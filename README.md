# BLOCKv

[![Version](https://img.shields.io/cocoapods/v/BlockV.svg?style=flat)](http://cocoapods.org/pods/BlockV)
[![License](https://img.shields.io/cocoapods/l/BlockV.svg?style=flat)](http://cocoapods.org/pods/BlockV)
[![Platform](https://img.shields.io/cocoapods/p/BlockV.svg?style=flat)](http://cocoapods.org/pods/BlockV)

## Requirements

- iOS 10.0+
- Xcode 9.2+
- Swift 4+

## Installation

BLOCKv is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BLOCKv'
```

## Configuration

Within the `AppDelegate` be sure to set your App ID and the desired server environment.

```Swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Set appID
        BLOCKv.configure(appID: "your-app-id")
        // Set platform environment
        BLOCKv.setEnvironment(.development)
        // Check logged in state
        if BLOCKv.isLoggedIn {
            // show interesting ui
        } else {
            // show authentication ui
        }
        return true
    }
}
```

## Example

The example app lets you try out the BLOCKv SDK. It's a great place to start if you're getting up to speed on the platform. It demonstrates the following features:

- Authentication (registration & login)
- Profile management
- Fetching the user's inventory of vAtoms
- Fetching individual vAtoms by thier ID(s)
- Dispalying vAtoms in a collection view
- Searching for vAtoms on the BLOCKv Platform

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Security Disclosure

If you believe you have identified a security vulnerability with BLOCKv, you should report it as soon as possible via email to support@blockv.io. Please do not post it to a public issue tracker.

## Author

[BLOCKv](developer.blockv.io)

## License

BlockV is available under the Blockv AG license. See the [LICENSE](https://github.com/BLOCKvIO/ios-sdk/blob/master/LICENSE) file for more info.
