## Unreleased

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
