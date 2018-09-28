# Change Log
All notable changes to this project will be documented in this file.

#### 2.x Releases (API v1)
- `2.0.x` Releases -  [2.0.0](#200)

#### 1.x Releases (API v1)
- `1.1.x` Releases - [1.1.0](#110)
- `1.0.x` Releases - [1.0.0](#100)

#### 0.x Releases (API v1)
- `0.9.x` Releases - [0.9.9](#099) | [0.9.10](#0910)

---

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
- Create an intermediary `UnpackedModel` to allow an unpacked response to be packeded into an array of `VatomModel`.
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

----

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
