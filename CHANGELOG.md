# Change Log

All notable changes to this project will be documented in this file.

#### 4.x Release

- `4.0.x` Releases - [4.0.0](#400)

#### 3.x Release

- `3.1.x` Releases - [3.1.0](#310)
- `3.0.x` Releases - [3.0.0](#300)

#### 2.x Releases

- `2.3.x` Releases -  [2.3.0](#230)
- `2.2.x` Releases -  [2.2.0](#220)
- `2.1.x` Releases -  [2.1.0](#210)
- `2.0.x` Releases -  [2.0.0](#200)

#### 1.x Releases

- `1.1.x` Releases - [1.1.0](#110)
- `1.0.x` Releases - [1.0.0](#100)

#### 0.x Releases

- `0.9.x` Releases - [0.9.9](#099) | [0.9.10](#0910)

---

## [4.0.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/4.0.0)

### Added

- Data Pool.
  - In memory object store that provides 'regions' which represent logical groups of remote vatoms. For example, the user's inventory is managed by the 'InventoryRegion'. Some regions offer real-time synchronization with the BLOCKv platform.
- Bridge Protocol 2.1.0
  - Pull Request [#354](https://github.com/BLOCKvIO/ios-sdk/pull/354)
  - Pull Request [#338](https://github.com/BLOCKvIO/ios-sdk/pull/338)
  - Pull Request [#244](https://github.com/BLOCKvIO/ios-sdk/pull/244)
- Swift Package Manager support
  - Pull Request [#352](https://github.com/BLOCKvIO/ios-sdk/pull/352)
- Action notifications
  - Pull Request [#333](https://github.com/BLOCKvIO/ios-sdk/pull/333)
- Split and Combine actions
  - Pull Request [#323](https://github.com/BLOCKvIO/ios-sdk/pull/323)
- (Face) Trigger Rules
  - Pull Request [#311](https://github.com/BLOCKvIO/ios-sdk/pull/311)
- Redemption request on Vatom id
  - Pull Request [#297](https://github.com/BLOCKvIO/ios-sdk/pull/297)
- Dispense request
  - Pull Request [#286](https://github.com/BLOCKvIO/ios-sdk/pull/286)
- Convenience method to clear auth credentials
  - Pull Request [#280](https://github.com/BLOCKvIO/ios-sdk/pull/280)
- OAuth login
  - Pull Request [#275](https://github.com/BLOCKvIO/ios-sdk/pull/275)
- os_log
  - Pull Request [#272](https://github.com/BLOCKvIO/ios-sdk/pull/272)
  - Pull Request [#271](https://github.com/BLOCKvIO/ios-sdk/pull/271)
- Method `updatePushNotification(fcmToken:platformID:enabled:complete)`
  - Pull Request [#224](https://github.com/BLOCKvIO/ios-sdk/pull/224)
- App version support
  - Pull Request [#223](https://github.com/BLOCKvIO/ios-sdk/pull/223)

### Updated

- Update BVError
  - Pull Request [#341](https://github.com/BLOCKvIO/ios-sdk/pull/341)
  - Pull Request [#309](https://github.com/BLOCKvIO/ios-sdk/pull/309)
  - Pull Request [#304](https://github.com/BLOCKvIO/ios-sdk/pull/304)
  - Pull Request [#302](https://github.com/BLOCKvIO/ios-sdk/pull/302)
  - Pull Request [#279](https://github.com/BLOCKvIO/ios-sdk/pull/279)
  - Pull Request [#249](https://github.com/BLOCKvIO/ios-sdk/pull/249)
  - Pull Request [#248](https://github.com/BLOCKvIO/ios-sdk/pull/248)
- Generate Guest ID.
  - Pull Request [#347](https://github.com/BLOCKvIO/ios-sdk/pull/347)
- Update vatom view with only a procedure
  - Pull Request [#340](https://github.com/BLOCKvIO/ios-sdk/pull/340)
- User consent property in `UserModel`.
  - Pull Request [#339](https://github.com/BLOCKvIO/ios-sdk/pull/339)
- Error Spec 1.0.0 conformance
  - Pull Request [#321](https://github.com/BLOCKvIO/ios-sdk/pull/321)
- KeyPath with nested strings
  - Pull Request [#291](https://github.com/BLOCKvIO/ios-sdk/pull/291)
- KayPath lookup
  - Pull Request [#287](https://github.com/BLOCKvIO/ios-sdk/pull/287)
- Image downloader
  - Pull Request [#277](https://github.com/BLOCKvIO/ios-sdk/pull/277)
- Add `sync` to `WSStateUpdateEvent`
  - Pull Request [#268](https://github.com/BLOCKvIO/ios-sdk/pull/268)

### Fixed

- Web socket life cycle.
  - Pull Request [#359](https://github.com/BLOCKvIO/ios-sdk/pull/359)
  - Pull Request [#283](https://github.com/BLOCKvIO/ios-sdk/pull/283)
  - Pull Request [#282](https://github.com/BLOCKvIO/ios-sdk/pull/282)
  - Pull Request [#243](https://github.com/BLOCKvIO/ios-sdk/pull/243)
- Add member-wise initializer to `FaceModel`
  - Pull Request [#358](https://github.com/BLOCKvIO/ios-sdk/pull/358)
- JSON parsing for arrays where the value is `null`.
  - Pull Request [#357](https://github.com/BLOCKvIO/ios-sdk/pull/357)
- Duplicate parent id updates.
  - Pull Request [#350](https://github.com/BLOCKvIO/ios-sdk/pull/350)
- Parent ID side effects.
  - Pull Request [#349](https://github.com/BLOCKvIO/ios-sdk/pull/349)
- (Face) Image progress layout
  - Pull Request [#346](https://github.com/BLOCKvIO/ios-sdk/pull/346)
- (Face) Vatom View Life Cycle.
  - Pull Request [#345](https://github.com/BLOCKvIO/ios-sdk/pull/345)
- Expose properties of `ActionResponse`
  - Pull Request [#337](https://github.com/BLOCKvIO/ios-sdk/pull/337)
  - Pull Request [#336](https://github.com/BLOCKvIO/ios-sdk/pull/336)
- Bearer token endpoint scope
  - Pull Request [#331](https://github.com/BLOCKvIO/ios-sdk/pull/331)
- Add class conformance to `FacePresenter`
  - Pull Request [#317](https://github.com/BLOCKvIO/ios-sdk/pull/317)
- Expose `SystemProperties` on `UserModel`
  - Pull Request [#305](https://github.com/BLOCKvIO/ios-sdk/pull/305)
- Requests should retry only once
  - Pull Request [#303](https://github.com/BLOCKvIO/ios-sdk/pull/303)
- (Face) Image progress label responsiveness
  - Pull Request [#295](https://github.com/BLOCKvIO/ios-sdk/pull/295)
- Image policy face config
  - Pull Request [#293](https://github.com/BLOCKvIO/ios-sdk/pull/293)
- Fetch user as part of OAuth
  - Pull Request [#292](https://github.com/BLOCKvIO/ios-sdk/pull/292)
- (Face) Use throwing initializer
  - Pull Request [#285](https://github.com/BLOCKvIO/ios-sdk/pull/285)
- Reference cycle in save closure
  - Pull Request [#218](https://github.com/BLOCKvIO/ios-sdk/pull/218)
- BoundedView
  - Pull Request [#273](https://github.com/BLOCKvIO/ios-sdk/pull/273)
- `when_added` on `VatomModel`
  - Pull Request [#264](https://github.com/BLOCKvIO/ios-sdk/pull/264)
- Member-wise initializer for `MessageModel`
  - Pull Request [#259](https://github.com/BLOCKvIO/ios-sdk/pull/259)
- Migrate to GenericJSON 2.0.0 (fix double point precision)
  - Pull Request [#250](https://github.com/BLOCKvIO/ios-sdk/pull/250)
- (Face) Image policy face root property lookup (`cloning_score` and `num_direct_clones`)
  - Pull Request [#251](https://github.com/BLOCKvIO/ios-sdk/pull/251)
- Vatom View Life Cycle
  - Pull Request [#230](https://github.com/BLOCKvIO/ios-sdk/pull/230)
- (Face) Fix web view scrolling
  - Pull Request [#229](https://github.com/BLOCKvIO/ios-sdk/pull/229)
- Add `nonPushNotification` to `TokenRegisterParams`
  - Pull Request [#228](https://github.com/BLOCKvIO/ios-sdk/pull/228)
- Web face caching
  - Pull Request [#225](https://github.com/BLOCKvIO/ios-sdk/pull/225)
- VatomView in reuse pool
  - Pull Request [#222](https://github.com/BLOCKvIO/ios-sdk/pull/222)

## [3.1.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/3.1.0)

### Updated

- Add `Codable` conformance to `MessageListModel`.  
- Convert `cursor` and `messages` properties on `MessageListModel` from `let` to `var` .
- Convert `cursor` and `threads` properties on  `MessageListModel`  from `let` to `var`.
  - Pull Request [#175](https://github.com/BLOCKvIO/ios-sdk/pull/175)
- Add `page` and `limit` properties to `DiscoverQueryBuilder` to allow for paging.
  - Pull Request [#173](https://github.com/BLOCKvIO/ios-sdk/pull/173/files)

### Fixed

- Default `isPublished` is `false`. This allows vAtoms with a missing `unpublished` JSON key to be decoded.
  - Pull Request [#176](https://github.com/BLOCKvIO/ios-sdk/pull/176)

## [3.0.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/3.0.0)

### Added

- Web Face View
  - Pull Request [#161](https://github.com/BLOCKvIO/ios-sdk/pull/161)
  - Pull Request [#159](https://github.com/BLOCKvIO/ios-sdk/pull/159)
  - Pull Request [#155](https://github.com/BLOCKvIO/ios-sdk/pull/155)
  - Pull Request [#153](https://github.com/BLOCKvIO/ios-sdk/pull/153)
  - Pull Request [#152](https://github.com/BLOCKvIO/ios-sdk/pull/152)
  - Pull Request [#148](https://github.com/BLOCKvIO/ios-sdk/pull/148)
  - Pull Request [#147](https://github.com/BLOCKvIO/ios-sdk/pull/147)
  - Pull Request [#146](https://github.com/BLOCKvIO/ios-sdk/pull/146)
- BLOCKv encoder and decoder convenience structs
  - Pull Request [#151](https://github.com/BLOCKvIO/ios-sdk/pull/151)
- `NSNull` initialisation to GenericJSON
  - Pull Request [#151](https://github.com/BLOCKvIO/ios-sdk/pull/151)
- `Codable` conformance to `VatomModel` and`ActionModel`
  - Pull Request [#150](https://github.com/BLOCKvIO/ios-sdk/pull/150)

### Updated

- Remove discover count (due to server inconsistency)
  - Pull Request [#158](https://github.com/BLOCKvIO/ios-sdk/pull/158)
- Correct `VatomModel` codable keys to match server
  - Pull Request [#157](https://github.com/BLOCKvIO/ios-sdk/pull/157)
- Use unencoded resource url as cache key
  - Pull Request [#145](https://github.com/BLOCKvIO/ios-sdk/pull/145)

---

## [2.3.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/2.3.0)

### Added

- Image Layered Face View
  - Pull Request [#143](https://github.com/BLOCKvIO/ios-sdk/pull/143)
  
- 3D Face View
  - Pull Request [#143](https://github.com/BLOCKvIO/ios-sdk/pull/143)

## [2.2.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/2.2.0)

### Added

- Image Policy Face View
  - Pull Request [#134](https://github.com/BLOCKvIO/ios-sdk/pull/134)
  
### Updated
  
  - Prevent `InventoryViewController` from refreshing the inventory after a state update event. This is bad pratice. Rather, an object should
be created which performs localized updates using the state events.
  - Pull Request [#133](https://github.com/BLOCKvIO/ios-sdk/pull/133)

## [2.1.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/2.1.0)

### Added

- Image Progress Face View
  - Pull Request [#119](https://github.com/BLOCKvIO/ios-sdk/pull/119)
- `LiveVatomView` demonstrating responding to Web socket state updates.
  - Pull Request [#116](https://github.com/BLOCKvIO/ios-sdk/pull/116)
- `updated(applying:)` method to `VatomModel`. This method allows the partial update data in a state update to be applied to a vatom.
  - Pull Request [#115](https://github.com/BLOCKvIO/ios-sdk/pull/115)
- EOS ans ETH properties to `VatomModel`.
  - Pull Request [#114](https://github.com/BLOCKvIO/ios-sdk/pull/114)

### Updated

- `TappedVatomViewController` now uses the new `LiveVatomView` instead of the base class `VatomView`. This allows the view
controller to respond to the changes over the Web socket.
  - Pull Request [#117](https://github.com/BLOCKvIO/ios-sdk/pull/117)

### Fixed

- Image Face View looking for wrong image
  - Pull Request [#110](https://github.com/BLOCKvIO/ios-sdk/pull/110)

## [2.0.1](https://github.com/BLOCKvIO/ios-sdk/releases/tag/2.0.1)

### Fixed

- Missing files in Example app
  - Pull Request [#108](https://github.com/BLOCKvIO/ios-sdk/pull/108)

## [2.0.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/2.0.0)

Released on 2018-09-28

### Added

- Face module for visually rendering vAtoms using faces.
  - Pull Request [#104](https://github.com/BLOCKvIO/ios-sdk/pull/104)

### Updated

- Renamed `privateProps` to `private`.
  - Pull Request [#84](https://github.com/BLOCKvIO/ios-sdk/pull/84), [#85](https://github.com/BLOCKvIO/ios-sdk/pull/85)
- Update discover queury to complete with an array of `VatomModel`. Update permitted discover query builder field types.
  - Pull Request [#78](https://github.com/BLOCKvIO/ios-sdk/pull/78)
- Converted `VatomPackModel` and replaced with an array of packed `VatomModel`.
  - Pull Request [#77](https://github.com/BLOCKvIO/ios-sdk/pull/77)
- Update sample app to use `VatomModel` in place of `VatomPackModel`.
  - Pull Request [#76](https://github.com/BLOCKvIO/ios-sdk/pull/76)
- Create an intermediary `UnpackedModel` to allow an unpacked response to be packed into an array of `VatomModel`.
  - Pull Request [#75](https://github.com/BLOCKvIO/ios-sdk/pull/75)
- Convert `displayURL` to a `String`.
  - Pull Request [#69](https://github.com/BLOCKvIO/ios-sdk/pull/69)
- Rename errors for consistency and add equatable conformance.
  - Pull Request [#68](https://github.com/BLOCKvIO/ios-sdk/pull/68)
- Add `faceModels` and `actionModels` to `VatomModel`.
  - Pull Request [#67](https://github.com/BLOCKvIO/ios-sdk/pull/67)
- Add config section to `FaceModel`.
  - Pull Request [#64](https://github.com/BLOCKvIO/ios-sdk/pull/64)
- Add `isNative` and `isWeb` convenience properties to `FaceModel`. Add face model decoding unit tests.
  - Pull Request [#63](https://github.com/BLOCKvIO/ios-sdk/pull/63)
- Add pack model tests *depreciated*.
  - Pull Request [#61](https://github.com/BLOCKvIO/ios-sdk/pull/61)
- Add convenience extensions to `PackModel` *depreciated*.
  - Pull Request [#60](https://github.com/BLOCKvIO/ios-sdk/pull/60)
- Rename `templateName` to `templateID` .
  - Pull Request [#59](https://github.com/BLOCKvIO/ios-sdk/pull/59)
- Add Swift Lint.
  - Pull Request [#58](https://github.com/BLOCKvIO/ios-sdk/pull/58)
- Improve environement configuration handling.
  - Pull Request [#57](https://github.com/BLOCKvIO/ios-sdk/pull/57)
- Filter out avatar vAtom from inventory.
  - Pull Request [#55](https://github.com/BLOCKvIO/ios-sdk/pull/55)
- Add public user `id` to `PublicUserModel`.
  - Pull Request [#54](https://github.com/BLOCKvIO/ios-sdk/pull/54)
- Add `isPasswordSet` flag to `UserModel`.
  - Pull Request [#53](https://github.com/BLOCKvIO/ios-sdk/pull/53)
- Update `namePublic` as `isNamePublic`, and `avatarPublic` as `isAvatarPublic`.
  - Pull Request [#52](https://github.com/BLOCKvIO/ios-sdk/pull/52)
- Update `templateVariationName` as `templateVariationID` within the `VatomChildPolicy` object.
  - Pull Request [#51](https://github.com/BLOCKvIO/ios-sdk/pull/51)
- Fix access control on `VatomModel`.
  - Pull Request [#50](https://github.com/BLOCKvIO/ios-sdk/pull/50)
- Fix an issue where the user's birthday was not passed to the server.
  - Pull Request [#49](https://github.com/BLOCKvIO/ios-sdk/pull/49)
- Add delete current user endpoint (for internal use only).
  - Pull Request [#48](https://github.com/BLOCKvIO/ios-sdk/pull/48)
- Add trash vatom endpoint
  - Pull Request [#45](https://github.com/BLOCKvIO/ios-sdk/pull/45)

---

## [1.1.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/1.1.0)

Released on 2018-07-10.

#### Added

- Changelog to keep track of SDK changes.
  - Pull Request [#44](https://github.com/BLOCKvIO/ios-sdk/pull/44)
- Allow a vAtom to be sent to the trash.
  - Pull Request [#43](https://github.com/BLOCKvIO/ios-sdk/pull/43) , [#45](https://github.com/BLOCKvIO/ios-sdk/pull/45)
- Adopted Swiftlint as the linter.
  - Pull Request [#41](https://github.com/BLOCKvIO/ios-sdk/pull/41)

#### Updated

- Inventory params now match Android.
  - Pull Request [#42](https://github.com/BLOCKvIO/ios-sdk/pull/42)
- Readme to reflect beta status.
  - Pull Request [#40](https://github.com/BLOCKvIO/ios-sdk/pull/40)

#### Upgrade Notes
This release has breaking changes.

- The `getInventory` method takes `id` as its first param, instead of `parentId`. The behavior is unchanged.

## [1.0.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/1.0.0)

Released on 2018-06-30.

#### Added

- Send message endpoint.
  - Pull Request [#38](https://github.com/BLOCKvIO/ios-sdk/pull/38)
- Activity endpoints.
  - Pull Request [#31](https://github.com/BLOCKvIO/ios-sdk/pull/31)
- Web socket integration.
  - Pull Request [#28](https://github.com/BLOCKvIO/ios-sdk/pull/28)
  
#### Updated

- Error codes.
  - Pull Request [#35](https://github.com/BLOCKvIO/ios-sdk/pull/35).
- Group model renaming.
  - Pull Request [#33](https://github.com/BLOCKvIO/ios-sdk/pull/33).

#### Fixed

- Remove unecessary fields from FullTokenModel.
  - Pull Request [#30](https://github.com/BLOCKvIO/ios-sdk/pull/30).
- Failing vAtom resource URLs no longer prevent vAtoms from decoding.
  - Pull Request [#29](https://github.com/BLOCKvIO/ios-sdk/pull/29).
  
#### Upgrade Notes

This release has breaking changes.

---

## [0.9.10](https://github.com/BLOCKvIO/ios-sdk/releases/tag/0.9.10)

Released on 2018-06-26.
  
#### Added

- Enforce re-authorization.
  - Pull Request [#26](https://github.com/BLOCKvIO/ios-sdk/pull/26).
  
## [0.9.9](https://github.com/BLOCKvIO/ios-sdk/releases/tag/0.9.9)
  Released on 2018-06-21.

#### Added

- Geo discover vAtoms (geo search).
  - Pull Request [#24](https://github.com/BLOCKvIO/ios-sdk/pull/24).
- Geo discover groups (geo count search).
  - Pull Request [#24](https://github.com/BLOCKvIO/ios-sdk/pull/24).
