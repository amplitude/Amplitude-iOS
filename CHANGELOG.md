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
