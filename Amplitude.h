//
// Amplitude.h

#import <Foundation/Foundation.h>


/*!
 @class
 Amplitude API.
 
 @abstract
 The interface for integrating Amplitude with your application.
 
 @discussion
 Use the Amplitude class to track events in your application.
 
 <pre>
 // In every file that uses analytics, import Amplitude.h at the top
 #import "Amplitude.h"
 
 // First, be sure to initialize the API in your didFinishLaunchingWithOptions delegate
 [Amplitude initializeApiKey:@"YOUR_API_KEY_HERE"];
 
 // Track an event anywhere in the app
 [Amplitude logEvent:@"EVENT_IDENTIFIER_HERE"];
 
 // You can attach additional data to any event by passing a NSDictionary object
 NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
 [eventProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
 [Amplitude logEvent:@"Compute Hash" withEventProperties:eventProperties];
 </pre>
 
 For me details on the setup and usage, be sure to check out the docs here:
 https://github.com/amplitude/Amplitude-iOS#setup
 */
@interface Amplitude : NSObject

// Step 1: Initialization
// ----------------------

/*!
 @method
 
 @abstract
 Initializes the Amplitude static class with your Amplitude api key.
 
 @param apiKey                 Your Amplitude key obtained from your dashboard at https://amplitude.com/settings
 @param userId                 If your app has its own login system that you want to track users with, you can set the userId.
 
 @discussion
 We recommend you first initialize your class within your "didFinishLaunchingWithOptions" method inside your app delegate.
 
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 {
 // Initialize your shared Analytics instance.
 [Amplitude initializeApiKey:@"YOUR_API_KEY_HERE"];
 
 // YOUR OTHER APP LAUNCH CODE HERE....
 
 return YES;
 }
 */
+ (void)initializeApiKey:(NSString*) apiKey;
+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId;

// Step 2: Track an event
// -------------------------------------

/*!
 @method

 @abstract
 Tracks an event

 @param eventType                The name of the event you wish to track.
 @param eventProperties         You can attach additional data to any event by passing a NSDictionary object.

 @discussion
 Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close. 
 After calling logEvent in your app, you will immediately see data appear on the Amplitude Website.
 
 It's important to think about what types of events you care about as a developer. You should aim to track 
 between 10 and 100 types of events within your app. Common event types are different screens within the app,
 actions the user initiates (such as pressing a button), and events you want the user to complete 
 (such as filling out a form, completing a level, or making a payment). 
 Contact us if you want assistance determining what would be best for you to track. (contact@amplitude.com)
 */
+ (void)logEvent:(NSString*) eventType;
+ (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties;

/*!
 @method
 
 @abstract
 Tracks revenue.
 
 @param amount                   The amount of revenue to track, e.g. "3.99".
 
 @discussion
 To track revenue from a user, call [Amplitude logRevenue:[NSNumber numberWithDouble:3.99]] each time the user generates revenue. 
 logRevenue: takes in an NSNumber with the dollar amount of the sale as the only argument. This allows us to automatically display 
 data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, 
 lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.
 
 For validating revenue, use [Amplitude logRevenue:@"com.company.app.productId" quantity:1 price:[NSNumber numberWithDouble:3.99] receipt:transactionReceipt]
 */
+ (void)logRevenue:(NSNumber*) amount;
+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price;
+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price receipt:(NSData*) receipt;



/*!
 @method
 
 @abstract
 Manually forces the class to immediately upload all queued events.
 
 @discussion
 Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close.
 Use this method to force the class to immediately upload all queued events.
 */
+ (void)uploadEvents;

// Step 3: Set event properties (optional)
// -------------------------------------

/*!
 @method
 
 @abstract
 Adds properties that are tracked on the user level.
 
 @param userProperties         An NSDictionary containing any additional data to be tracked.
 
 @discussion
 Property keys must be <code>NSString</code> objects and values must be serializable.
 */
+ (void)setUserProperties:(NSDictionary*) userProperties;

/*!
 @method
 
 @abstract
 Sets the userId.
 
 @param userId                   If your app has its own login system that you want to track users with, you can set the userId.
 
 @discussion
 If your app has its own login system that you want to track users with, you can set the userId.
 */
+ (void)setUserId:(NSString*) userId;

// Step 4: Advanced customizations and features (optional)
// -------------------------------------

/*!
 @method
 
 @abstract
 Enables location tracking.
 
 @discussion
 If the user has granted your app location permissions, the SDK will also grab the location of the user. 
 Amplitude will never prompt the user for location permissions itself, this must be done by your app.
 */
+ (void)enableLocationListening;

/*!
 @method
 
 @abstract
 Disables location tracking.
 
 @discussion
 If you want location tracking disabled on startup of the app, call disableLocationListening before you call initializeApiKey.
 */
+ (void)disableLocationListening;

/*!
 @method
 
 @abstract
 Uses advertisingIdentifier instead of identifierForVendor as the device ID
 
 @discussion
 Apple prohibits the use of advertisingIdentifier if your app does not have advertising. Useful for tying together data from advertising campaigns to anlaytics data. Must be called before initializeApiKey: is called to function.
 */
+ (void)useAdvertisingIdForDeviceId;

/*!
 @method
 
 @abstract
 Prints the number of events in the queue.
 
 @discussion
 Debugging method to find out how many events are being stored locally on the device.
 */
+ (void)printEventsCount;

/*!
 @method

 @abstract
 Returns deviceId

 @discussion
 The deviceId is an identifier used by Amplitude to determine unique users when no userId has been set.
 */
+ (NSString*)getDeviceId;
@end
