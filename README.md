# Setup #
1. If you haven't already, go to https://amplitude.com and register for an account. You will receive an API Key.
2. [Download the source code](https://github.com/amplitude/Amplitude-iOS/archive/master.zip) and extract the zip file. Alternatively, you can pull directly from GitHub. If you use Cocoapods, add the following line to your Podfile: `pod 'Amplitude-iOS', '~> 2.1'`
3. Copy the Amplitude-iOS folder into the source of your project in XCode. Check "Copy items into destination group's folder (if needed)".

4. In every file that uses analytics, import Amplitude.h at the top:
    ``` objective-c
    #import "Amplitude.h"
    ```

5. In the application:didFinishLaunchingWithOptions: method of your YourAppNameAppDelegate.m file, initialize the SDK:
    ``` objective-c
    [Amplitude initializeApiKey:@"YOUR_API_KEY_HERE"];
    ```

6. To track an event anywhere in the app, call:
    ``` objective-c
    [Amplitude logEvent:@"EVENT_IDENTIFIER_HERE"];
    ```

7. Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close. After calling logEvent in your app, you will immediately see data appear on the Amplitude Website.

# Tracking Events #

It's important to think about what types of events you care about as a developer. You should aim to track between 20 and 200 types of events within your app. Common event types are different screens within the app, actions the user initiates (such as pressing a button), and events you want the user to complete (such as filling out a form, completing a level, or making a payment). Contact us if you want assistance determining what would be best for you to track.

# Tracking Sessions #

A session is a period of time that a user has the app in the foreground. Sessions within 10 seconds of each other are merged into a single session. In the iOS SDK, sessions are tracked automatically.

# Setting Custom User IDs #

If your app has its own login system that you want to track users with, you can call `setUserId:` at any time:

``` objective-c
[Amplitude setUserId:@"USER_ID_HERE"];
```

A user's data will be merged on the backend so that any events up to that point on the same device will be tracked under the same user.

You can also add the user ID as an argument to the `initializeApiKey:` call:

``` objective-c
[Amplitude initializeApiKey:@"YOUR_API_KEY_HERE" userId:@"USER_ID_HERE"];
```

# Setting Event Properties #

You can attach additional data to any event by passing a NSDictionary object as the second argument to logEvent:withEventProperties:

``` objective-c
NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
[eventProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
[Amplitude logEvent:@"Compute Hash" withEventProperties:eventProperties];
```

# Setting User Properties

To add properties that are associated with a user, you can set user properties:

``` objective-c
NSMutableDictionary *userProperties = [NSMutableDictionary dictionary];
[userProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
[Amplitude setUserProperties:userProperties];
```

# Tracking Revenue #

To track revenue from a user, call

``` objective-c
[Amplitude logRevenue:@"productIdentifier" quantity:1 price:[NSNumber numberWithDouble:3.99]]
```

after a successful purchase transaction. `logRevenue:` takes a string to identify the product (can be pulled from `SKPaymentTransaction.payment.productIdentifier`). `quantity:` takes an integer with the quantity of product purchased. `price:` takes a NSNumber with the dollar amount of the sale as the only argument. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

**To enable revenue verification, copy your iTunes Connect In App Purchase Shared Secret into the manage section of your app on Amplitude. You must put a key for every single app in Amplitude where you want revenue verification.**

Then call

``` objective-c
[Amplitude logRevenue:@"productIdentifier" quantity:1 price:[NSNumber numberWithDouble:3.99 receipt:receiptData]
```

after a successful purchase transaction. `receipt:` takes the receipt NSData from the app store. For details on how to obtain the receipt data, see [Apple's guide on Receipt Validation](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW1).

# Advanced #

This SDK automatically grabs useful data from the phone, including app version, phone model, operating system version, and carrier information. If the user has granted your app location permissions, the SDK will also grab the location of the user. Amplitude will never prompt the user for location permissions itself, this must be done by your app. Amplitude only polls for a location once on startup of the app, once on each app open, and once when the permission is first granted. There is no continuous tracking of location. If you wish to disable location tracking done by the app, you can call `[Amplitude disableLocationListening]` at any point. If you want location tracking disabled on startup of the app, call disableLocationListening before you call `initializeApiKey:`. You can always reenable location tracking through Amplitude with `[Amplitude enableLocationListening]`.

User IDs are automatically generated and will default to device specific identifiers if not specified.

Device IDs use identifierForVendor if available, or a random ID otherwise. You can retrieve the Device ID that Amplitude uses with `[Amplitude getDeviceId]`.

This code will work with both ARC and non-ARC projects. Preprocessor macros are used to determine which version of the compiler is being used.
