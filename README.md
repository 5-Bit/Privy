## Privy
An information sharing application. This repository houses the iOS client for Privy.

#### Build Instructions (OS X only)
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

### Features
----------------------------------------------------------------------------

##### TODO

- Application Wide
  - Finish force touch launch options
  - Peek and pop transitions
  - App icon
  - Launch screen
  - Launch to history via APNS
- My Info Page
  - Split all data into business and personal sections
  - Ability to select what information to share
  - Save profile picture
  - Birthday/address/etc
  - Upload profile picture to server
- History Page
  - List
    - Add ability to delete contact
    - Linking from profile to various social networks  
    - Retrieve user's profile pictures from server
  - Profiles
    - Auto-follow
    - Finish profile page
    - Saving contact to native contacts app
    - Theming profile info based on social network colors
- Swap Page
  - Toggle torch
  - Better representation of contact being saved
    - Animate scanned QR code to history
- Settings Page
  - Log out button
  - Revoke subscriptions for individual users
  - Business card customization
    - Select font
    - Select color scheme (needs to be predefined for QR code contrast)


### API
--------------------------------------------------------------------------------

Host is https://privyapp.com

##### Requests

| Name                 | Path         | Method | Body                 | Parameters         | URL Encoded |
| -------------------- | ------------ | ------ | -------------------- | ------------------ | ----------- |
| Login                | /users/login | POST   | email, password      | N/A                | Yes         |
| Register             | /users/new   | POST   | email, password      | N/A                | Yes         |
| Save                 | /users/info  | POST   | JSON w/ social types | N/A                | No          |
| Check Authentication | /users/auth  | GET    | N/A                  | sessionid (string) | Yes         |
| LookupUUIDS          | /users/info  | GET    | N/A                  | uuids (UUID[])     | Yes         |


##### Responses

| Name                 | Body                                                           | Status Codes  | Body Type |
| -------------------- | -------------------------------------------------------------- | ------------- | --------- |
| Login                | sessionid, basic, social, business, developer, media, blogging | 200, 401, 50X | JSON      |
| Register             | sessionid, basic, social, business, developer, media, blogging | 200, 40X, 50X | JSON      |
| Save                 | N/A                                                            | 200, 40X, 50X | N/A       |
| Check Authentication | N/A                                                            | 200, 401, 50X | N/A       |
| LookupUUIDS          | JSON object, social type keys and UUID values                  | 200, 401, 50X | JSON      |
