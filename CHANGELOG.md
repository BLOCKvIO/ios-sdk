# Change Log
All notable changes to this project will be documented in this file.

#### 1.x Releases (API v1)
- `1.1.x` Releases - [1.1.0](#110)
- `1.0.x` Releases - [1.0.0](#100)

#### 0.x Releases (API v1)
- `0.9.x` Releases - [0.9.9](#099) | [0.9.10](#0910)

---

## [1.1.0](https://github.com/BLOCKvIO/ios-sdk/releases/tag/1.1.0)
Released on TBC.

#### Added
- Changelog to keep track of SDK changes
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
