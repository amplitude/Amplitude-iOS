[![Circle CI](https://circleci.com/gh/amplitude/Amplitude-iOS/tree/master.svg?style=badge&circle-token=e1b2a7d2cd6dd64ac3643bc8cb2117c0ed5cbb75)](https://circleci.com/gh/amplitude/Amplitude-iOS/tree/master)

Amplitude iOS SDK
====================

An iOS SDK for tracking events and revenue to [Amplitude](http://www.amplitude.com).

A [demo application](https://github.com/amplitude/iOS-Demo) is available to show a simple integration.

# Setup #
1. If you haven't already, go to https://amplitude.com and register for an account. You will receive an API Key.
2. [Download the source code](https://github.com/amplitude/Amplitude-iOS/archive/master.zip) and extract the zip file. Alternatively, you can pull directly from GitHub. If you use CocoaPods, add the following line to your Podfile: `pod 'Amplitude-iOS', '~> 3.2.1'`
3. Copy the Amplitude-iOS folder into the source of your project in XCode. Check "Copy items into destination group's folder (if needed)".

4. In every file that uses analytics, import Amplitude.h at the top:
    ``` objective-c
    #import "Amplitude.h"
    ```

5. In the application:didFinishLaunchingWithOptions: method of your YourAppNameAppDelegate.m file, initialize the SDK:
    ``` objective-c
    [[Amplitude instance] initializeApiKey:@"YOUR_API_KEY_HERE"];
    ```

6. To track an event anywhere in the app, call:
    ``` objective-c
    [[Amplitude instance] logEvent:@"EVENT_IDENTIFIER_HERE"];
    ```

7. Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close. After calling logEvent in your app, you will immediately see data appear on the Amplitude Website.

# Tracking Events #

It's important to think about what types of events you care about as a developer. You should aim to track between 20 and 200 types of events within your app. Common event types are different screens within the app, actions the user initiates (such as pressing a button), and events you want the user to complete (such as filling out a form, completing a level, or making a payment). Contact us if you want assistance determining what would be best for you to track.

# Tracking Sessions #

A session is a period of time that a user has the app in the foreground. Sessions within 5 minutes of each other are merged into a single session. In the iOS SDK, sessions are tracked automatically. When the SDK is initialized, it determines whether the app is launched into the foreground or background and starts a new session if launched in the foreground. A new session is created when the app comes back into the foreground after being out of the foreground for 5 minutes or more.

You can adjust the time window for which sessions are extended by changing the variable minTimeBetweenSessionsMillis:
``` objective-c
[Amplitude instance].minTimeBetweenSessionsMillis = 30 * 60 * 1000; // 30 minutes
[[Amplitude instance] initializeApiKey:@"YOUR_API_KEY_HERE"];
```

By default start and end session events are no longer sent. To renable add this line before initializing the SDK:
``` objective-c
[[Amplitude instance] trackingSessionEvents:YES];
[[Amplitude instance] initializeApiKey:@"YOUR_API_KEY_HERE"];
```

You can also log events as out of session. Out of session events have a session_id of -1 and are not considered part of the current session, meaning they do not extend the current session. You can log events as out of session by setting input parameter outOfSession to true when calling logEvent.

``` objective-c
[[Amplitude instance] logEvent:@"EVENT_IDENTIFIER_HERE" withEventProperties:nil outOfSession:true];
```

# Setting Custom User IDs #

If your app has its own login system that you want to track users with, you can call `setUserId:` at any time:

``` objective-c
[[Amplitude instance] setUserId:@"USER_ID_HERE"];
```

You can also clear the user ID by calling `setUserId` with input `nil`. Events without a user ID are anonymous.

A user's data will be merged on the backend so that any events up to that point on the same device will be tracked under the same user.

You can also add the user ID as an argument to the `initializeApiKey:` call:

``` objective-c
[[Amplitude instance] initializeApiKey:@"YOUR_API_KEY_HERE" userId:@"USER_ID_HERE"];
```

# Setting Event Properties #

You can attach additional data to any event by passing a NSDictionary object as the second argument to logEvent:withEventProperties:

``` objective-c
NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
[eventProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
[[Amplitude instance] logEvent:@"Compute Hash" withEventProperties:eventProperties];
```

# Setting User Properties

To add properties that are associated with a user, you can set user properties:

``` objective-c
NSMutableDictionary *userProperties = [NSMutableDictionary dictionary];
[userProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
[[Amplitude instance] setUserProperties:userProperties];
```

To replace any existing user properties with a new set:

``` objective-c
NSMutableDictionary *userProperties = [NSMutableDictionary dictionary];
[userProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
[[Amplitude instance] setUserProperties:userProperties replace:YES];
```

# User Property Operations #

The SDK supports the operations set, setOnce, unset, and add on individual user properties. The operations are declared via a provided `AMPIdentify` interface. Multiple operations can be chained together in a single `AMPIdentify` object. The `AMPIdentify` object is then passed to the Amplitude client to send to the server. The results of the operations will be visible immediately in the dashboard, and take effect for events logged after. Note, each
operation on the `AMPIdentify` object returns the same instance, allowing you to chain multiple operations together.

1. `set`: this sets the value of a user property.

    ``` objective-c
    AMPIdentify *identify = [[[AMPIdentify identify] set:@"gender" value:@"female"] set:@"age" value:[NSNumber numberForInt:20]];
    [[Amplitude instance] identify:identify];
    ```

2. `setOnce`: this sets the value of a user property only once. Subsequent `setOnce` operations on that user property will be ignored. In the following example, `sign_up_date` will be set once to `08/24/2015`, and the following setOnce to `09/14/2015` will be ignored:

    ``` objective-c
    AMPIdentify *identify1 = [[AMPIdentify identify] setOnce:@"sign_up_date" value:@"09/06/2015"];
    [[Amplitude instance] identify:identify1];

    AMPIdentify *identify2 = [[AMPIdentify identify] setOnce:@"sign_up_date" value:@"10/06/2015"];
    [[Amplitude instance] identify:identify2];
    ```

3. `unset`: this will unset and remove a user property.

    ``` objective-c
    AMPIdentify *identify = [[[AMPIdentify identify] unset:@"gender"] unset:@"age"];
    [[Amplitude instance] identify:identify];
    ```

4. `add`: this will increment a user property by some numerical value. If the user property does not have a value set yet, it will be initialized to 0 before being incremented.

    ``` objective-c
    AMPIdentify *identify = [[[AMPIdentify identify] add:@"karma" value:[NSNumber numberWithFloat:0.123]] add:@"friends" value:[NSNumber numberWithInt:1]];
    [[Amplitude instance] identify:identify];
    ```

Note: if a user property is used in multiple operations on the same `Identify` object, only the first operation will be saved, and the rest will be ignored. In this example, only the set operation will be saved, and the add and unset will be ignored:

```objective-c
AMPIdentify *identify = [[[[AMPIdentify identify] set:@"karma" value:[NSNumber numberWithInt:10]] add:@"friends" value:[NSNumber numberWithInt:1]] unset:@"karma"];
    [[Amplitude instance] identify:identify];
```

# Allowing Users to Opt Out

To stop all event and session logging for a user, call setOptOut:

``` objective-c
[[Amplitude instance] setOptOut:YES];
```

Logging can be restarted by calling setOptOut again with enabled set to NO.
No events will be logged during any period opt out is enabled, even after opt
out is disabled.

# Tracking Revenue #

To track revenue from a user, call

``` objective-c
[[Amplitude instance] logRevenue:@"productIdentifier" quantity:1 price:[NSNumber numberWithDouble:3.99]]
```

after a successful purchase transaction. `logRevenue:` takes a string to identify the product (can be pulled from `SKPaymentTransaction.payment.productIdentifier`). `quantity:` takes an integer with the quantity of product purchased. `price:` takes a NSNumber with the dollar amount of the sale as the only argument. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

**To enable revenue verification, copy your iTunes Connect In App Purchase Shared Secret into the manage section of your app on Amplitude. You must put a key for every single app in Amplitude where you want revenue verification.**

Then call

``` objective-c
[[Amplitude instance] logRevenue:@"productIdentifier" quantity:1 price:[NSNumber numberWithDouble:3.99 receipt:receiptData]
```

after a successful purchase transaction. `receipt:` takes the receipt NSData from the app store. For details on how to obtain the receipt data, see [Apple's guide on Receipt Validation](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1).

# Swift #

This SDK will work with Swift. If you are copying the source files or using CocoaPods without the `use_frameworks!` directive, you should create a bridging header as documented [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html) and add the following line to your bridging header:

``` objective-c
#import "Amplitude.h"
```

If you have `use_frameworks!` set, you should not use a bridging header and instead use the following line in your swift files:

``` swift
import Amplitude_iOS
```

In either case, you can call Amplitude methods with `Amplitude.instance().method(...)`

# Advanced #

This SDK automatically grabs useful data from the phone, including app version, phone model, operating system version, and carrier information. If the user has granted your app location permissions, the SDK will also grab the location of the user. Amplitude will never prompt the user for location permissions itself, this must be done by your app. Amplitude only polls for a location once on startup of the app, once on each app open, and once when the permission is first granted. There is no continuous tracking of location. If you wish to disable location tracking done by the app, you can call `[[Amplitude instance] disableLocationListening]` at any point. If you want location tracking disabled on startup of the app, call disableLocationListening before you call `initializeApiKey:`. You can always reenable location tracking through Amplitude with `[[Amplitude instance] enableLocationListening]`.

User IDs are automatically generated and will default to device specific identifiers if not specified.

Device IDs are randomly generated. You can, however, choose to instead use the identifierForVendor (if available) by calling `[[Amplitude instance] useAdvertisingIdForDeviceId]` before initializing with your API key. You can also retrieve the Device ID that Amplitude uses with `[[Amplitude instance] getDeviceId]`.

If you have your own system for tracking device IDs and would like to set a custom device ID, you can do so with `[[Amplitude instance] setDeviceId:@"CUSTOM_DEVICE_ID"];` **Note: this is not recommended unless you really know what you are doing.** Make sure the device ID you set is sufficiently unique (we recommend something like a UUID - see `[AMPUtils generateUUID]` for an example on how to generate) to prevent conflicts with other devices in our system.

This code will work with both ARC and non-ARC projects. Preprocessor macros are used to determine which version of the compiler is being used.

The SDK includes support for SSL pinning, but it is undocumented and recommended against unless you have a specific need. Please contact Amplitude support before you ship any products with SSL pinning enabled so that we are aware and can provide documentation and implementation help.
