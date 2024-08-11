# WNBA Schedule Spoon for Hammerspoon

This Spoon provides a convenient way to view upcoming WNBA games directly from your Mac's menu bar using Hammerspoon.

## Features

- Displays upcoming WNBA games for the next two weeks
- Shows game information including date, time, teams, and location
- Sorts games in chronological order
- Updates time to Eastern Time (ET)
- Accessible via a menu bar item

## Requirements

- [Hammerspoon](https://www.hammerspoon.org/) (latest version recommended)
- macOS (tested on the latest version, but should work on recent versions)
- Internet connection (to fetch the schedule data)

## Installation

1. Ensure you have Hammerspoon installed on your Mac.
2. Download the `WNBASchedule.spoon` directory.
3. Place the entire `WNBASchedule.spoon` directory in your Hammerspoon Spoons directory (usually `~/.hammerspoon/Spoons/`).

## Usage

1. Open your Hammerspoon configuration file (usually `~/.hammerspoon/init.lua`).
2. Add the following lines to load and start the Spoon:

   ```lua
   hs.loadSpoon("WNBASchedule")
   spoon.WNBASchedule:start()
   ```

3. Reload your Hammerspoon configuration.
4. You should now see a "WNBA" item in your menu bar.
5. Click on the "WNBA" menu bar item to view the upcoming games.

## Customization

You can modify the `init.lua` file within the `WNBASchedule.spoon` directory to customize the Spoon's behavior. For example, you could change the menu bar text or adjust how many days of games are fetched.

## Troubleshooting

- If you don't see the menu bar item, ensure that the Spoon is correctly loaded in your Hammerspoon configuration.
- If no games are displayed, check your internet connection and try reloading the Hammerspoon configuration.
- For any other issues, check the Hammerspoon Console for error messages.

## Contributing

Contributions to improve the WNBA Schedule Spoon are welcome! Please feel free to submit issues or pull requests on the GitHub repository.

## License

This Spoon is released under the MIT License. See the LICENSE file for details.

## Acknowledgments

- Thanks to the Hammerspoon team for creating and maintaining such a powerful tool.
- Data is sourced from ESPN's API.

## Version History

- 1.5: Added sorting functionality for games
- 1.4: Updated to show ET timezone and game location
- 1.3: Improved date formatting
- 1.2: Fixed time parsing issues
- 1.1: Added error handling and improved code structure
- 1.0: Initial release
