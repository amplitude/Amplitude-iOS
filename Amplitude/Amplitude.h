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

 For more details on the setup and usage, be sure to check out the docs here:
 https://github.com/amplitude/Amplitude-iOS#setup
 */
@interface Amplitude : NSObject

#pragma mark - Properties
@property (nonatomic, readonly) NSString *apiKey;
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *deviceId;
@property (nonatomic, assign) BOOL optOut;

/*!
 The maximum number of events that can be stored locally before forcing an upload.
 The default is 30 events.
 */
@property (nonatomic, assign) int eventUploadThreshold;

/*!
 The maximum number of events that can be uploaded in a single request.
 The default is 100 events.
 */
@property (nonatomic, assign) int eventUploadMaxBatchSize;

/*!
 The maximum number of events that can be stored lcoally.
 The default is 1000 events.
 */
@property (nonatomic, assign) int eventMaxCount;

/*!
 The amount of time after an event is logged that events will be batched before being uploaded to the server.
 The default is 30 seconds.
 */
@property (nonatomic, assign) int eventUploadPeriodSeconds;

/*!
 When a user closes and reopens the app within minTimeBetweenSessionsMillis milliseconds, the reopen is considered part of the same session and the session continues. Otherwise, a new session is created.
 The default is 15000 milliseconds (15 seconds).
 */
@property (nonatomic, assign) long minTimeBetweenSessionsMillis;

/*!
 A session will time out automatically after a period of inactivity. If the user has performed no events within sessionTimeoutMillis milliseconds, a new session is created on the next event logged.
 The default is 1800000 milliseconds (30 minutes).
 */
@property (nonatomic, assign) long sessionTimeoutMillis;

#pragma mark - Methods

+ (Amplitude *)instance;

/*!
 @method

 @abstract
 Initializes the Amplitude static class with your Amplitude api key.

 @param apiKey                 Your Amplitude key obtained from your dashboard at https://amplitude.com/settings
 @param userId                 If your app has its own login system that you want to track users with, you can set the userId.
 @param startSession           Whether or not to automatically start a user session at the time of initialization. By default, initialization automatically starts a session if it determinesthe app is active. This parameter overrides that default behavior. Useful for initialization when tracking push notifications receipt.

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
- (void)initializeApiKey:(NSString*) apiKey;
- (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId;
- (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId startSession:(BOOL)startSession;

- (void)startSession;

/*!
 @method

 @abstract
 Tracks an event

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object.

 @discussion
 Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close.
 After calling logEvent in your app, you will immediately see data appear on the Amplitude Website.

 It's important to think about what types of events you care about as a developer. You should aim to track
 between 10 and 100 types of events within your app. Common event types are different screens within the app,
 actions the user initiates (such as pressing a button), and events you want the user to complete
 (such as filling out a form, completing a level, or making a payment).
 Contact us if you want assistance determining what would be best for you to track. (contact@amplitude.com)
 */
- (void)logEvent:(NSString*) eventType;
- (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties;

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
- (void)logRevenue:(NSNumber*) amount;
- (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price;
- (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price receipt:(NSData*) receipt;

/*!
 @method

 @abstract
 Manually forces the class to immediately upload all queued events.

 @discussion
 Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close.
 Use this method to force the class to immediately upload all queued events.
 */
- (void)uploadEvents;

/*!
 @method

 @abstract
 Adds properties that are tracked on the user level.

 @param userProperties          An NSDictionary containing any additional data to be tracked.

 @discussion
 Property keys must be <code>NSString</code> objects and values must be serializable.
 */

- (void)setUserProperties:(NSDictionary*) userProperties;
- (void)setUserProperties:(NSDictionary*) userProperties replace:(BOOL) replace;

/*!
 @method

 @abstract
 Sets the userId.

 @param userId                  If your app has its own login system that you want to track users with, you can set the userId.

 @discussion
 If your app has its own login system that you want to track users with, you can set the userId.
 */
- (void)setUserId:(NSString*) userId;

/*!
 @method

 @abstract
 Enables tracking opt out.

 @param enabled                  Whether tracking opt out should be enabled or disabled.

 @discussion
 If the user wants to opt out of all tracking, use this method to enable opt out for them. Once opt out is enabled, no events will be saved locally or sent to the server. Calling this method again with enabled set to false will turn tracking back on for the user.
 */
- (void)setOptOut:(BOOL)enabled;

/*!
 @method

 @abstract
 Enables location tracking.

 @discussion
 If the user has granted your app location permissions, the SDK will also grab the location of the user.
 Amplitude will never prompt the user for location permissions itself, this must be done by your app.
 */
- (void)enableLocationListening;

/*!
 @method

 @abstract
 Disables location tracking.

 @discussion
 If you want location tracking disabled on startup of the app, call disableLocationListening before you call initializeApiKey.
 */
- (void)disableLocationListening;

/*!
 @method

 @abstract
 Uses advertisingIdentifier instead of identifierForVendor as the device ID

 @discussion
 Apple prohibits the use of advertisingIdentifier if your app does not have advertising. Useful for tying together data from advertising campaigns to anlaytics data. Must be called before initializeApiKey: is called to function.
 */
- (void)useAdvertisingIdForDeviceId;

/*!
 @method

 @abstract
 Prints the number of events in the queue.

 @discussion
 Debugging method to find out how many events are being stored locally on the device.
 */
- (void)printEventsCount;

/*!
 @method

 @abstract
 Returns deviceId

 @discussion
 The deviceId is an identifier used by Amplitude to determine unique users when no userId has been set.
 */
- (NSString*)getDeviceId;


#pragma mark - Static methods (deprecated)

+ (void)initializeApiKey:(NSString*) apiKey __attribute((deprecated()));

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId __attribute((deprecated()));

+ (void)logEvent:(NSString*) eventType __attribute((deprecated()));

+ (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties __attribute((deprecated()));

+ (void)logRevenue:(NSNumber*) amount __attribute((deprecated()));

+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price __attribute((deprecated())) __attribute((deprecated()));

+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price receipt:(NSData*) receipt __attribute((deprecated()));

+ (void)uploadEvents __attribute((deprecated()));

+ (void)setUserProperties:(NSDictionary*) userProperties __attribute((deprecated()));

+ (void)setUserId:(NSString*) userId __attribute((deprecated()));

+ (void)enableLocationListening __attribute((deprecated()));

+ (void)disableLocationListening __attribute((deprecated()));

+ (void)useAdvertisingIdForDeviceId __attribute((deprecated()));

+ (void)printEventsCount __attribute((deprecated()));

+ (NSString*)getDeviceId __attribute((deprecated()));
@end
