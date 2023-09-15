## [8.17.2](https://github.com/amplitude/Amplitude-iOS/compare/v8.17.1...v8.17.2) (2023-09-15)


### Bug Fixes

* fix the compatible issue with macOSSonoma ([#463](https://github.com/amplitude/Amplitude-iOS/issues/463)) ([fd9495f](https://github.com/amplitude/Amplitude-iOS/commit/fd9495f7c3cfcd13047b36b0cebc81bdc0e62731))

## [8.17.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.17.0...v8.17.1) (2023-07-06)


### Bug Fixes

* remove MD5 usage ([#456](https://github.com/amplitude/Amplitude-iOS/issues/456)) ([4e2d35f](https://github.com/amplitude/Amplitude-iOS/commit/4e2d35fba1081ebd21124b8a8d3998509129be54))

# [8.17.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.16.4...v8.17.0) (2023-07-05)


### Features

* add default events ([#455](https://github.com/amplitude/Amplitude-iOS/issues/455)) ([9bf9664](https://github.com/amplitude/Amplitude-iOS/commit/9bf9664199d9c5ea7367205180e9ee3c52a9aaa7))

## [8.16.4](https://github.com/amplitude/Amplitude-iOS/compare/v8.16.3...v8.16.4) (2023-06-22)


### Bug Fixes

* avoid global variables in AMPIdentifyInterceptor to fix missing user properties updates ([#445](https://github.com/amplitude/Amplitude-iOS/issues/445)) ([eb820a2](https://github.com/amplitude/Amplitude-iOS/commit/eb820a254f1e13b617d3c81209f0b307a1f5de8e))

## [8.16.3](https://github.com/amplitude/Amplitude-iOS/compare/v8.16.2...v8.16.3) (2023-06-15)


### Bug Fixes

* malloc -> calloc to fix CWE-789 vulnerability ([#449](https://github.com/amplitude/Amplitude-iOS/issues/449)) ([3793d58](https://github.com/amplitude/Amplitude-iOS/commit/3793d58ec1b4091742efa5d01aeffb5e20c67646))

## [8.16.2](https://github.com/amplitude/Amplitude-iOS/compare/v8.16.1...v8.16.2) (2023-06-14)


### Bug Fixes

* bump dependencies to fix cocoapods vulnerability ([#448](https://github.com/amplitude/Amplitude-iOS/issues/448)) ([a57f4dc](https://github.com/amplitude/Amplitude-iOS/commit/a57f4dcda90760c7e8244496717155d196f6a9b2))

## [8.16.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.16.0...v8.16.1) (2023-05-30)


### Bug Fixes

* set _inForeground value earlier ([#433](https://github.com/amplitude/Amplitude-iOS/issues/433)) ([3cee4c2](https://github.com/amplitude/Amplitude-iOS/commit/3cee4c2db581ec8be5cbbf9e44d58e4a0b486504))
* sudo rm appledoc ([#444](https://github.com/amplitude/Amplitude-iOS/issues/444)) ([53ba490](https://github.com/amplitude/Amplitude-iOS/commit/53ba490e3b93de95af6164b14e29563531338522))
* XCode 14 fixes - update iPhone targets to 11, MacOS to 10.15, appledoc ([#442](https://github.com/amplitude/Amplitude-iOS/issues/442)) ([5c15979](https://github.com/amplitude/Amplitude-iOS/commit/5c159794dfcb2f14828c892ac3a5fefbb8226c25))

# [8.16.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.15.2...v8.16.0) (2023-04-26)


### Bug Fixes

* update identify collapsing logic to send actions on separate identify event ([#437](https://github.com/amplitude/Amplitude-iOS/issues/437)) ([9fb64c3](https://github.com/amplitude/Amplitude-iOS/commit/9fb64c30bb65aff375969b8f23119310d51b8a28))
* updated identify merging logic to ignore nil values ([#434](https://github.com/amplitude/Amplitude-iOS/issues/434)) ([8e1239c](https://github.com/amplitude/Amplitude-iOS/commit/8e1239c369e0dfe4c26f2dce1b05d093f6e18aff))


### Features

* update back off for rate limit ([#436](https://github.com/amplitude/Amplitude-iOS/issues/436)) ([9fc1ba9](https://github.com/amplitude/Amplitude-iOS/commit/9fc1ba9bcec8b7df3d80f9ec28edff40033d237e))

## [8.15.2](https://github.com/amplitude/Amplitude-iOS/compare/v8.15.1...v8.15.2) (2023-03-08)


### Bug Fixes

* fix os version ([#430](https://github.com/amplitude/Amplitude-iOS/issues/430)) ([23fcf7d](https://github.com/amplitude/Amplitude-iOS/commit/23fcf7d798c2c94cdba39489f72d9032388058ba))

## [8.15.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.15.0...v8.15.1) (2023-02-21)


### Bug Fixes

* transfer intercepted Identify's on user identity change ([#427](https://github.com/amplitude/Amplitude-iOS/issues/427)) ([3279b78](https://github.com/amplitude/Amplitude-iOS/commit/3279b787d531a474f70b833c36f52beafb3c7f18))

# [8.15.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.14.1...v8.15.0) (2023-02-15)


### Features

* AMP-66570 added IdentifyInterceptor ([#423](https://github.com/amplitude/Amplitude-iOS/issues/423)) ([0c7f0d4](https://github.com/amplitude/Amplitude-iOS/commit/0c7f0d4e7e3c41a1b71bee960127b69e5baf278a))

## [8.14.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.14.0...v8.14.1) (2023-02-08)


### Bug Fixes

* response handler when 200 and various errors ([#424](https://github.com/amplitude/Amplitude-iOS/issues/424)) ([74c9e57](https://github.com/amplitude/Amplitude-iOS/commit/74c9e5721cc6d4849eed5c55470a8437ad1ad987))

# [8.14.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.13.0...v8.14.0) (2022-10-05)


### Features

* add possibility to manually check in foreground ([#414](https://github.com/amplitude/Amplitude-iOS/issues/414)) ([9b8ada6](https://github.com/amplitude/Amplitude-iOS/commit/9b8ada694c212ba3f67a59467f6b924d03d622eb))

# [8.13.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.12.0...v8.13.0) (2022-09-08)


### Features

* add ingestion_metadata field ([#410](https://github.com/amplitude/Amplitude-iOS/issues/410)) ([49e1126](https://github.com/amplitude/Amplitude-iOS/commit/49e1126213d4b4cc9010d1bf32e4dec3a2855698))

# [8.12.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.11.1...v8.12.0) (2022-08-10)


### Features

* expose more function signature for logEvent ([#409](https://github.com/amplitude/Amplitude-iOS/issues/409)) ([c6195f8](https://github.com/amplitude/Amplitude-iOS/commit/c6195f85a3a2aa6a786485c0f5a8fa545e26acb6))

## [8.11.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.11.0...v8.11.1) (2022-07-31)


### Bug Fixes

* turn requiringSecureCoding on, adjust the available version ([#407](https://github.com/amplitude/Amplitude-iOS/issues/407)) ([53d7026](https://github.com/amplitude/Amplitude-iOS/commit/53d7026d75bbf87967576fb98d36d16f84a4def0))

# [8.11.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.10.2...v8.11.0) (2022-07-19)


### Bug Fixes

* deprecation fix ([#404](https://github.com/amplitude/Amplitude-iOS/issues/404)) ([2f1203c](https://github.com/amplitude/Amplitude-iOS/commit/2f1203c18f5e50d2a4699f93aadb9218e3c7df1c))


### Features

* add EU SSL pinning cert, extent it to support multiple domains ([#403](https://github.com/amplitude/Amplitude-iOS/issues/403)) ([aba104d](https://github.com/amplitude/Amplitude-iOS/commit/aba104d98f51b04481046cc4228cea1529139bd8))

## [8.10.2](https://github.com/amplitude/Amplitude-iOS/compare/v8.10.1...v8.10.2) (2022-06-21)


### Reverts

* Revert "Compile with code coverage enabled (#398)" (#402) ([bd00ae5](https://github.com/amplitude/Amplitude-iOS/commit/bd00ae527e154204eccbde595f9c7bdf4aec982a)), closes [#398](https://github.com/amplitude/Amplitude-iOS/issues/398) [#402](https://github.com/amplitude/Amplitude-iOS/issues/402)

## [8.10.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.10.0...v8.10.1) (2022-06-15)


### Bug Fixes

* wrong carrier info with deprecated method ([#400](https://github.com/amplitude/Amplitude-iOS/issues/400)) ([2af05da](https://github.com/amplitude/Amplitude-iOS/commit/2af05da0651cf032aee394e471349ad9ce5587df))

# [8.10.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.9.0...v8.10.0) (2022-03-31)


### Features

* Add versionId to tracking plan data ([#392](https://github.com/amplitude/Amplitude-iOS/issues/392)) ([a09f022](https://github.com/amplitude/Amplitude-iOS/commit/a09f02230a76b85ce3e12400cf6613cd03a68ab0))

# [8.9.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.8.0...v8.9.0) (2022-03-30)


### Bug Fixes

* fix release action ([5eb7ee6](https://github.com/amplitude/Amplitude-iOS/commit/5eb7ee6c363c8c6c11cab965cdd0201e581d8843))


### Features

* Add support on Swift Package Manager for WatchOS ([#381](https://github.com/amplitude/Amplitude-iOS/issues/381)) ([74d3227](https://github.com/amplitude/Amplitude-iOS/commit/74d3227cf5b069bac45f6e26d1c7e357bc0bb936))

# [8.8.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.7.2...v8.8.0) (2022-02-10)


### Bug Fixes

* update swift package to support connector package ([#383](https://github.com/amplitude/Amplitude-iOS/issues/383)) ([95501aa](https://github.com/amplitude/Amplitude-iOS/commit/95501aa6f1938cf40bb5f22abfa76dfea7b87843))


### Features

* Support seamless integration with amplitude experiment SDK ([#378](https://github.com/amplitude/Amplitude-iOS/issues/378)) ([26e7830](https://github.com/amplitude/Amplitude-iOS/commit/26e78304f6436d6c1aefd2065936a6c7e8576978))

## [8.7.2](https://github.com/amplitude/Amplitude-iOS/compare/v8.7.1...v8.7.2) (2022-01-23)


### Bug Fixes

* show correct device info for ios app runs on M1 mac ([#379](https://github.com/amplitude/Amplitude-iOS/issues/379)) ([7a75adb](https://github.com/amplitude/Amplitude-iOS/commit/7a75adbee74aad675a50a7b7006b2952c11a73f0))

## [8.7.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.7.0...v8.7.1) (2021-12-22)


### Bug Fixes

* fix method for swift ([#377](https://github.com/amplitude/Amplitude-iOS/issues/377)) ([293f665](https://github.com/amplitude/Amplitude-iOS/commit/293f665ffba077c9c90199c1ca856f775c0ca540))

# [8.7.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.6.0...v8.7.0) (2021-12-17)


### Features

* public the setEventUploadMaxBatchSize api ([#376](https://github.com/amplitude/Amplitude-iOS/issues/376)) ([86b8ea9](https://github.com/amplitude/Amplitude-iOS/commit/86b8ea9aad3e4e9835f116fd247726a1b6eb37dc))

# [8.6.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.5.0...v8.6.0) (2021-12-08)


### Bug Fixes

* Add watchOS scheme for building with Carthage ([#351](https://github.com/amplitude/Amplitude-iOS/issues/351)) ([4b893a8](https://github.com/amplitude/Amplitude-iOS/commit/4b893a8423316dc1053bfd33db6c5997f5332c93))


### Features

* add middleware support ([#371](https://github.com/amplitude/Amplitude-iOS/issues/371)) ([02a0994](https://github.com/amplitude/Amplitude-iOS/commit/02a09945be92d9334140a69f8b4b7b7f25d1643d))

# [8.5.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.4.0...v8.5.0) (2021-10-22)


### Features

* add server zone for eu dynamic configuration support ([#369](https://github.com/amplitude/Amplitude-iOS/issues/369)) ([3c9a590](https://github.com/amplitude/Amplitude-iOS/commit/3c9a590a7fd4fa60445ba8d65915a41737877b94))

# [8.4.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.3.1...v8.4.0) (2021-09-24)


### Features

* add observe plan information support ([62e8bab](https://github.com/amplitude/Amplitude-iOS/commit/62e8bab0a2d53cabda9f251454d465d350271a56))

## [8.3.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.3.0...v8.3.1) (2021-08-21)


### Bug Fixes

* rename to initCompletionBlock ([f43a86c](https://github.com/amplitude/Amplitude-iOS/commit/f43a86c576af02957cacae3aac96fabba9c71450))

# [8.3.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.2.1...v8.3.0) (2021-04-30)


### Bug Fixes

* fix umbrella header warning ([#346](https://github.com/amplitude/Amplitude-iOS/issues/346)) ([f5d10f7](https://github.com/amplitude/Amplitude-iOS/commit/f5d10f751402e91492c74558dc5da49c90c7c427))


### Features

* Add preInsert, postInsert and remove functions to Identify and Group Identify ([#338](https://github.com/amplitude/Amplitude-iOS/issues/338)) ([4cc28bf](https://github.com/amplitude/Amplitude-iOS/commit/4cc28bf3950d5aa91f0a3a494bd1318da8119d6c))

## [8.2.1](https://github.com/amplitude/Amplitude-iOS/compare/v8.2.0...v8.2.1) (2021-04-01)


### Bug Fixes

* Cocoapods resources directory path fix ([#336](https://github.com/amplitude/Amplitude-iOS/issues/336)) ([8680587](https://github.com/amplitude/Amplitude-iOS/commit/8680587c9fd3e207c974d55c2f907d026e1f6ccd))

# [8.2.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.1.0...v8.2.0) (2021-03-18)


### Features

* **podspec:** Add defines modules to podspec for React Native support ([#331](https://github.com/amplitude/Amplitude-iOS/issues/331)) ([e7d1257](https://github.com/amplitude/Amplitude-iOS/commit/e7d1257ea025f08d82e76f6809a9fa671e9672af))

# [8.1.0](https://github.com/amplitude/Amplitude-iOS/compare/v8.0.0...v8.1.0) (2021-03-16)


### Features

* Add support for watchOS ([#330](https://github.com/amplitude/Amplitude-iOS/issues/330)) ([9db310a](https://github.com/amplitude/Amplitude-iOS/commit/9db310a91e264ab84a3bcc871818da9d031300bf))

# [8.0.0](https://github.com/amplitude/Amplitude-iOS/compare/v7.3.0...v8.0.0) (2021-03-06)


### Bug Fixes

* Removes event explorer to fix problems with swift package manager import ([#329](https://github.com/amplitude/Amplitude-iOS/issues/329)) ([11022b8](https://github.com/amplitude/Amplitude-iOS/commit/11022b89f344d85bef5530e37c2e844ede1950f3))

# [7.3.0](https://github.com/amplitude/Amplitude-iOS/compare/v7.2.2...v7.3.0) (2021-02-22)


### Features

* Set content-type header for HTTP requests ([#328](https://github.com/amplitude/Amplitude-iOS/issues/328)) ([21f138c](https://github.com/amplitude/Amplitude-iOS/commit/21f138c3886e781004f6604ba6b1e1f07dfdb9a4))

## [7.2.2](https://github.com/amplitude/Amplitude-iOS/compare/v7.2.1...v7.2.2) (2020-12-23)


### Bug Fixes

* SPM SSL Pinning file discovery bug ([#319](https://github.com/amplitude/Amplitude-iOS/issues/319)) ([9878134](https://github.com/amplitude/Amplitude-iOS/commit/987813420d47b66ccc19d4ff18d69e6b7e483346))

## [7.2.1](https://github.com/amplitude/Amplitude-iOS/compare/v7.2.0...v7.2.1) (2020-12-02)


### Bug Fixes

* Make resources files to be visible inside xcode project ([#313](https://github.com/amplitude/Amplitude-iOS/issues/313)) ([64aa1ad](https://github.com/amplitude/Amplitude-iOS/commit/64aa1ad48d9682a562e9a3d85f4b8b1797a41303))
* SPM macOS/tvOS disable event explorer ([#315](https://github.com/amplitude/Amplitude-iOS/issues/315)) ([e3e763c](https://github.com/amplitude/Amplitude-iOS/commit/e3e763c08d6879d6c002c8031f3d5baffd8abb26))

# [7.2.0](https://github.com/amplitude/Amplitude-iOS/compare/v7.1.1...v7.2.0) (2020-10-26)


### Bug Fixes

* macOS 10.11/10.13 compile warning fix ([#309](https://github.com/amplitude/Amplitude-iOS/issues/309)) ([d834b6c](https://github.com/amplitude/Amplitude-iOS/commit/d834b6c58d0aae77802399330e751fc418b66f3d))


### Features

* Add setSessionId to public API ([#312](https://github.com/amplitude/Amplitude-iOS/issues/312)) ([7db7d34](https://github.com/amplitude/Amplitude-iOS/commit/7db7d3441d16a8a86b712b1e0a8fa9918b3a40ae))

## [7.1.1](https://github.com/amplitude/Amplitude-iOS/compare/v7.1.0...v7.1.1) (2020-10-20)


### Bug Fixes

* **buildsettings:** Remove override for GCC_WARN_INHIBIT_ALL_WARNINGS ([#302](https://github.com/amplitude/Amplitude-iOS/issues/302)) ([0e55297](https://github.com/amplitude/Amplitude-iOS/commit/0e552979efb9595b77567cd3796b106534fc3e70))
* **deprecation warnings:** Fix deprecation warnings ([#301](https://github.com/amplitude/Amplitude-iOS/issues/301)) ([e7b0e6e](https://github.com/amplitude/Amplitude-iOS/commit/e7b0e6ef6a6fb8ee74ff2ca5f81d978823206bd3)), closes [/github.com/amplitude/Amplitude-iOS/issues/250#issuecomment-655224554](https://github.com//github.com/amplitude/Amplitude-iOS/issues/250/issues/issuecomment-655224554)
* **deprecations:** Use DEPRECATED_MSG_ATTRIBUTE instead of notes ([#305](https://github.com/amplitude/Amplitude-iOS/issues/305)) ([f501c6c](https://github.com/amplitude/Amplitude-iOS/commit/f501c6cf60ffa7e224a661527979e58a5a773c1f))
* nil dynamic config refresh crash ([#288](https://github.com/amplitude/Amplitude-iOS/issues/288)) ([#289](https://github.com/amplitude/Amplitude-iOS/issues/289)) ([9dc896d](https://github.com/amplitude/Amplitude-iOS/commit/9dc896d94aa678a2b70de675ea3acbca587c602f))
* Swift UserId and DeviceId setter ([#299](https://github.com/amplitude/Amplitude-iOS/issues/299)) ([b7c0f90](https://github.com/amplitude/Amplitude-iOS/commit/b7c0f90e6bb8f2a2b51ed2602eab78b8f099ae1a))
* Explicitly add files in Resources for SPM ([#292](https://github.com/amplitude/Amplitude-iOS/issues/292)) ([61da6d3](https://github.com/amplitude/Amplitude-iOS/commit/61da6d3a6bfc880c9b73ba8f5260e97875e2b9ee))

## 7.1.0 (Sep 30, 2020)
* Add support to view/copy userId, deviceId to use Event Explorer (BETA). NOTE: This feature doesn't support Swift Package Manager yet.
* Removed Amplitude-iOS.podspec from repo.

## 7.0.1 (Sep 20, 2020)
* Fix issues for nullable/nonnull declaration in `Amplitude.h`
* Fix [#286](https://github.com/amplitude/Amplitude-iOS/issues/286)
* Fix [#285](https://github.com/amplitude/Amplitude-iOS/issues/285)

## 7.0.0 (Sep 14, 2020)

### BREAKING CHANGES
Background: Users reported that IDFA MACRO still do not prevent app rejections. So we make both idfa and location tracking to be fully customer driven.
* Add `adSupportBlock` to let idfa tracking to be customer driven. 
* Add `locationInfoBlock` to let location tracking to be customer driven.
* Remove `enableLocationListening`, `disableLocationListening` and `updateLocation` APIs.

## 6.0.0 (Aug 19, 2020)

* To accommodate the new rules over IDFA in iOS 14, we make some changes over our IDFA logic.
* Added `AMPLITUDE_IDFA_TRACKING` MACRO to control if IDFA logic is included in the binary.
* Removed `disableIdfaTracking` API.
* [Documentation](https://developers.amplitude.com/docs/ios-ios-advertising-id-idfa#ios)

## 5.3.0 (Aug 6, 2020)

* Introducing `useDynamicConfig` flag!! Turning this flag on will find the best server url automatically based on users' geo location.
* Note 1. If you have your own proxy server and use `setServerUrl` API, please leave this OFF.
* Note 2. If you have users in China Mainland, we suggest you turn this on.
* Note 3. By default, this feature is OFF. So you need to explicitly set it to ON to use it.

## 5.2.1 (Jul 6, 2020)

* Removed obsolete certificates used for SSL Pinning before.

## 5.2.0 (Jun 2, 2020)

* Fixed an implementation issue in SSL pinning. If you're using SSL pinning, please update your SDK ASAP.

## 5.1.0 (Mar 16, 2020)

* Added APIs to `Amplitude` to let users set `library` name and version. This should be only used when you develop your own library which wraps Amplitude iOS SDK. 

## 5.0.0 (Mar 12, 2020)

* Now macOS support!
* Covered both cases. (1) pure macOS App, (2) Mac Catalyst (Running iPad App on macOS)
* NOTE 1: CocoaPods users! `Amplitude-iOS` pod is deprecated (4.10.0 is the last version we support). Please use the new one  `Amplitude` going forward.
* NOTE 2: If you encounter any issues when instrumenting your macOS App, please reach out to us!
* NOTE 3: Minimum supported iOS version is now 10.0 instead of 8.0 in the past. We made this decision since usages for 9.0 and 8.0 are extremely low now. (<= 1%)

## 4.10.0 (Feb 4, 2020)

* Now you can enable or disable COPPA (Children's Online Privacy Protection Act) restrictions on IDFA, IDFV, city, IP address and location tracking. 
* To enable COPPA, please call `[[Amplitude instance] enableCoppaControl];`.
* To disable COPPA, please call `[[Amplitude instance] disableCoppaControl];`.
* Fix partial truncation for string with unicode (e.g. emoji).

## 4.9.3 (Nov 22, 2019)

* Fix error for not finding declaration for NSObject when using Swift Package Manager

## 4.9.0 (Nov 21, 2019)

* Added support for Swift Package Manager. Thanks @mayur1407 to add the support.

## 4.8.2 (Oct 19, 2019)

* Ensure background tasks are always ended and add safeguard before retrieving the app by checking for valid uploadTaskID


## 4.8.1 (Sep 19, 2019)

* Suppress NSLogs for non-dev environments.

## 4.8.0 (Sep 3, 2019)

* Identify Macs for Mac Catalyst support.

## 4.7.1 (Aug 20, 2019)

* Fix issue where tag wasn't included in tag spec

## 4.7.0 (Aug 20, 2019)

* Fix bug where background task might be stopped before final events are flushed
* Revert logic to restore db from memory on potential db resets

## 4.6.0 (Mar 1, 2019)

* Add support for installing on tvOS platform via Carthage
* Do not use IDFV or IDFA for device ID if disabled via tracking options
* Close Sqlite DB object even if open fails
* Made `startOrContinueSession` public method. Only call this if you know what you are doing. This may trigger a new session to start.
* Properly end background event flush task
* Increased minimum iOS deployment target to 8.0


## 4.5.0 (Dec 18, 2018)

* Add ability to set a custom server URL for uploading events using `setServerUrl`.

## 4.4.0 (Oct 15, 2018)

* Add ability to set group properties via a new `groupIdentifyWithGroupType` method that takes in an `AMPIdentify` object as well as a group type and group name.

## 4.3.1 (Aug 14, 2018)

* Update SDK to better handle SQLite Exceptions.

## 4.3.0 (Jul 24, 2018)

* Add `AMPTrackingOptions` interface to customize the automatic tracking of user properties in the SDK (such as language, ip_address, platform, etc). See [Help Center Documentation](https://amplitude.zendesk.com/hc/en-us/articles/115002278527#disable-automatic-tracking-of-properties) for instructions on setting up this configuration.

## 4.2.1 (May 21, 2018)

* Fix a bunch of compiler warnings
* Fix SSLPinning import so that it doesn't corrupt debug console. Thanks to @rob-keepsafe for the PR

## 4.2.0 (Apr 19, 2018)

* Added a `setUserId` method with optional boolean argument `startNewSession`, which when `YES` starts a new session after changing the userId.

## 4.1.0 (Feb 27, 2018)
* Add option to disable IDFA tracking. To disable IDFA tracking call `[[Amplitude instance] disableIdfaTracking];` before initializing with your API key.

## 4.0.4 (Oct 23, 2017)

* Fix bug where events in the initial session for brand new users have a session id of -1 (introduced in v4.0.2).

## 4.0.3 (Oct 16, 2017)

* Fix unknown carrier caching. This fixes "Could not successfully update network info during initialization" warnings when logging events on devices without SIM cards.

## 4.0.2 (Oct 13, 2017)

* Ensure the foreground checker in `initializeApiKey` runs on the main thread. This fixes the "UI API called on a background thread" warning.
* Removing unnecessary try / catch when looking up device carrier.

## 4.0.1 (Sep 18, 2017)

* Lowering minimum required iOS version down to 7.0.

## 4.0.0 (Sep 18, 2017)

* Minimum required iOS version is now 9.0
* Removed deprecated methods, fixed warnings in Xcode 9, adding support for iOS 11.
* Migrate setup instructions and SDK documentation in the README file to Zendesk articles.

## 3.14.1 (Mar 14, 2017)

* Catch exceptions when looking up device carrier.
* Fix build warnings caused by certificate files in the Podfile. Thanks to @benasher44 for the PR.
* Fix warnings for missing new line at end of files. Thanks to @teanet for reporting.
* Fix linker warnings when using Amplitude framework in an extension target. Thanks to @r-peck for the PR.

## 3.14.0 (Feb 2, 2017)

* Add support for enabling SSL-pinning via Cocoapods. Thanks to @aaronwasserman for the PR. See [Readme](https://github.com/amplitude/amplitude-ios#ssl-pinning) for more information.

## 3.13.0 (Jan 30, 2017)

* Add support for tvOS. Thanks to @gabek for the original PR. See [Readme](https://github.com/amplitude/Amplitude-iOS#tvos) for more information.
* Bump iOS minimum deployment target to 6.0.
* Update device list. Thanks to @subbotkin for the PR.

## 3.12.1 (Dec 15, 2016)

* Fix bug where `regenerateDeviceId` was not being run on background thread.
* `[AMPDeviceInfo generateUUID]` should be a static method.

## 3.12.0 (Dec 5, 2016)

* Add helper method to regenerate a new random deviceId. This can be used in conjunction with `setUserId:nil` to anonymize a user after they log out. Note this is not recommended unless you know what you are doing. See [Readme](https://github.com/amplitude/Amplitude-iOS#logging-out-and-anonymous-users) for more information.

## 3.11.1 (Nov 7, 2016)

* Allow `logEvent` with a custom long long timestamp (milliseconds since epoch). See [iOS documentation](https://rawgit.com/amplitude/Amplitude-iOS/v3.11.1/documentation/html/Classes/Amplitude.html#//api/name/logEvent:withEventProperties:withGroups:withLongLongTimestamp:outOfSession:) for more details.

## 3.11.0 (Nov 7, 2016)

* Allow `logEvent` with a custom timestamp (milliseconds since epoch). If the timestamp value is `nil`, then the event is timestamped with the current time. If setting a custom timestamp, you should use `[NSNumber numberWithLongLong:milliseconds]`. See [iOS documentation](https://rawgit.com/amplitude/Amplitude-iOS/master/documentation/html/Classes/Amplitude.html#//api/name/logEvent:withEventProperties:withGroups:withTimestamp:outOfSession:) for more details.

## 3.10.1 (Oct 31, 2016)

* Enable "Weak References in Manual Retain Release" to fix build errors in Xcode 7.3 and up.

## 3.10.0 (Oct 26, 2016)

* Add ability to log identify events outOfSession, this is useful for updating user properties without triggering session-handling logic. See [Readme](https://github.com/amplitude/Amplitude-iOS#tracking-sessions) for more information.

## 3.9.0 (Oct 7, 2016)

* Switch to unarchiving unsent events archive file with `[NSKeyedUnarchiver unarchiveObjectWithFile]` to iOS 9's `[NSKeyedUnarchiver unarchiveTopLevelObjectWithData]`. Note: this only affects you if you are *upgrading from an SDK version older than v3.1.0 straight to v3.9.0 or newer*. Users who have not updated to iOS 9.0 or newer will lose any unsent events stored on their devices. This also removes all Objective-C Exceptions (@try/@catch) from the SDK, removing the need to toggle `Enable Objective-C Exceptions` in Xcode.
* Block event property and user property dictionaries that have more than 1000 items. This is to block properties that are set unintentionally (for example in a loop). A single call to `logEvent` should not have more than 1000 event properties. Similarly a single call to `setUserProperties` should not have more than 1000 user properties.

## 3.8.5 (Aug 29, 2016)

* Fix crash by handling NULL events saved to and fetched from the database.

## 3.8.4 Re-release (Aug 19, 2016)

* Added support for integration via Carthage. Thanks to @mpurland for the original PR. Thanks to @lexrus for follow up PR to fix framework naming.
* Cleaned up warnings for expression result unused.
* Note if you installed 3.8.4 on August 18, just rerun `pod install` or `carthage update` to pull in the new changes. The re-release was to fix the Carthage framework naming.

## 3.8.3 (Jul 18, 2016)

* Fix overflow bug for long long values saved to Sqlite DB on 32-bit devices.

## 3.8.2 (Jul 11, 2016)

* `productId` is no longer a required field for `Revenue` logged via `logRevenueV2`.
* Fix bug where revenue receipt was being truncated if it was too long (exceeded 1024 characters);

## 3.8.1 (Jun 14, 2016)

* Allow ability to silence error messages. Note error messages are printed by default. To disable error logging, change `AMPLITUDE_LOG_ERRORS` from `1` to `0` in `Amplitude.m`.

## 3.8.0 (Jun 13, 2016)

* Add support for iOS Extensions. See the [Readme](https://github.com/amplitude/amplitude-ios#ios-extensions) for instructions, or check out our [iOS-Extension-Demo](https://github.com/amplitude/iOS-Extension-Demo). Credit to @andyyc for the original PR.
* Fix bug where subsequent calls to `initializeApiKey` after the first were not being ignored.
* Guard debug log statements with a debug flag (disabled by default). To enable debug logging, change `AMPLITUDE_DEBUG` from `0` to `1` at the top of the Objective-C file you wish to examine.

## 3.7.1 (Jun 10, 2016)

* Add documentation for SDK functions. You can take a look [here](https://rawgit.com/amplitude/Amplitude-iOS/master/documentation/html/index.html). A link has also been added to the Readme.
* Updated device mapping with iPhone SE, iPad Mini 4, and iPad Pro.
* Fix crash during upgradePrefs in the init method. This bug affected app users who were upgrading from an old version of an app using Amplitude iOS v2.1.1 or earlier straight to a version of the app using Amplitude iOS v3.6.0 or later.

## 3.7.0 (Apr 20, 2016)

* Add helper method `getSessionId` to expose the current sessionId value.
* Add support for setting groups for users and events. See [Readme](https://github.com/amplitude/Amplitude-iOS#setting-groups) for more information.
* Add logRevenueV2 and new Revenue class to support logging revenue events with properties, and revenue type. See [Readme](https://github.com/amplitude/Amplitude-iOS#tracking-revenue) for more info.

## 3.6.0 (Mar 28, 2016)

* Add support for prepend user property operation.
* Fix support for 32-bit devices. Switch to using sqlite3.0, and cast return values from sqlite3.
* Add support for logging events to multiple Amplitude apps. See [Readme](https://github.com/amplitude/Amplitude-iOS#tracking-events-to-multiple-amplitude-apps) for details.

## 3.5.0 (Jan 15, 2016)

* Add ability to clear all user properties.

## 3.4.1 (Dec 31, 2015)

* Guarding AMPDatabaseHelper logging with a debug flag.

## 3.4.0 (Dec 29, 2015)

* Remove dependency on FMDB, use built-in SQLite3 library.
* Updated DeviceInfo platform strings, added iPhone 6s, iPhone 6s Plus, iPod Touch 6G.
* Fix bug to make sure events can be serialized before saving.

## 3.3.0 (Dec 15, 2015)

* Add support for append user property operation.
* Add ability to force the SDK to update with the user's latest location.

## 3.2.1 (Nov 11, 2015)

* Handle NaNs and exceptions from NSJSONSerialization during event data migration.
* Fix bug where logEvent checks session when logging start/end session events.
* Update DatabaseHelper to work with long longs instead of longs.

## 3.2.0 (Oct 20, 2015)

* Add ability to set custom deviceId.
* Add support for user property operations (set, setOnce, add, unset).
* Add ability to go offline (disable sending logged events to server).
* Fix bug where event and identify queues are not truncated if eventMaxCount is less than eventRemoveBatchSize.
* Fix bug where fetching nil/null values from database causes crash.

## 3.1.1 (Oct 8, 2015)

* Switch to using FMDB/standard.

## 3.1.0 (Oct 5, 2015)

* Migrate events data to Sqlite database.
* Fix bug where end session event was not being sent upon app reopen.
* Fix bug in database path.

## 3.0.1 (Sep 21, 2015)

* Fix uploadEventsWithDelay bug not triggering uploadEvents.
* Fix crash when dictionaries are deallocated during logEvent.

## 3.0.0 (Aug 20, 2015)

* Simplified session tracking. minTimeBetweenSessionsMillis default changed to 5 minutes. Removed sessionTimeoutMillis. No longer send start/end session events by default.
* Can now clear userId by setting to nil (subsequent logged events will be anonymous).

## 2.5.1 (Jun 12, 2015)

* Fix crash when array or dictionary is modified during JSON serialization.

## 2.5.0 (May 29, 2015)

* Static methods are now deprecated. Use the [Amplitude instance] singleton instead.
* Enable configuration of eventUploadThreshold, eventMaxCount,
  eventUploadMaxBatchSize, eventUploadPeriodSeconds, minTimeBetweenSessionsMillis,
  and sessionTimeoutMillis.

## 2.4.0 (Apr 7, 2015)

* Expose the startSession method publicly. Can be used to start a session for a user
  interaction that happens while the app is in the background, for example,
  changing tracks on background audio.
* No longer starts a session if the app is in the background when the SDK is
  initialized. Prevents logging of silent push notifications from starting
  a session and counting a user visit. This changes the previous default
  behavior. To maintain the previous behavior, use
  initializeApiKey:apiKey:userId:startSession and set startSession to true.

## 2.3.0 (Mar 21, 2015)

* Add opt out method to disable logging for a user
* Fix CLLocationManager authorization constants warning
* Add method for adding new user properties without replacing. Make it default
* Fix base64 string deprecation warning

## 2.2.4 (Jan 4, 2015)

* Fixed regressive crash on updateLocation. Fixes issue #22

## 2.2.3 (Dec 29, 2014)

* Fix bug where start session is called more than once when app enters foreground
* Change SDK to use a singleton instead of class methods
* Initialize deviceId properly in _getDeviceId. Fixes issue #20
* Fixed AMPDeviceInfo for non-ARC applications

## 2.2.2 (Nov 12, 2014)

* Update field names
* Split platform and os
* Send library information

## 2.2.1 (Nov 8, 2014)

* Fix long long to long warning
* Fix non-retained CTTelephonyNetworkInfo object

## 2.2.0 (Oct 29, 2014)

* Remove unused methods getPlatformString, getPhoneModel, and replaceWithJSONNull
* Change some method signatures to be cleaner
* Fix race condition setting session id
* Fix double release for CTTelephonyNetworkInfo
* Fix memory leak in generateUUID
* Send IDFA and IDFV
* Change data directory to be NSLibraryDirectory instead of NSCachesDirectory

## 2.1.1 (Aug 6, 2014)

* Ensure events are JSON serializable

## 2.1.0 (Jun 5, 2014)

* Cache device id in getDeviceId
* Add logRevenue method with receipt options
* Fix bug with ending on background task prematurely

## 2.0.0 (Mar 7, 2014)

* Added LICENSE file
* Fix bug where session id didn't match session start timestamp
* Lowered advertiserID version requirement to 6.0 and up
* Added advertisingIdentifier as an optional device identifier
* Fix bug when flushQueue dictionary value setting to empty array
* Changed reupload to only occur when beyond the number of max events to store locally
* Removed mac address, advertiser ID from user tracked
* Switched to identiferForVendor, otherwise randomly generated ID.
* Renamed customProperties to eventProperties
* Removed redundant saving of apiProperties in each event
* Removed campaign tracking code
* Renamed globalProperties to userProperties
* Fixing background task bug when app is minimized and maximized quickly a few times causing a dangling task to never be ended

## 1.0.2 (Oct 3, 2013)

* Fix warning by explicitly cast NSMakeRange arguments to int
* Fix bug with creating location manager off the main thread

## 1.0.1 (Aug 2, 2013)

* Save deviceId in local storage to ensure consistency
* Added iOS7 forward compatibility by using advertiserId by default on iOS7.0+
* Generate random UUID on mac address failure
* Fixed rare location access concurency bug
* Switch to native NSJSONSerialization

## 1.0.0 (Apr 11, 2013)

* Initial packaged release
