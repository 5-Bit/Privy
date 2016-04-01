## Privy
An information sharing application. This repository houses the iOS client for Privy.

##### Build Instructions (OS X only)
0. Download Xcode 7.3 (7D175) or later.
1. Clone this repository to your computer
2. If you don't have [Homebrew](http://brew.sh) installed, run this command to install it `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
3. Install [Carthage](https://github.com/Carthage/Carthage) with `brew install carthage`
4. Change to the directory where you cloned Privy to (the directory containing Privy.xcodeproj)
5. Run `carthage update`
6. Open the Xcode project file (Privy.xcodeproj)
7. If you're having trouble building this project after updating to Xcode 7.3 (with linker errors), simply run `carthage update` again.
  - You may need to run `sudo xcode-select --switch PATH_TO_XCODE_BETA` for Carthage to use the correct compiler version for its build.
8. Build, run, enjoy.


##### TODO

- Finish force touch launch options
- Peek and pop transitions
- Linking from profile to various social networks
- Ability to select what information to share
- Finish profile page
- Add ability to delete contact
- Saving contact to native contacts app.

##### Considerations

- Split all data into business and personal sections
- Auto-follow
- Animate scanned QR code to history
- Themes for business cards
- Theming profile info based on social network colors
