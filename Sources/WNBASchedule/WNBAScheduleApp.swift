import SwiftUI
import os.log
import Combine

@main
struct WNBAScheduleApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appCoordinator)
        } label: {
            Text("🏀")
                .font(.system(size: 18, weight: .semibold))
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Coordinator
@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Properties
    @Published var games: FilteredGames?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let scheduleManager: ScheduleManagerProtocol
    private let userPreferences: UserPreferences
    private let apiCache: APICacheProtocol
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "AppCoordinator")
    
    // Managers
    private let liveScoreManager: LiveScoreManager
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimerCancellable: AnyCancellable?
    private var liveScoreTimerCancellable: AnyCancellable?
    
    // MARK: - Initialization
    init(
        scheduleManager: ScheduleManagerProtocol = DependencyContainer.shared.scheduleManager,
        userPreferences: UserPreferences = DependencyContainer.shared.userPreferences,
        apiCache: APICacheProtocol = DependencyContainer.shared.apiCache
    ) {
        self.scheduleManager = scheduleManager
        self.userPreferences = userPreferences
        self.apiCache = apiCache
        self.liveScoreManager = LiveScoreManager()
        
        setupTimers()
        refreshGames()
    }
    
    // MARK: - Public Methods
    func refreshGames() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if TeamSelection.isAllTeams(userPreferences.favoriteTeam) {
                    try await handleAllTeamsMode()
                } else {
                    try await handleIndividualTeamMode()
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.setupLiveScoreTimerIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Error refreshing games: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func changeTeam(to teamAbbreviation: String) {
        // If switching to "ALL", save the current team as previously selected
        if TeamSelection.isAllTeams(teamAbbreviation) && !TeamSelection.isAllTeams(userPreferences.favoriteTeam) {
            userPreferences.previouslySelectedTeam = userPreferences.favoriteTeam
        }
        
        userPreferences.favoriteTeam = teamAbbreviation
        userPreferences.savePreferences()
        apiCache.clearCache()
        refreshGames()
    }
    
    // MARK: - Private Methods
    private func handleAllTeamsMode() async throws {
        // Use ScheduleManager to fetch all teams games
        let (inProgressGames, upcomingGames) = try await scheduleManager.fetchAllTeamsGames(season: nil)
        
        // Fetch live scores for in-progress games if any exist
        var updatedInProgressGames = inProgressGames
        if !updatedInProgressGames.isEmpty {
            updatedInProgressGames = await liveScoreManager.fetchLiveScores(for: updatedInProgressGames)
        }
        
        await MainActor.run {
            // Convert to FilteredGames format for compatibility
            self.games = FilteredGames(
                pastGames: [],
                inProgressGames: updatedInProgressGames.map { MarkedGame(game: $0, isHomeGame: false) },
                upcomingGames: upcomingGames.map { MarkedGame(game: $0, isHomeGame: false) }
            )
        }
    }
    
    private func handleIndividualTeamMode() async throws {
        let fetchedGames = try await scheduleManager.fetchGames(forTeam: userPreferences.favoriteTeam)
        
        await MainActor.run {
            self.games = fetchedGames
        }
    }
    
    private func setupTimers() {
        // Setup refresh timer (every 15 minutes)
        refreshTimerCancellable = Timer.publish(every: 900, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshGames()
            }
    }
    
    private func setupLiveScoreTimerIfNeeded() {
        let hasInProgressGames = games?.inProgressGames.isEmpty == false
        
        if hasInProgressGames {
            liveScoreTimerCancellable?.cancel()
            liveScoreTimerCancellable = Timer.publish(every: 30, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateLiveScores()
                }
        } else {
            liveScoreTimerCancellable?.cancel()
        }
    }
    
    private func updateLiveScores() {
        guard let currentGames = games else { return }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            await self.liveScoreManager.updateLiveScoresForTeam(currentGames: currentGames) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    if data.gameFinished {
                        self.refreshGames()
                    } else {
                        self.games = data.updatedGames
                    }
                    
                    if data.updatedGames.inProgressGames.isEmpty {
                        self.liveScoreTimerCancellable?.cancel()
                    }
                    
                case .failure(let error):
                    self.logger.error("Error updating live scores: \(error.localizedDescription)")
                }
            }
        }
    }
    
    deinit {
        refreshTimerCancellable?.cancel()
        liveScoreTimerCancellable?.cancel()
        cancellables.removeAll()
    }
}

// MARK: - Menu Bar Content View
struct MenuBarContentView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            if appCoordinator.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if let errorMessage = appCoordinator.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Retry") {
                        appCoordinator.refreshGames()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if let games = appCoordinator.games {
                if TeamSelection.isAllTeams(DependencyContainer.shared.userPreferences.favoriteTeam) {
                    AllTeamsMenuView(
                        upcomingGames: games.upcomingGames.map { $0.game },
                        inProgressGames: games.inProgressGames.map { $0.game },
                        refreshAction: {
                            appCoordinator.refreshGames()
                        },
                        changeTeamAction: { newTeam in
                            appCoordinator.changeTeam(to: newTeam)
                        },
                        previouslySelectedTeam: DependencyContainer.shared.userPreferences.previouslySelectedTeam
                    )
                } else {
                    MenuView(
                        games: games,
                        teamAbbreviation: DependencyContainer.shared.userPreferences.favoriteTeam,
                        refreshAction: {
                            appCoordinator.refreshGames()
                        },
                        changeTeamAction: { newTeam in
                            appCoordinator.changeTeam(to: newTeam)
                        }
                    )
                }
            } else {
                VStack(spacing: 8) {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .frame(width: 320, height: 630)
    }
}
