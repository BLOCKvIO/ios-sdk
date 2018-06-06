# BLOCKv SDK for iOS

[![Version](https://img.shields.io/cocoapods/v/BLOCKv.svg?style=flat)](http://cocoapods.org/pods/BLOCKv)
[![License](https://img.shields.io/cocoapods/l/BLOCKv.svg?style=flat)](http://cocoapods.org/pods/BLOCKv)
[![Platform](https://img.shields.io/cocoapods/p/BLOCKv.svg?style=flat)](http://cocoapods.org/pods/BLOCKv)

This is the official BLOCKv SDK. It allows you to easily integrate your own apps into the BLOCKv Platform.

## Requirements

- iOS 10.0+
- Xcode 9.4+
- Swift 4.1+

## Installation

BLOCKv is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BLOCKv'
```

## Configuration

Within the `AppDelegate` be sure to set the App ID.

```Swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        // Set app id
        BLOCKv.configure(appID: "your-app-id")
        
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

## Example App

The example app lets you try out the BLOCKv SDK. It's a great place to start if you're getting up to speed on the platform. It demonstrates the following features:

- [x] Authentication (registration & login)
- [x] Profile management
- [x] Fetching the user's inventory of vAtoms
- [x] Fetching individual vAtoms
- [x] Fetching a vAtom's Activated Image
- [x] Dispalying vAtoms in a UICollectionView
- [x] Searching for vAtoms on the BLOCKv Platform

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Security Disclosure

If you believe you have identified a security vulnerability with BLOCKv, you should report it as soon as possible via email to support@blockv.io. Please do not post it to a public issue tracker.

## Author

[BLOCKv](developer.blockv.io)

## License

BLOCKv is available under the BLOCKv AG license. See the [LICENSE](https://github.com/BLOCKvIO/ios-sdk/blob/master/LICENSE) file for more info.
