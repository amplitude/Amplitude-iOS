# Setup #
1. If you haven't already, go to http://giraffegraph.com and register for an account. You will receive an API Key.
2. [Download the source code](http://giraffegraph.com/static/downloads/giraffegraph-ios.zip) and extract the zip file.
3. Copy the GiraffeGraph-iOS folder into the source of your project in XCode. Check "Copy items into destination group's folder (if needed)".
4. In every file that uses analytics, you will need to place the following at the top:

        #import "EventLog.h"

5. In the application:didFinishLaunchingWithOptions: method of your YourAppNameAppDelegate.m file you need to initialize the SDK:

        [EventLog initializeApiKey:@"YOUR_API_KEY_HERE"];

6. To track an event anywhere in the app, call:

        [EventLog logEvent:@"EVENT_IDENTIFIER_HERE"];

7. Events are saved locally. Uploads are batched to occur every 10 events and every 10 seconds. After calling logEvent in your app, you will immediately see data appear on Giraffe Graph.

# Tracking Events #

It's important to think about what types of events you care about as a developer. You should aim to track at least 5 and no more than 50 types of events within your app. Common event types are different screens within the app, actions the user initiates (such as pressing a button), and events you want the user to complete (such as filling out a form, completing a level, or making a payment). Shoot me an email if you want assistance determining what would be best for you to track.

# Tracking Sessions #

A session is a period of time that a user has the app in the foreground. Sessions within 10 seconds of each other are merged into a single session. In the iOS SDK, sessions are tracked automatically.

# Settings Custom User IDs #

If your app has its own login system that you want to track users with, you can call the following at any time:

    [EventLog setUserId:@"USER_ID_HERE"];

You can also add the user ID as an argument to the initialize call:
    
    [EventLog initializeApiKey:@"YOUR_API_KEY_HERE" userId:@"USER_ID_HERE"];

Users data will be merged on the backend so that any events up to that point on the same device will be tracked under the same user.

# Setting Custom Properties #

You can attach additional data to any event by passing a NSDictionary object as the second argument to EventLog:withCustomProperties:

    NSMutableDictionary *customProperties = [NSMutableDictionary dictionary];
    [customProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
    [EventLog logEvent:@"Compute Hash" withCustomProperties:customProperties];

To add properties that are tracked in every event, you can set global properties for a user:

    NSMutableDictionary *globalProperties = [NSMutableDictionary dictionary];
    [globalProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
    [EventLog setGlobalUserProperties:globalProperties];

# Advanced #

This SDK automatically grabs useful data from the phone, including app version, phone model, operating system version, and carrier information. If your app has location permissions, the SDK will also grab the location of the user (this will not consume a lot of battery, as it only polls for significant location changes).

User IDs are automatically generated based on device specific identifiers if not specified.

This code will work with both ARC and non-ARC projects, as preprocessor macros are used to determine which version of the compiler is being used.
