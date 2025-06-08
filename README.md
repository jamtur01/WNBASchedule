# WNBASchedule

Menu bar application that displays WNBA schedule information for the New York Liberty (NYL) team, including:

- Previous 10 games with win/loss records and scores
- Upcoming 5 games
- Game times displayed in the user's local timezone (with ET as the default)

## Features

- Lives in your menu bar for easy access
- Automatically refreshes data every hour
- Fetches real-time WNBA schedule data from the NBA API
- Filters games for a specific team (default: New York Liberty)
- Shows past game results with scores and win/loss status (color-coded for winners and losers)
- Shows upcoming games with dates and times in the user's local timezone

## Requirements

- macOS 12.0 or later
- Swift 5.5 or later

## Installation

1. Clone this repository
2. Build the application using the provided build script:

```bash
./build.sh
```

3. Open the application:

```bash
open WNBASchedule.app
```

4. (Optional) Drag the app to your Applications folder

## Development

### Project Structure

```
WNBASchedule/
├── Sources/WNBASchedule/      # Application source code
├── Tests/WNBAScheduleTests/   # Test suite
├── Info/Info.plist            # App configuration
├── .github/workflows/         # CI/CD workflows
├── build.sh                   # Build script
└── bump-version.sh            # Version update script
```

### Testing

Run tests with Swift's test command:

```bash
swift test
```

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

## Data Source

This application uses the NBA API to fetch WNBA schedule data:
```
https://content-api-prod.nba.com/public/1/leagues/wnba/schedule?addEvents=true&seasonYear=2025
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or bugfix
3. Make your changes
4. Run tests to ensure everything works
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
