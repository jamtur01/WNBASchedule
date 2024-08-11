--- WNBA Schedule Spoon
--- Display upcoming WNBA games for the next two weeks, sorted by date and time

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WNBASchedule"
obj.version = "1.5"
obj.author = "James Turnbull <james@lovedthanlost.net>"
obj.homepage = "https://www.hammerspoon.org"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
    self.menubar = nil
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

function obj:displaySchedule()
    local scheduleData = fetchSchedule()
    if not scheduleData then 
        hs.alert.show("Failed to fetch WNBA schedule", 3)
        return 
    end
    
    local games = parseGames(scheduleData)
    
    if #games == 0 then
        hs.alert.show("No upcoming WNBA games found", 3)
        return
    end
    
    sortGames(games)
    
    local alertText = "Upcoming WNBA Games:\n\n"
    for _, game in ipairs(games) do
        local gameDate = formatGameDate(game.date)
        local gameTime = formatGameTime(game.time)
        alertText = alertText .. string.format("%s: %s vs %s at %s, %s\n", 
            gameDate, game.away, game.home, game.home, gameTime)
    end
    
    hs.alert.show(alertText, 10)
end

function obj:start()
    if self.menubar then
        self.menubar:delete()
    end
    self.menubar = hs.menubar.new()
    self.menubar:setTitle("WNBA")
    self.menubar:setClickCallback(function() self:displaySchedule() end)
end

function obj:stop()
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
end

return obj