# WNBA Schedule

Menu bar application that displays WNBA schedule information for all teams, including:

- Allows you specify one team or view all teams
- Previous 10 games with win/loss records and scores
- Live in-progress games with real-time score updates
- Upcoming 5 games
- Game times displayed in the user's local timezone (with ET as the default)

## Requirements

- macOS 12.0 or later

## Installation

### Option 1: Download from GitHub Releases

1. Go to the [releases page](https://github.com/jamtur01/WNBASchedule/releases)
2. Download the latest `WNBASchedule.zip` file
3. Unzip the downloaded file
4. Move `WNBASchedule.app` to your Applications folder
5. Right-click the app and select "Open" (required for first launch due to code signing)

### Option 2: Build from Source

Requirements for building:
- Swift 5.5 or later
- Xcode Command Line Tools

Steps:
1. Clone this repository:
```bash
git clone https://github.com/jamtur01/WNBASchedule.git
cd WNBASchedule
```

2. Build the application using the provided build script:
```bash
./build.sh
```

3. Open the application:
```bash
open WNBASchedule.app
```

4. (Optional) Move the app to your Applications folder

## Team Abbreviations

- NYL - New York Liberty
- LVA - Las Vegas Aces
- CON - Connecticut Sun
- MIN - Minnesota Lynx
- SEA - Seattle Storm
- IND - Indiana Fever
- WAS - Washington Mystics
- DAL - Dallas Wings
- CHI - Chicago Sky
- ATL - Atlanta Dream
- PHX - Phoenix Mercury
- LAS - Los Angeles Sparks
- GSV - Golden State Valkyries

## Development &amp; Data Sources

This application uses multiple NBA APIs to provide comprehensive WNBA information:

### Schedule Data
```
https://content-api-prod.nba.com/public/1/leagues/wnba/schedule?addEvents=true&seasonYear={currentYear}
```

### Live Score Data
```
https://cdn.wnba.com/static/json/liveData/boxscore/boxscore_{gameId}.json
```

### Caching Strategy

- **Schedule Data**: Cached for 1 hour to reduce API load
- **Live Score Data**: Cached for 5 minutes to balance freshness with performance
- **Retry Logic**: Exponential backoff for failed API requests

### Architecture Overview

- **AppDelegate**: Main application lifecycle and coordination
- **Managers**: Business logic and state management
- **Views**: SwiftUI interface components
- **Models**: Data structures and game logic
- **Networking**: API clients and caching
- **Utilities**: Helper functions and extensions

### Versioning

The app follows [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH).

Version information is stored in:
- `Sources/WNBASchedule/Version.swift`
- `Info/Info.plist`

To update the version:

```bash
./bump-version.sh X.Y.Z
```

This script updates version numbers in all necessary files. After running:

1. Review the changes: `git diff`
2. Commit the changes: `git commit -am "Bump version to X.Y.Z"`
3. Create a tag: `git tag vX.Y.Z`
4. Push changes and tag: `git push && git push --tags`

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or bugfix
3. Make your changes
4. Run tests to ensure everything works: `swift test`
5. Run SwiftLint to check code quality: `swiftlint`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
