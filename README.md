# WNBASchedule

A native Swift menu bar application that displays WNBA schedule information for the New York Liberty (NYL) team, including:

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
- Robust date parsing to handle various time formats

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

## Development

### Testing

Run the test suite with:

```bash
swift test
```

### CI/CD

The GitHub workflow automatically:
1. Builds the project
2. Runs tests on push and pull requests to the main branch
3. Creates a binary application bundle (.app)
4. Uploads the binary as an artifact that can be downloaded from the GitHub Actions page

You can download the latest binary from the "Actions" tab in the GitHub repository.

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.