## Unreleased

## 3.8.1 (June 14, 2016)

* Allow ability to silence error messages. Note error messages are printed by default. To disable error logging, change `AMPLITUDE_LOG_ERRORS` from `1` to `0` in `Amplitude.m`.

## 3.8.0 (June 13, 2016)

* Add support for iOS Extensions. See the [Readme](https://github.com/amplitude/amplitude-ios#ios-extensions) for instructions, or check out our [iOS-Extension-Demo](https://github.com/amplitude/iOS-Extension-Demo). Credit to @andyyc for the original PR.
* Fix bug where subsequent calls to `initializeApiKey` after the first were not being ignored.
* Guard debug log statements with a debug flag (disabled by default). To enable debug logging, change `AMPLITUDE_DEBUG` from `0` to `1` at the top of the Objective-C file you wish to examine.

## 3.7.1 (June 10, 2016)

* Add documentation for SDK functions. You can take a look [here](https://rawgit.com/amplitude/Amplitude-iOS/master/documentation/html/index.html). A link has also been added to the Readme.
* Updated device mapping with iPhone SE, iPad Mini 4, and iPad Pro.
* Fix crash during upgradePrefs in the init method. This bug affected app users who were upgrading from an old version of an app using Amplitude iOS v2.1.1 or earlier straight to a version of the app using Amplitude iOS v3.6.0 or later.

## 3.7.0 (April 20, 2016)

* Add helper method `getSessionId` to expose the current sessionId value.
* Add support for setting groups for users and events. See [Readme](https://github.com/amplitude/Amplitude-iOS#setting-groups) for more information.
* Add logRevenueV2 and new Revenue class to support logging revenue events with properties, and revenue type. See [Readme](https://github.com/amplitude/Amplitude-iOS#tracking-revenue) for more info.

## 3.6.0 (March 28, 2016)

* Add support for prepend user property operation.
* Fix support for 32-bit devices. Switch to using sqlite3.0, and cast return values from sqlite3.
* Add support for logging events to multiple Amplitude apps. See [Readme](https://github.com/amplitude/Amplitude-iOS#tracking-events-to-multiple-amplitude-apps) for details.

## 3.5.0 (January 15, 2016)

* Add ability to clear all user properties.

## 3.4.1 (December 31, 2015)

* Guarding AMPDatabaseHelper logging with a debug flag.

## 3.4.0 (December 29, 2015)

* Remove dependency on FMDB, use built-in SQLite3 library.
* Updated DeviceInfo platform strings, added iPhone 6s, iPhone 6s Plus, iPod Touch 6G.
* Fix bug to make sure events can be serialized before saving.

## 3.3.0 (December 15, 2015)

* Add support for append user property operation.
* Add ability to force the SDK to update with the user's latest location.

## 3.2.1 (November 11, 2015)

* Handle NaNs and exceptions from NSJSONSerialization during event data migration.
* Fix bug where logEvent checks session when logging start/end session events.
* Update DatabaseHelper to work with long longs instead of longs.

## 3.2.0 (October 20, 2015)

* Add ability to set custom deviceId.
* Add support for user property operations (set, setOnce, add, unset).
* Add ability to go offline (disable sending logged events to server).
* Fix bug where event and identify queues are not truncated if eventMaxCount is less than eventRemoveBatchSize.
* Fix bug where fetching nil/null values from database causes crash.

## 3.1.1 (October 8, 2015)

* Switch to using FMDB/standard.

## 3.1.0 (October 5, 2015)

* Migrate events data to Sqlite database.
* Fix bug where end session event was not being sent upon app reopen.
* Fix bug in database path.

## 3.0.1 (September 21, 2015)

* Fix uploadEventsWithDelay bug not triggering uploadEvents.
* Fix crash when dictionaries are deallocated during logEvent.

## 3.0.0 (August 20, 2015)

* Simplified session tracking. minTimeBetweenSessionsMillis default changed to 5 minutes. Removed sessionTimeoutMillis. No longer send start/end session events by default.
* Can now clear userId by setting to nil (subsequent logged events will be anonymous).

## 2.5.1 (June 12, 2015)

* Fix crash when array or dictionary is modified during JSON serialization.

## 2.5.0 (May 29, 2015)

* Static methods are now deprecated. Use the [Amplitude instance] singleton instead.
* Enable configuration of eventUploadThreshold, eventMaxCount,
  eventUploadMaxBatchSize, eventUploadPeriodSeconds, minTimeBetweenSessionsMillis,
  and sessionTimeoutMillis.

## 2.4.0 (April 7, 2015)

* Expose the startSession method publicly. Can be used to start a session for a user
  interaction that happens while the app is in the background, for example,
  changing tracks on background audio.
* No longer starts a session if the app is in the background when the SDK is
  initialized. Prevents logging of silent push notifications from starting
  a session and counting a user visit. This changes the previous default
  behavior. To maintain the previous behavior, use
  initializeApiKey:apiKey:userId:startSession and set startSession to true.

## 2.3.0 (March 21, 2015)

* Add opt out method to disable logging for a user
* Fix CLLocationManager authorization constants warning
* Add method for adding new user properties without replacing. Make it default
* Fix base64 string deprecation warning

## 2.2.4 (January 4, 2015)

* Fixed regressive crash on updateLocation. Fixes issue #22

## 2.2.3 (December 29, 2014)

* Fix bug where start session is called more than once when app enters foreground
* Change SDK to use a singleton instead of class methods
* Initialize deviceId properly in _getDeviceId. Fixes issue #20
* Fixed AMPDeviceInfo for non-ARC applications

## 2.2.2 (November 12, 2014)

* Update field names
* Split platform and os
* Send library information

## 2.2.1 (November 8, 2014)

* Fix long long to long warning
* Fix non-retained CTTelephonyNetworkInfo object

## 2.2.0 (October 29, 2014)

* Remove unused methods getPlatformString, getPhoneModel, and replaceWithJSONNull
* Change some method signatures to be cleaner
* Fix race condition setting session id
* Fix double release for CTTelephonyNetworkInfo
* Fix memory leak in generateUUID
* Send IDFA and IDFV
* Change data directory to be NSLibraryDirectory instead of NSCachesDirectory

## 2.1.1 (August 6, 2014)

* Ensure events are JSON serializable

## 2.1.0 (June 5, 2014)

* Cache device id in getDeviceId
* Add logRevenue method with receipt options
* Fix bug with ending on background task prematurely

## 2.0.0 (March 7, 2014)

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

## 1.0.2 (October 3, 2013)

* Fix warning by explicitly cast NSMakeRange arguments to int
* Fix bug with creating location manager off the main thread

## 1.0.1 (August 2, 2013)

* Save deviceId in local storage to ensure consistency
* Added iOS7 forward compatibility by using advertiserId by default on iOS7.0+
* Generate random UUID on mac address failure
* Fixed rare location access concurency bug
* Switch to native NSJSONSerialization

## 1.0.0 (April 11, 2013)

* Initial packaged release
