local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WNBASchedule"
obj.version = "2.0"
obj.author = "James Turnbull <james@lovedthanlost.net>"
obj.homepage = "https://www.hammerspoon.org"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
    self.menubar = nil
    self.numGames = 1  -- Default to showing 1 game
    self.favoriteTeams = {}  -- List of teams to follow
    return self
end

local function fetchSchedule()
    local twoWeeksFromNow = os.time() + (14 * 24 * 60 * 60)
    local url = string.format("https://cdn.espn.com/core/wnba/schedule?dates=%s&userab=18&xhr=1&render=true&device=desktop",
                              os.date("%Y%m%d", twoWeeksFromNow))
    
    local status, body = hs.http.get(url)
    if status ~= 200 then
        print("Error fetching schedule:", status)
        return nil
    end
    
    return hs.json.decode(body)
end

local function parseGames(data)
    local games = {}
    if data and data.content and data.content.schedule then
        for date, dateData in pairs(data.content.schedule) do
            if dateData.games then
                for _, game in ipairs(dateData.games) do
                    table.insert(games, {
                        date = date,
                        time = game.date,
                        url  = game.links[1].href,
                        home = game.competitions[1].competitors[1].team.shortDisplayName,
                        away = game.competitions[1].competitors[2].team.shortDisplayName
                    })
                end
            end
        end
    end
    return games
end

local function formatGameTime(timeString)
    local year, month, day, hour, min = timeString:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if year and month and day and hour and min then
        local timestamp = os.time({year=year, month=month, day=day, hour=hour, min=min})
        -- Convert to ET (NYC) time
        local etTime = timestamp - 4 * 3600  -- Adjust for ET (UTC-4)
        return os.date("%I:%M %p ET", etTime)
    else
        return "Time TBA"
    end
end

local function getDaySuffix(day)
    if day >= 11 and day <= 13 then
        return "th"
    end
    local lastDigit = day % 10
    local suffixes = {[1] = "st", [2] = "nd", [3] = "rd"}
    return suffixes[lastDigit] or "th"
end

local function formatGameDate(dateString)
    local year, month, day = dateString:match("(%d+)(%d%d)(%d%d)")
    if year and month and day then
        local timestamp = os.time({year=year, month=month, day=day})
        local dayOfWeek = os.date("%a", timestamp)
        local monthName = os.date("%b", timestamp)
        local dayNum = tonumber(day)
        local suffix = getDaySuffix(dayNum)
        return string.format("%s %s %d%s", dayOfWeek, monthName, dayNum, suffix)
    else
        return "Date Unknown"
    end
end

local function sortGames(games)
    table.sort(games, function(a, b)
        if a.date == b.date then
            return a.time < b.time
        end
        return a.date < b.date
    end)
end

local function isFavoriteTeam(game, favoriteTeams)
    for _, team in ipairs(favoriteTeams) do
        if game.home == team or game.away == team then
            return true
        end
    end
    return false
end

function obj:displaySchedule()
    local scheduleData = fetchSchedule()
    if not scheduleData then 
        hs.notify.new({title="WNBA Schedule Error", informativeText="Failed to fetch WNBA schedule"}):send()
        return 
    end
    
    local games = parseGames(scheduleData)
    
    if #games == 0 then
        hs.notify.new({title="WNBA Schedule", informativeText="No upcoming WNBA games found"}):send()
        return
    end
    
    sortGames(games)
    
    local displayedGames = 0
    for i = 1, #games do
        if isFavoriteTeam(games[i], self.favoriteTeams) then
            displayedGames = displayedGames + 1
            local game = games[i]
            local gameDate = formatGameDate(game.date)
            local gameTime = formatGameTime(game.time)
            local notificationText = string.format("%s vs %s at %s\n%s, %s", 
                game.away, game.home, game.home, gameDate, gameTime)
            
            hs.timer.doAfter(displayedGames * 2, function()  -- Delay each notification by 2 seconds
                local notification = hs.notify.new(function()
                    hs.urlevent.openURL(game.url)
                end)
                :title("Upcoming WNBA Game")
                :subTitle(gameDate)
                :informativeText(notificationText)
                :actionButtonTitle("Open")
                :hasActionButton(true)
                :withdrawAfter(0)  -- Don't automatically withdraw
                
                notification:send()
            end)
            
            if displayedGames >= self.numGames then
                break
            end
        end
    end
    
    if displayedGames == 0 then
        hs.notify.new({title="WNBA Schedule", informativeText="No upcoming games featuring your favorite teams"}):send()
    end
end

function obj:setFavoriteTeams()
    hs.chooser.new(function(choice)
        if choice then
            local teams = {}
            for team in string.gmatch(choice.text, '([^,]+)') do
                table.insert(teams, team:match("^%s*(.-)%s*$"))  -- Trim whitespace
            end
            self.favoriteTeams = teams
            hs.notify.new({title="WNBA Schedule", informativeText="Favorite teams set to: " .. table.concat(teams, ", ")}):send()
        end
    end)
    :choices({
        {text = "Liberty"}, {text = "Aces"}, {text = "Sky"}, {text = "Sun"}, {text = "Mystics"},
        {text = "Dream"}, {text = "Fever"}, {text = "Wings"}, {text = "Sparks"}, {text = "Mercury"},
        {text = "Storm"}, {text = "Lynx"}
    })
    :placeholderText("Enter teams (comma separated)")
    :show()
end

function obj:start()
    if self.menubar then
        self.menubar:delete()
    end
    self.menubar = hs.menubar.new()
    self.menubar:setTitle("WNBA")
    self.menubar:setMenu({
        {title = "Show Schedule", fn = function() self:displaySchedule() end},
        {title = "Set Favorite Teams", fn = function() self:setFavoriteTeams() end},
        {title = "-"},
        {title = "Set Number of Games", fn = function() self:setNumGames() end}
    })
end

function obj:setNumGames()
    hs.chooser.new(function(choice)
        if choice then
            self.numGames = tonumber(choice.text)
            hs.notify.new({title="WNBA Schedule", informativeText="Number of games to show set to " .. self.numGames}):send()
        end
    end)
    :choices({
        {text = "1"}, {text = "2"}, {text = "3"}, {text = "4"}, {text = "5"}
    })
    :placeholderText("Select number of games to show")
    :show()
end

function obj:stop()
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
end

return obj
