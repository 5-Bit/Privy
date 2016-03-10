## Privy
An information sharing application. This repository houses the iOS client for Privy.

##### Build Instructions (OS X only)
0. Download Xcode 7.3 beta 5 (7D152p) or later.
1. Clone this repository to your computer
2. If you don't have [Homebrew](http://brew.sh) installed, run this command to install it `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
3. Install [Carthage](https://github.com/Carthage/Carthage) with `brew install carthage`
4. Change to the directory where you cloned Privy to (the directory containing Privy.xcodeproj)
5. Run `carthage update`
6. Open the Xcode project file (Privy.xcodeproj)
7. If you're having trouble building this project after updating to Xcode 7.3 (with linker errors), simply run `carthage update` again.
8. Build, run, enjoy.
