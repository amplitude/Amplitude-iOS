//
//  Amplitude.h
//  Copyright (c) 2013 Amplitude Inc. (https://amplitude.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "AMPIdentify.h"
#import "AMPRevenue.h"
#import "AMPTrackingOptions.h"
#import "AMPPlan.h"
#import "AMPIngestionMetadata.h"
#import "AMPServerZone.h"
#import "AMPMiddleware.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *_Nonnull (^AMPAdSupportBlock)(void);
typedef NSDictionary *_Nullable (^AMPLocationInfoBlock)(void);
typedef void (^AMPInitCompletionBlock)(void);
/**
 Amplitude iOS SDK.

 Use the Amplitude SDK to track events in your application.

 Setup:

 1. In every file that uses analytics, import Amplitude.h at the top `#import "Amplitude.h"`
 2. Be sure to initialize the API in your didFinishLaunchingWithOptions delegate `[[Amplitude instance] initializeApiKey:@"YOUR_API_KEY_HERE"];`
 3. Track an event anywhere in the app `[[Amplitude instance] logEvent:@"EVENT_IDENTIFIER_HERE"];`
 4. You can attach additional data to any event by passing a NSDictionary object:

        NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
        [eventProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
        [[Amplitude instance] logEvent:@"Compute Hash" withEventProperties:eventProperties];

 **Note:** you should call SDK methods on an Amplitude instance, for example logging events with the default instance: `[[Amplitude instance] logEvent:@"testEvent"];`

 **Note:** the SDK supports tracking data to multiple Amplitude apps, via separate named instances. For example: `[[Amplitude instanceWithName:@"app1"] logEvent:@"testEvent"];` See [Tracking Events to Multiple Apps](https://github.com/amplitude/amplitude-ios#tracking-events-to-multiple-amplitude-apps).

 For more details on the setup and usage, be sure to checkout the [README](https://github.com/amplitude/Amplitude-iOS#amplitude-ios-sdk)
 */
@interface Amplitude : NSObject

#pragma mark - Properties

/**
 API key for your Amplitude App.
 */
@property (nonatomic, copy, readonly) NSString *apiKey;

/**
 Identifier for the current user.
 */
@property (nonatomic, copy, readonly, nullable) NSString *userId;

/**
 Identifier for the current device.
 */
@property (nonatomic, copy, readonly) NSString *deviceId;

/**
 Name of the SDK instance (ex: no name for default instance, or custom name for a named instance)
 */
@property (nonatomic, copy, readonly, nullable) NSString *instanceName;
@property (nonatomic, copy, readonly, nullable) NSString *propertyListPath;

/**
 Whether or to opt the current user out of tracking. If true then this blocks the logging of any events and properties, and blocks the sending of events to Amplitude servers.
 */
@property (nonatomic, assign, readwrite) BOOL optOut;

/**
 Turning this flag on will find the best server url automatically based on users' geo location.
 Note:
 1. If you have your own proxy server and use `setServerUrl` API, please leave this off.
 2. If you have users in China Mainland, we suggest you turn this on.
 */
@property (nonatomic, assign, readwrite) BOOL useDynamicConfig;


/**-----------------------------------------------------------------------------
 * @name Configurable SDK thresholds and parameters
 * -----------------------------------------------------------------------------
 */

/**
 The maximum number of events that can be stored locally before forcing an upload. The default is 30 events.
 */
@property (nonatomic, assign) int eventUploadThreshold;

/**
 The maximum number of events that can be uploaded in a single request. The default is 100 events.
 */
@property (nonatomic, assign) int eventUploadMaxBatchSize;

/**
 The maximum number of events that can be stored locally. The default is 1000 events.
 */
@property (nonatomic, assign) int eventMaxCount;

/**
 The amount of time after an event is logged that events will be batched before being uploaded to the server. The default is 30 seconds.
 */
@property (nonatomic, assign) int eventUploadPeriodSeconds;

/**
 When a user closes and reopens the app within minTimeBetweenSessionsMillis milliseconds, the reopen is considered part of the same session and the session continues. Otherwise, a new session is created. The default is 5 minutes.
 */
@property (nonatomic, assign) long minTimeBetweenSessionsMillis;

/**
 Whether to automatically log start and end session events corresponding to the start and end of a user's session.
 */
@property (nonatomic, assign) BOOL trackingSessionEvents;

/**
 Library name is default as `amplitude-ios`.
 Notice: You will only want to set it when following conditions are met.
 1. You develop your own library which bridges Amplitude iOS native library.
 2. You want to track your library as one of the data sources.
 */
@property (nonatomic, copy, nullable) NSString *libraryName;

/**
 Library version is default as the latest Amplitude iOS SDK version.
 Notice: You will only want to set it when following conditions are met.
 1. You develop your own library which bridges Amplitude iOS native library.
 2. You want to track your library as one of the data sources.
*/
@property (nonatomic, copy, nullable) NSString *libraryVersion;

/**
 * Sets a block to be called when IDFA / AdSupport identifier is created.
 * This is to allow for apps that do not want ad tracking to pass App Store guidelines in certain categories while
 * still allowing apps that do ad tracking to continue to function.  This block will be called repeatedly during
 * the life of the application as IDFA is needed.
 *
 * This achieve the previous SDK behavior use the example as follows.  It assumes you've handled any setup
 * and dialogs necessary to receive permissions from the user.
 *
 * Example:
 *      amplitude.adSupportBlock = ^{
 *          return [[ASIdentifierManager sharedManager] advertisingIdentifier];
 *      };
 */
@property (nonatomic, strong, nullable) AMPAdSupportBlock adSupportBlock;

/**
 * Sets a block to be called when location (latitude, longitude) information can be passed into an event.
 * This is to allow for apps that do not want location tracking to function without defining location permission while
 * still allowing apps that do location tracking to continue to function.  This block will be called repeatedly when
 * location information is needed for constructing an event.
 *
 * Location information is a NSDictionary with 2 keys in it, "lat" and "lng".
 * Example:
 *      amplitude.locationInfoBlock = ^{
 *          return @{
 *              @"lat" : @37.7,
 *              @"lng" : @122.4
 *              };
 *      };
 */
@property (nonatomic, strong, nullable) AMPLocationInfoBlock locationInfoBlock;

/**
 Content-Type header for event sending requests. Only relevant for sending events to a different URL (e.g. proxy server)
 */
@property (nonatomic, copy, readonly) NSString *contentTypeHeader;

/**
 * Sets a block to be called after completely initialized.
 *
 * Example:
 *  __typeof(amp) __weak weakAmp = amp;
 *  amp.initCompletionBlock = ^(void){
 *     NSLog(@"deviceId: %@, userId: %@", weakAmp.deviceId, weakAmp.userId);
 *  };
 */
@property (nonatomic, strong, nullable) AMPInitCompletionBlock initCompletionBlock;

/**
 * Defer the forground check in initializeApiKey.
 * checkInForeground need to be manually called in order to get the right config and session info if deferCheckInForeground = true has been set.
 */
@property (nonatomic, assign) BOOL deferCheckInForeground;

#pragma mark - Methods

/**-----------------------------------------------------------------------------
 * @name Fetching Amplitude SDK instance
 * -----------------------------------------------------------------------------
 */

/**
 This fetches the default SDK instance. Recommended if you are only logging events to a single app.

 @returns the default Amplitude SDK instance
 */
+ (Amplitude *)instance;

/**
 This fetches a named SDK instance. Use this if logging events to multiple Amplitude apps.

 @param instanceName the name of the SDK instance to fetch.

 @returns the Amplitude SDK instance corresponding to `instanceName`

 @see [Tracking Events to Multiple Amplitude Apps](https://github.com/amplitude/amplitude-ios#tracking-events-to-multiple-amplitude-apps)
 */
+ (Amplitude *)instanceWithName:(nullable NSString *)instanceName;

/**-----------------------------------------------------------------------------
 * @name Initialize the Amplitude SDK with your Amplitude API Key
 * -----------------------------------------------------------------------------
 */

/**
 Initializes the Amplitude instance with your Amplitude API key

 We recommend you first initialize your class within your "didFinishLaunchingWithOptions" method inside your app delegate.

 **Note:** this is required before you can log any events.

 @param apiKey Your Amplitude key obtained from your dashboard at https://amplitude.com/settings
 */
- (void)initializeApiKey:(NSString *)apiKey;

/**
 Initializes the Amplitude instance with your Amplitude API key and sets a user identifier for the current user.

 We recommend you first initialize your class within your "didFinishLaunchingWithOptions" method inside your app delegate.

 **Note:** this is required before you can log any events.

 @param apiKey Your Amplitude key obtained from your dashboard at https://amplitude.com/settings

 @param userId If your app has its own login system that you want to track users with, you can set the userId.

*/
- (void)initializeApiKey:(NSString *)apiKey userId:(nullable NSString *)userId;

/**
* Manually check in and set the forground related settings including dynamic config and sesstion. Need to be called manually when onEnterForeground if  deferCheckInForeground = true.
*/
- (void)checkInForeground;

/**-----------------------------------------------------------------------------
 * @name Logging Events
 * -----------------------------------------------------------------------------
 */

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)
 */
- (void)logEvent:(NSString *)eventType;

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object with property: value pairs.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)
 */
- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties;

- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties withMiddlewareExtra: (nullable NSMutableDictionary *) extra;

- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties withUserProperties:(NSDictionary *)userProperties;

- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties withUserProperties:(NSDictionary *)userProperties withMiddlewareExtra: (nullable NSMutableDictionary *) extra;

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object with property: value pairs.
 @param outOfSession             If YES, will track the event as out of session. Useful for push notification events.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)
 @see [Tracking Sessions](https://github.com/amplitude/Amplitude-iOS#tracking-sessions)
 */
- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties outOfSession:(BOOL)outOfSession;

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object with property: value pairs.
 @param groups                   You can specify event-level groups for this user by passing a NSDictionary object with groupType: groupName pairs. Note the keys need to be strings, and the values can either be strings or an array of strings.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)

 @see [Setting Groups](https://github.com/amplitude/Amplitude-iOS#setting-groups)
 */
- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties
      withGroups:(nullable NSDictionary *)groups;

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object with property: value pairs.
 @param groups                   You can specify event-level groups for this user by passing a NSDictionary object with groupType: groupName pairs. Note the keys need to be strings, and the values can either be strings or an array of strings.
 @param outOfSession             If YES, will track the event as out of session. Useful for push notification events.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)

 @see [Setting Groups](https://github.com/amplitude/Amplitude-iOS#setting-groups)

 @see [Tracking Sessions](https://github.com/amplitude/Amplitude-iOS#tracking-sessions)
 */
- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties
      withGroups:(nullable NSDictionary *)groups
    outOfSession:(BOOL)outOfSession;

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object with property: value pairs.
 @param groups                   You can specify event-level groups for this user by passing a NSDictionary object with groupType: groupName pairs. Note the keys need to be strings, and the values can either be strings or an array of strings.
 @param longLongTimestamp        You can specify a custom timestamp by passing the milliseconds since epoch UTC time as a long long.
 @param outOfSession             If YES, will track the event as out of session. Useful for push notification events.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)

 @see [Setting Groups](https://github.com/amplitude/Amplitude-iOS#setting-groups)

 @see [Tracking Sessions](https://github.com/amplitude/Amplitude-iOS#tracking-sessions)
 */
- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties withGroups:(nullable NSDictionary *)groups withLongLongTimestamp:(long long)longLongTimestamp outOfSession:(BOOL)outOfSession;

/**
 Tracks an event. Events are saved locally.

 Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.

 @param eventType                The name of the event you wish to track.
 @param eventProperties          You can attach additional data to any event by passing a NSDictionary object with property: value pairs.
 @param groups                   You can specify event-level groups for this user by passing a NSDictionary object with groupType: groupName pairs. Note the keys need to be strings, and the values can either be strings or an array of strings.
 @param timestamp                You can specify a custom timestamp by passing an NSNumber representing the milliseconds since epoch UTC time. We recommend using [NSNumber numberWithLongLong:milliseconds] to create the value. If nil is passed in, then the event will be timestamped with the current time.
 @param outOfSession             If YES, will track the event as out of session. Useful for push notification events.

 @see [Tracking Events](https://github.com/amplitude/amplitude-ios#tracking-events)

 @see [Setting Groups](https://github.com/amplitude/Amplitude-iOS#setting-groups)

 @see [Tracking Sessions](https://github.com/amplitude/Amplitude-iOS#tracking-sessions)
 */
- (void)logEvent:(NSString *)eventType withEventProperties:(nullable NSDictionary *)eventProperties
      withGroups:(nullable NSDictionary *)groups
   withTimestamp:(NSNumber *)timestamp
    outOfSession:(BOOL)outOfSession;

/**-----------------------------------------------------------------------------
 * @name Logging Revenue
 * -----------------------------------------------------------------------------
 */

/**
 Tracks revenue.

 To track revenue from a user, call [[Amplitude instance] logRevenue:[NSNumber numberWithDouble:3.99]] each time the user generates revenue. logRevenue: takes in an NSNumber with the dollar amount of the sale as the only argument. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

 @param amount                   The amount of revenue to track, e.g. "3.99".

 @see [LogRevenue Backwards Compatability](https://github.com/amplitude/Amplitude-iOS#backwards-compatibility)
 */
- (void)logRevenue:(NSNumber *)amount DEPRECATED_MSG_ATTRIBUTE("Use `logRevenueV2` and `AMPRevenue` instead");

/**
 Tracks revenue. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

 @param productIdentifier        The identifier for the product in the transaction, e.g. "com.amplitude.productId"
 @param quantity                 The number of products in the transaction. Revenue amount is calculated as quantity * price
 @param price                    The price of the products in the transaction. Revenue amount is calculated as quantity * price

 @see [LogRevenueV2](https://github.com/amplitude/Amplitude-iOS#tracking-revenue)
 @see [LogRevenue Backwards Compatability](https://github.com/amplitude/Amplitude-iOS#backwards-compatibility)
 */
- (void)logRevenue:(nullable NSString *)productIdentifier
          quantity:(NSInteger)quantity
             price:(NSNumber *)price DEPRECATED_MSG_ATTRIBUTE("Use `logRevenueV2` and `AMPRevenue` instead");

/**
 Tracks revenue. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

 For validating revenue, use [[Amplitude instance] logRevenue:@"com.company.app.productId" quantity:1 price:[NSNumber numberWithDouble:3.99] receipt:transactionReceipt]

 @param productIdentifier        The identifier for the product in the transaction, e.g. "com.amplitude.productId"
 @param quantity                 The number of products in the transaction. Revenue amount is calculated as quantity * price
 @param price                    The price of the products in the transaction. Revenue amount is calculated as quantity * price
 @param receipt                  The receipt data from the App Store. Required if you want to verify this revenue event.

 @see [LogRevenueV2](https://github.com/amplitude/Amplitude-iOS#tracking-revenue)
 @see [LogRevenue Backwards Compatability](https://github.com/amplitude/Amplitude-iOS#backwards-compatibility)
 @see [Revenue Verification](https://github.com/amplitude/Amplitude-iOS#revenue-verification)
 */
- (void)logRevenue:(nullable NSString *)productIdentifier
          quantity:(NSInteger)quantity
             price:(NSNumber *)price
           receipt:(nullable NSData *)receipt DEPRECATED_MSG_ATTRIBUTE("Use `logRevenueV2` and `AMPRevenue` instead");

/**
 Tracks revenue - API v2. This uses the `AMPRevenue` object to store transaction properties such as quantity, price, and revenue type. This is the recommended method for tracking revenue in Amplitude.

 For validating revenue, make sure the receipt data is set on the AMPRevenue object.

 To track revenue from a user, create an AMPRevenue object each time the user generates revenue, and set the revenue properties (productIdentifier, price, quantity). logRevenuev2: takes in an AMPRevenue object. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

 @param revenue AMPRevenue object       revenue object contains all revenue information

 @see [Tracking Revenue](https://github.com/amplitude/Amplitude-iOS#tracking-revenue)
 */
- (void)logRevenueV2:(AMPRevenue *)revenue;

/**-----------------------------------------------------------------------------
 * @name User Properties and User Property Operations
 * -----------------------------------------------------------------------------
 */

/**
 Update user properties using operations provided via Identify API.

 To update user properties, first create an AMPIdentify object. For example if you wanted to set a user's gender, and then increment their karma count by 1, you would do:

    AMPIdentify *identify = [[[AMPIdentify identify] set:@"gender" value:@"male"] add:@"karma" value:[NSNumber numberWithInt:1]];

 Then you would pass this AMPIdentify object to the identify function to send to the server:

    [[Amplitude instance] identify:identify];

 @param identify                   An AMPIdentify object with the intended user property operations

 @see [User Properties and User Property Operations](https://github.com/amplitude/Amplitude-iOS#user-properties-and-user-property-operations)

 */

- (void)identify:(AMPIdentify *)identify;

/**
 Update user properties using operations provided via Identify API. If outOfSession is `YES` then the identify event is logged with a session id of -1 and does not trigger any session-handling logic.

 To update user properties, first create an AMPIdentify object. For example if you wanted to set a user's gender, and then increment their karma count by 1, you would do:

 AMPIdentify *identify = [[[AMPIdentify identify] set:@"gender" value:@"male"] add:@"karma" value:[NSNumber numberWithInt:1]];

 Then you would pass this AMPIdentify object to the identify function to send to the server:

 [[Amplitude instance] identify:identify outOfSession:YES];

 @param identify                   An AMPIdentify object with the intended user property operations
 @param outOfSession               Whether to log identify event out of session

 @see [User Properties and User Property Operations](https://github.com/amplitude/Amplitude-iOS#user-properties-and-user-property-operations)

 */

- (void)identify:(AMPIdentify *)identify outOfSession:(BOOL)outOfSession;

/**

 Adds properties that are tracked on the user level.

 **Note:** Property keys must be <code>NSString</code> objects and values must be serializable.

 @param userProperties          An NSDictionary containing any additional data to be tracked.

 @see [Setting Multiple Properties with setUserProperties](https://github.com/amplitude/Amplitude-iOS#setting-multiple-properties-with-setuserproperties)
 */
- (void)setUserProperties:(NSDictionary *)userProperties;

/**
 Adds properties that are tracked on the user level.

 **Note:** Property keys must be <code>NSString</code> objects and values must be serializable.

 @param userProperties          An NSDictionary containing any additional data to be tracked.
 @param replace                 In earlier versions of this SDK, this replaced the in-memory userProperties dictionary with the input, but now userProperties are no longer stored in memory, so this parameter does nothing.

 @see [Setting Multiple Properties with setUserProperties](https://github.com/amplitude/Amplitude-iOS#setting-multiple-properties-with-setuserproperties)
 */
- (void)setUserProperties:(NSDictionary *)userProperties replace:(BOOL)replace DEPRECATED_MSG_ATTRIBUTE("Use `- setUserProperties` instead. In earlier versions of the SDK, `replace: YES` replaced the in-memory userProperties dictionary with the input. However, userProperties are no longer stored in memory, so the flag does nothing.");

/**
 Clears all properties that are tracked on the user level.

 **Note: the result is irreversible!**

 @see [Clearing user properties](https://github.com/amplitude/Amplitude-iOS#clearing-user-properties-with-clearuserproperties)
 */

- (void)clearUserProperties;

/**
 Adds a user to a group or groups. You need to specify a groupType and groupName(s).

 For example you can group people by their organization. In that case groupType is "orgId", and groupName would be the actual ID(s). groupName can be a string or an array of strings to indicate a user in multiple groups.

 You can also call setGroup multiple times with different groupTypes to track multiple types of groups (up to 5 per app).

 **Note:** this will also set groupType: groupName as a user property.

 @param groupType               You need to specify a group type (for example "orgId").

 @param groupName               The value for the group name, can be a string or an array of strings, (for example for groupType orgId, the groupName would be the actual id number, like 15).

 @see [Setting Groups](https://github.com/amplitude/Amplitude-iOS#setting-groups)
 */

- (void)setGroup:(NSString *)groupType groupName:(NSObject *)groupName;

- (void)groupIdentifyWithGroupType:(NSString *)groupType
                         groupName:(NSObject *)groupName
                     groupIdentify:(AMPIdentify *)groupIdentify;

- (void)groupIdentifyWithGroupType:(NSString *)groupType
                         groupName:(NSObject *)groupName
                     groupIdentify:(AMPIdentify *)groupIdentify
                      outOfSession:(BOOL)outOfSession;

/**-----------------------------------------------------------------------------
 * @name Setting User and Device Identifiers
 * -----------------------------------------------------------------------------
 */

/**
 Sets the userId and starts a new session.

 @param userId                  If your app has its own login system that you want to track users with, you can set the userId.
 @see [Setting Custom UserIds](https://github.com/amplitude/Amplitude-iOS#setting-custom-user-ids)
 */

- (void)setUserId:(nullable NSString *)userId;

/**
 Sets the userId. If startNewSession is true, the previous session for the previous user will be terminated and a new session will begin for the new userId.

 @param userId                  If your app has its own login system that you want to track users with, you can set the userId.

 @param startNewSession         Terminates previous user session and creates a new one for the new user

 @see [Setting Custom UserIds](https://github.com/amplitude/Amplitude-iOS#setting-custom-user-ids)
 */
- (void)setUserId:(nullable NSString *)userId startNewSession:(BOOL)startNewSession;

/**
 Sets the deviceId.

 **NOTE: not recommended unless you know what you are doing**

 @param deviceId                  If your app has its own system for tracking devices, you can set the deviceId.

 @see [Setting Custom Device Ids](https://github.com/amplitude/Amplitude-iOS#custom-device-ids)
 */
- (void)setDeviceId:(NSString *)deviceId;

/**-----------------------------------------------------------------------------
 * @name Configuring the SDK instance
 * -----------------------------------------------------------------------------
 */

/**
 Enables tracking opt out.

 If the user wants to opt out of all tracking, use this method to enable opt out for them. Once opt out is enabled, no events will be saved locally or sent to the server. Calling this method again with enabled set to NO will turn tracking back on for the user.

 @param enabled                  Whether tracking opt out should be enabled or disabled.
 */
- (void)setOptOut:(BOOL)enabled;

/**
 Sets event upload max batch size. This controls the maximum number of events sent with each upload request.

 @param eventUploadMaxBatchSize                  Set the event upload max batch size
 */
- (void)updateEventUploadMaxBatchSize:(int)eventUploadMaxBatchSize;

/**
 Disables sending logged events to Amplitude servers.

 If you want to stop logged events from being sent to Amplitude severs, use this method to set the client to offline. Once offline is enabled, logged events will not be sent to the server until offline is disabled. Calling this method again with offline set to NO will allow events to be sent to server and the client will attempt to send events that have been queued while offline.

 @param offline                  Whether logged events should be sent to Amplitude servers.
 */
- (void)setOffline:(BOOL)offline;

/**
 Uses advertisingIdentifier instead of identifierForVendor as the device ID

 Apple prohibits the use of advertisingIdentifier if your app does not have advertising. Useful for tying together data from advertising campaigns to anlaytics data.

 **NOTE:** Must be called before initializeApiKey: is called to function.
 */
- (void)useAdvertisingIdForDeviceId;

/**
  By default the iOS SDK will track several user properties such as carrier, city, country, ip_address, language, platform, etc. You can use the provided AMPTrackingOptions interface to customize and disable individual fields.

  Note: Each operation on the AMPTrackingOptions object returns the same instance which allows you to chain multiple operations together.

      AMPTrackingOptions *options = [[[[AMPTrackingOptions options] disableCity] disableIPAddress] disablePlatform];
      [[Amplitude instance] setTrackingOptions:options];
 */
- (void)setTrackingOptions:(AMPTrackingOptions *)options;

/**
 Enable COPPA (Children's Online Privacy Protection Act) restrictions on IDFA, IDFV, city, IP address and location tracking.
 This can be used by any customer that does not want to collect IDFA, IDFV, city, IP address and location tracking.
 */
- (void)enableCoppaControl;

/**
 Disable COPPA (Children's Online Privacy Protection Act) restrictions on IDFA, IDFV, city, IP address and location tracking.
 */
- (void)disableCoppaControl;

/**
 Sends events to a different URL other than kAMPEventLogUrl. Used for proxy servers

 We now have a new method setServerZone. To send data to Amplitude's EU servers, recommend to use setServerZone
 method like [client setServerZone:EU]
 */
- (void)setServerUrl:(NSString *)serverUrl;

/**
 Sets Content-Type header for event sending requests
*/
- (void)setContentTypeHeader:(NSString *)contentType;

- (void)setBearerToken:(NSString *)token;

- (void)setPlan:(AMPPlan *)plan;

- (void)setIngestionMetadata:(AMPIngestionMetadata *)ingestionMetadata;

/**
 * Set Amplitude Server Zone, switch to zone related configuration, including dynamic configuration and server url.
 * To send data to Amplitude's EU servers, you need to configure the serverZone to EU like [client setServerZone:EU]
 */
- (void)setServerZone:(AMPServerZone)serverZone;

/**
 * Set Amplitude Server Zone, switch to zone related configuration, including dynamic configuration and server url.
 * If updateServerUrl is true, including server url as well. Recommend to keep updateServerUrl to be true for alignment.
 */
- (void)setServerZone:(AMPServerZone)serverZone updateServerUrl:(BOOL)updateServerUrl;

/**
 * Adds a new middleware function to run on each logEvent() call prior to sending to Amplitude.
 */
- (void)addEventMiddleware:(id<AMPMiddleware> _Nonnull)middleware;

/**
 * The amount of time after an identify is logged that identify events will be batched before being uploaded to the server.
 * The default is 30 seconds.
 */
- (BOOL)setIdentifyUploadPeriodSeconds:(int)uploadPeriodSeconds;

/**
 * Don't.
 */
- (void)disableIdentifyBatching:(BOOL)disable;

/**-----------------------------------------------------------------------------
 * @name Other Methods
 * -----------------------------------------------------------------------------
 */

/**
 Prints the number of events in the queue.

 Debugging method to find out how many events are being stored locally on the device.
 */
- (void)printEventsCount;

/**
 Fetches the deviceId, a unique identifier shared between multiple users using the same app on the same device.

 @returns the deviceId.
 */
- (NSString *)getDeviceId;

/**
 Regenerates a new random deviceId for current user. Note: this is not recommended unless you know what you are doing. This can be used in conjunction with setUserId:nil to anonymize users after they log out. With a nil userId and a completely new deviceId, the current user would appear as a brand new user in dashboard.

 @see [Logging Out Users](https://github.com/amplitude/Amplitude-iOS#logging-out-and-anonymous-users)
 */
- (void)regenerateDeviceId;

/**
 Fetches the current sessionId, an identifier used by Amplitude to group together events tracked during the same session.

 @returns the current session id

 @see [Tracking Sessions](https://help.amplitude.com/hc/en-us/articles/115002323627-Tracking-Session)
 */
- (long long)getSessionId;

/**
 Sets the sessionId.

 **NOTE: not recommended unless you know what you are doing**

 @param timestamp                  Timestamp representing the sessionId

 @see [Tracking Sessions](https://help.amplitude.com/hc/en-us/articles/115002323627-Tracking-Session)
 */
- (void)setSessionId:(long long)timestamp;

/**
 Manually forces the instance to immediately upload all unsent events.

 Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close. Use this method to force the class to immediately upload all queued events.
 */
- (void)uploadEvents;

/**
 Call to check if the SDK is ready to start a new session at timestamp. Returns YES if a new session was started, otherwise NO and current session is extended. Only use if you know what you are doing. Recommended to use current time in UTC milliseconds for timestamp.
 */
- (BOOL)startOrContinueSession:(long long)timestamp;


- (NSString *)getContentTypeHeader;

@end

#pragma mark - constants

extern NSString *const kAMPSessionStartEvent;
extern NSString *const kAMPSessionEndEvent;
extern NSString *const kAMPRevenueEvent;

NS_ASSUME_NONNULL_END
