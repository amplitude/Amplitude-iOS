//
// Amplitude.m

#ifndef AMPLITUDE_DEBUG
#define AMPLITUDE_DEBUG 0
#endif

#if AMPLITUDE_DEBUG
#   define AMPLITUDE_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define AMPLITUDE_LOG(...)
#endif


#import "Amplitude.h"
#import "AMPLocationManagerDelegate.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"
#import "AMPDeviceInfo.h"
#import <math.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@interface Amplitude ()
@property NSOperationQueue *backgroundQueue;
@property BOOL initialized;
@end

@implementation Amplitude

NSString *_userId;
NSString *_deviceId;
AMPDeviceInfo *_deviceInfo;
NSDictionary *_userProperties;

long long _sessionId = -1;
BOOL sessionStarted = NO;
BOOL updateScheduled = NO;
BOOL updatingCurrently = NO;
BOOL _initialized = NO;

BOOL locationListeningEnabled = YES;
BOOL useAdvertisingIdForDeviceId = NO;

NSMutableDictionary *propertyList;
NSString *propertyListPath;
NSMutableDictionary *eventsData;
NSString *eventsDataPath;

NSOperationQueue *mainQueue;
NSOperationQueue *initializerQueue;
NSOperationQueue *_backgroundQueue;
UIBackgroundTaskIdentifier uploadTaskID;

CLLocationManager *locationManager;
CLLocation *lastKnownLocation;
AMPLocationManagerDelegate *locationManagerDelegate;


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma mark - Static methods

+ (id)instance {
    static Amplitude *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (void)initializeApiKey:(NSString*) apiKey {
    [[Amplitude instance] initializeApiKey:apiKey];
}

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId {
    [[Amplitude instance] initializeApiKey:apiKey userId:userId];
}

+ (void)logEvent:(NSString*) eventType {
    [[Amplitude instance] logEvent:eventType];
}

+ (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties {
    [[Amplitude instance] logEvent:eventType withEventProperties:eventProperties];
}

+ (void)logRevenue:(NSNumber*) amount {
    [[Amplitude instance] logRevenue:amount];
}

+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price {
    [[Amplitude instance] logRevenue:productIdentifier quantity:quantity price:price];
}

+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price receipt:(NSData*) receipt {
    [[Amplitude instance] logRevenue:productIdentifier quantity:quantity price:price receipt:receipt];
}

+ (void)uploadEvents {
    [[Amplitude instance] uploadEvents];
}

+ (void)setUserProperties:(NSDictionary*) userProperties {
    [[Amplitude instance] setUserProperties:userProperties];
}

+ (void)setUserId:(NSString*) userId {
    [[Amplitude instance] setUserId:userId];
}

+ (void)enableLocationListening {
    [[Amplitude instance] enableLocationListening];
}

+ (void)disableLocationListening {
    [[Amplitude instance] disableLocationListening];
}

+ (void)useAdvertisingIdForDeviceId {
    [[Amplitude instance] useAdvertisingIdForDeviceId];
}

+ (void)printEventsCount {
    [[Amplitude instance] printEventsCount];
}

+ (NSString*)getDeviceId {
    return [[Amplitude instance] getDeviceId];
}

+ (void)updateLocation
{
    [[Amplitude instance] updateLocation];
}


#pragma mark - Main class methods
- (id)init
{
    if (self = [super init]) {
        initializerQueue = [[NSOperationQueue alloc] init];
        _backgroundQueue = [[NSOperationQueue alloc] init];
        // Force method calls to happen in FIFO order by only allowing 1 concurrent operation
        [_backgroundQueue setMaxConcurrentOperationCount:1];
        // Ensure initialize finishes running asynchronously before other calls are run
        [_backgroundQueue setSuspended:YES];
        
        [initializerQueue addOperationWithBlock:^{
            
            _deviceInfo = [[AMPDeviceInfo alloc] init];

            mainQueue = SAFE_ARC_RETAIN([NSOperationQueue mainQueue]);
            uploadTaskID = UIBackgroundTaskInvalid;
            
            NSString *eventsDataDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
            
            propertyListPath = SAFE_ARC_RETAIN([eventsDataDirectory stringByAppendingPathComponent:@"com.amplitude.plist"]);
            eventsDataPath = SAFE_ARC_RETAIN([eventsDataDirectory stringByAppendingPathComponent:@"com.amplitude.archiveDict"]);


            // Copy any old data files to new file paths
            NSString *oldEventsDataDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
            NSString *oldPropertyListPath = [oldEventsDataDirectory stringByAppendingPathComponent:@"com.amplitude.plist"];
            NSString *oldEventsDataPath = [oldEventsDataDirectory stringByAppendingPathComponent:@"com.amplitude.archiveDict"];
            [self moveFileIfNotExists:oldPropertyListPath to:propertyListPath];
            [self moveFileIfNotExists:oldEventsDataPath to:eventsDataPath];

            // Load propertyList object
            propertyList = SAFE_ARC_RETAIN([self deserializePList:propertyListPath]);
            if (!propertyList) {
                propertyList = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
                [propertyList setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
                BOOL success = [self savePropertyList];
                if (!success) {
                    NSLog(@"ERROR: Unable to save propertyList to file on initialization");
                }
            } else {
                AMPLITUDE_LOG(@"Loaded from %@", propertyListPath);
            }

            // Load eventData object
            eventsData = SAFE_ARC_RETAIN([self unarchive:eventsDataPath]);
            if (!eventsData) {
                // Create new eventsData object
                eventsData = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
                [eventsData setObject:[NSMutableArray array] forKey:@"events"];
                [eventsData setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
                BOOL success = [self saveEventsData];
                if (!success) {
                    NSLog(@"ERROR: Unable to save eventsData to file on initialization");
                }
            } else {
                AMPLITUDE_LOG(@"Loaded from %@", eventsDataPath);
            }
            
            [self initializeDeviceId];
            
            [_backgroundQueue setSuspended:NO];
        }];

        // CLLocationManager must be created on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            Class CLLocationManager = NSClassFromString(@"CLLocationManager");
            locationManager = [[CLLocationManager alloc] init];
            locationManagerDelegate = [[AMPLocationManagerDelegate alloc] init];
            SEL setDelegate = NSSelectorFromString(@"setDelegate:");
            [locationManager performSelector:setDelegate withObject:locationManagerDelegate];
        });

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(enterForeground)
                       name:UIApplicationWillEnterForegroundNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(enterBackground)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
    }
    return self;
};

- (void) dealloc {
    SAFE_ARC_RELEASE(_userId);
    SAFE_ARC_RELEASE(propertyList);
    SAFE_ARC_RELEASE(propertyListPath);
    SAFE_ARC_RELEASE(eventsData);
    SAFE_ARC_RELEASE(eventsDataPath);
    SAFE_ARC_RELEASE(mainQueue);
    SAFE_ARC_RELEASE(lastKnownLocation);
    SAFE_ARC_SUPER_DEALLOC();
}

- (void)initializeApiKey:(NSString*) apiKey
{
    [self initializeApiKey:apiKey userId:nil];
}

- (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId
{
    if (apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil in initializeApiKey:");
        return;
    }
    
    if (![self isArgument:apiKey validType:[NSString class] methodName:@"initializeApiKey:"]) {
        return;
    }
    if (userId != nil && ![self isArgument:userId validType:[NSString class] methodName:@"initializeApiKey:"]) {
        return;
    }
    
    if ([apiKey length] == 0) {
        NSLog(@"ERROR: apiKey cannot be blank in initializeApiKey:");
        return;
    }
    
    (void) SAFE_ARC_RETAIN(apiKey);
    SAFE_ARC_RELEASE(_apiKey);
    _apiKey = apiKey;
    
    [_backgroundQueue addOperationWithBlock:^{
        @synchronized (eventsData) {
            if (userId != nil) {
                [self setUserId:userId];
            } else {
                _userId = SAFE_ARC_RETAIN([eventsData objectForKey:@"user_id"]);
            }
        }
    }];

    if (!_initialized) {
        _initialized = YES;

        [self enterForeground];
    }
}

#pragma mark - logEvent

- (void)logEvent:(NSString*) eventType
{
    if (![self isArgument:eventType validType:[NSString class] methodName:@"logEvent"]) {
        return;
    }
    [self logEvent:eventType withEventProperties:nil];
}

- (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties
{
    if (![self isArgument:eventType validType:[NSString class] methodName:@"logEvent:withEventProperties:"]) {
        return;
    }
    if (eventProperties != nil && ![self isArgument:eventProperties validType:[NSDictionary class] methodName:@"logEvent:withEventProperties:"]) {
        return;
    }
    [self logEvent:eventType withEventProperties:eventProperties apiProperties:nil withTimestamp:nil];
}

- (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties apiProperties:(NSDictionary*) apiProperties withTimestamp:(NSNumber*) timestamp
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling logEvent:");
        return;
    }
    if (timestamp == nil) {
        timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    }
    
    [_backgroundQueue addOperationWithBlock:^{
        
        NSMutableDictionary *event = [NSMutableDictionary dictionary];
        
        @synchronized (eventsData) {
            // Increment propertyList max_id and save immediately
            NSNumber *propertyListMaxId = [NSNumber numberWithLongLong:[[propertyList objectForKey:@"max_id"] longLongValue] + 1];
            [propertyList setObject: propertyListMaxId forKey:@"max_id"];
            [self savePropertyList];
            
            // Increment eventsData max_id
            long long newId = [[eventsData objectForKey:@"max_id"] longLongValue] + 1;
            
            [event setValue:eventType forKey:@"event_type"];
            [event setValue:[NSNumber numberWithLongLong:newId] forKey:@"event_id"];
            [event setValue:[self replaceWithEmptyJSON:eventProperties] forKey:@"event_properties"];
            [event setValue:[self replaceWithEmptyJSON:apiProperties] forKey:@"api_properties"];
            [event setValue:[self replaceWithEmptyJSON:_userProperties] forKey:@"user_properties"];
            
            [self addBoilerplate:event timestamp:timestamp maxIdCheck:propertyListMaxId];
            [self refreshSessionTime:timestamp];
            
            [[eventsData objectForKey:@"events"] addObject:event];
            [eventsData setObject:[NSNumber numberWithLongLong:newId] forKey:@"max_id"];
            
            if ([[eventsData objectForKey:@"events"] count] >= kAMPEventMaxCount) {
                // Delete old events if list starting to become too large to comfortably work with in memory
                [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, kAMPEventRemoveBatchSize)];
                [self saveEventsData];
            } else if ([[eventsData objectForKey:@"events"] count] >= kAMPEventRemoveBatchSize && [[eventsData objectForKey:@"events"] count] % kAMPEventRemoveBatchSize == 0) {
                [self saveEventsData];
            }
            
            if ([[eventsData objectForKey:@"events"] count] >= kAMPEventUploadThreshold) {
                [self uploadEvents];
            } else {
                [self uploadEventsWithDelay:kAMPEventUploadPeriodSeconds];
            }

        }
        
    }];
}

- (void)addBoilerplate:(NSMutableDictionary*) event timestamp:(NSNumber*) timestamp maxIdCheck:(NSNumber*) propertyListMaxId
{
    [event setValue:timestamp forKey:@"timestamp"];
    [event setValue:_userId forKey:@"user_id"];
    [event setValue:_deviceId forKey:@"device_id"];
    [event setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"session_id"];
    [event setValue:kAMPPlatform forKey:@"platform"];
    [event setValue:_deviceInfo.appVersion forKey:@"version_name"];
    [event setValue:_deviceInfo.osName forKey:@"os_name"];
    [event setValue:_deviceInfo.osVersion forKey:@"os_version"];
    [event setValue:_deviceInfo.model forKey:@"device_model"];
    [event setValue:_deviceInfo.manufacturer forKey:@"device_manufacturer"];
    [event setValue:_deviceInfo.carrier forKey:@"carrier"];
    [event setValue:_deviceInfo.country forKey:@"country"];
    [event setValue:_deviceInfo.language forKey:@"language"];
    NSDictionary *library = @{
        @"name": kAMPLibrary,
        @"version": kAMPVersion
    };
    [event setValue:library forKey:@"library"];
    
    NSMutableDictionary *apiProperties = [event valueForKey:@"api_properties"];
    
    [apiProperties setValue:propertyListMaxId forKey:@"max_id"];
    NSString* advertiserID = _deviceInfo.advertiserID;
    if (advertiserID) {
        [apiProperties setValue:advertiserID forKey:@"ios_idfa"];
    }
    NSString* vendorID = _deviceInfo.vendorID;
    if (vendorID) {
        [apiProperties setValue:vendorID forKey:@"ios_idfv"];
    }
    
    if (lastKnownLocation != nil) {
        @synchronized (locationManager) {
            NSMutableDictionary *location = [NSMutableDictionary dictionary];
            
            // Need to use NSInvocation because coordinate selector returns a C struct
            SEL coordinateSelector = NSSelectorFromString(@"coordinate");
            NSMethodSignature *coordinateMethodSignature = [lastKnownLocation methodSignatureForSelector:coordinateSelector];
            NSInvocation *coordinateInvocation = [NSInvocation invocationWithMethodSignature:coordinateMethodSignature];
            [coordinateInvocation setTarget:lastKnownLocation];
            [coordinateInvocation setSelector:coordinateSelector];
            [coordinateInvocation invoke];
            CLLocationCoordinate2D lastKnownLocationCoordinate;
            [coordinateInvocation getReturnValue:&lastKnownLocationCoordinate];
            
            [location setValue:[NSNumber numberWithDouble:lastKnownLocationCoordinate.latitude] forKey:@"lat"];
            [location setValue:[NSNumber numberWithDouble:lastKnownLocationCoordinate.longitude] forKey:@"lng"];
            
            [apiProperties setValue:location forKey:@"location"];
        }
    }
}

#pragma mark - logRevenue

// amount is a double in units of dollars
// ex. $3.99 would be passed as [NSNumber numberWithDouble:3.99]
- (void)logRevenue:(NSNumber*) amount
{
    [self logRevenue:nil quantity:1 price:amount];
}


- (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price
{
    [self logRevenue:productIdentifier quantity:quantity price:price receipt:nil];
}


- (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price receipt:(NSData*) receipt
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling logRevenue:");
        return;
    }
    if (![self isArgument:price validType:[NSNumber class] methodName:@"logRevenue:"]) {
        return;
    }
    NSDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"revenue_amount" forKey:@"special"];
    [apiProperties setValue:productIdentifier forKey:@"productId"];
    [apiProperties setValue:[NSNumber numberWithInteger:quantity] forKey:@"quantity"];
    [apiProperties setValue:price forKey:@"price"];
    [apiProperties setValue:[receipt base64Encoding] forKey:@"receipt"];
    [self logEvent:@"revenue_amount" withEventProperties:nil apiProperties:apiProperties withTimestamp:nil];
}

#pragma mark - Upload events

- (void)uploadEventsWithDelay:(int) delay
{
    if (!updateScheduled) {
        updateScheduled = YES;
        
        [mainQueue addOperationWithBlock:^{
            [self performSelector:@selector(uploadEventsExecute) withObject:nil afterDelay:delay];
        }];
    }
}

- (void)uploadEventsExecute
{
    updateScheduled = NO;
    
    [_backgroundQueue addOperationWithBlock:^{
        [self uploadEvents];
    }];
}

- (void)uploadEvents
{
    [self uploadEventsWithLimit:kAMPEventUploadMaxBatchSize];
}

- (void)uploadEventsWithLimit:(int) limit
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling uploadEvents:");
        return;
    }
    
    @synchronized ([Amplitude class]) {
        if (updatingCurrently) {
            return;
        }
        updatingCurrently = YES;
    }
    
    [_backgroundQueue addOperationWithBlock:^{
        
        @synchronized (eventsData) {
            NSMutableArray *events = [eventsData objectForKey:@"events"];
            long long numEvents = limit ? fminl([events count], limit) : [events count];
            if (numEvents == 0) {
                updatingCurrently = NO;
                return;
            }
            NSArray *uploadEvents = [events subarrayWithRange:NSMakeRange(0, (int) numEvents)];
            long long lastEventIDUploaded = [[[uploadEvents lastObject] objectForKey:@"event_id"] longLongValue];
            NSError *error = nil;
            NSData *eventsDataLocal = nil;
            @try {
                eventsDataLocal = [NSJSONSerialization dataWithJSONObject:[self makeJSONSerializable:uploadEvents] options:0 error:&error];
            }
            @catch (NSException *exception) {
                NSLog(@"ERROR: NSJSONSerialization error: %@", exception.reason);
                updatingCurrently = NO;
                return;
            }
            if (error != nil) {
                NSLog(@"ERROR: NSJSONSerialization error: %@", error);
                updatingCurrently = NO;
                return;
            }
            if (eventsDataLocal) {
                NSString *eventsString = SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:eventsDataLocal encoding:NSUTF8StringEncoding]);
                [self makeEventUploadPostRequest:kAMPEventLogUrl events:eventsString lastEventIDUploaded:lastEventIDUploaded];
           }
        }
        
    }];
}

- (void)makeEventUploadPostRequest:(NSString*) url events:(NSString*) events lastEventIDUploaded:(long long) lastEventIDUploaded
{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:60.0];
    
    NSString *apiVersionString = [[NSNumber numberWithInt:kAMPApiVersion] stringValue];
    
    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"v=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[apiVersionString dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&client=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[_apiKey dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&e=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[self urlEncodeString:events] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Add timestamp of upload
    [postData appendData:[@"&upload_time=" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *timestampString = [[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000] stringValue];
    [postData appendData:[timestampString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Add checksum
    [postData appendData:[@"&checksum=" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *checksumData = [NSString stringWithFormat: @"%@%@%@%@", apiVersionString, _apiKey, events, timestampString];
    NSString *checksum = [self md5HexDigest: checksumData];
    [postData appendData:[checksum dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    AMPLITUDE_LOG(@"Events: %@", events);
    
    SAFE_ARC_RELEASE(postData);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_backgroundQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         BOOL uploadSuccessful = NO;
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
         if (response != nil) {
             if ([httpResponse statusCode] == 200) {
                 NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 if ([result isEqualToString:@"success"]) {
                     // success, remove existing events from dictionary
                     uploadSuccessful = YES;
                     @synchronized (eventsData) {
                         long long numberToRemove = 0;
                         long long i = 0;
                         for (id event in [eventsData objectForKey:@"events"]) {
                             i++;
                             if ([[event objectForKey:@"event_id"] longLongValue] == lastEventIDUploaded) {
                                 numberToRemove = i;
                                 break;
                             }
                         }
                         [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, (int) numberToRemove)];
                     }
                 } else if ([result isEqualToString:@"invalid_api_key"]) {
                     NSLog(@"ERROR: Invalid API Key, make sure your API key is correct in initializeApiKey:");
                 } else if ([result isEqualToString:@"bad_checksum"]) {
                     NSLog(@"ERROR: Bad checksum, post request was mangled in transit, will attempt to reupload later");
                 } else if ([result isEqualToString:@"request_db_write_failed"]) {
                     NSLog(@"ERROR: Couldn't write to request database on server, will attempt to reupload later");
                 } else {
                     NSLog(@"ERROR: %@, will attempt to reupload later", result);
                 }
                 SAFE_ARC_RELEASE(result);
             } else {
                 NSLog(@"ERROR: Connection response received:%ld, %@", (long)[httpResponse statusCode],
                       SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]));
             }
         } else if (error != nil) {
             if ([error code] == -1009) {
                 AMPLITUDE_LOG(@"No internet connection (not connected to internet), unable to upload events");
             } else if ([error code] == -1003) {
                 AMPLITUDE_LOG(@"No internet connection (hostname not found), unable to upload events");
             } else if ([error code] == -1001) {
                 AMPLITUDE_LOG(@"No internet connection (request timed out), unable to upload events");
             } else {
                 NSLog(@"ERROR: Connection error:%@", error);
             }
         } else {
             NSLog(@"ERROR: response empty, error empty for NSURLConnection");
         }
         
         [self saveEventsData];
         
         updatingCurrently = NO;
         
         if (uploadSuccessful && [[eventsData objectForKey:@"events"] count] > kAMPEventUploadThreshold) {
             [self uploadEventsWithLimit:0];
         } else if (uploadTaskID != UIBackgroundTaskInvalid) {
             // Upload finished, allow background task to be ended
             [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
             uploadTaskID = UIBackgroundTaskInvalid;
         }
     }];
}

#pragma mark - application lifecycle methods

- (void)enterForeground
{
    [self updateLocation];
    [self startSession];
    if (uploadTaskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
        uploadTaskID = UIBackgroundTaskInvalid;
    }
    [_backgroundQueue addOperationWithBlock:^{
        [self uploadEvents];
    }];
}

- (void)enterBackground
{
    if (uploadTaskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
    }
    uploadTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //Took too long, manually stop
        if (uploadTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
            uploadTaskID = UIBackgroundTaskInvalid;
        }
    }];
    
    [self endSession];
    [_backgroundQueue addOperationWithBlock:^{
        [self saveEventsData];
        [self uploadEventsWithLimit:0];
    }];
}

#pragma mark - Sessions

- (void)startSession
{
    NSNumber *now = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    
    [mainQueue addOperationWithBlock:^{
        // Remove turn off session later callback
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(turnOffSessionLaterExecute)
                                                   object:self];
    }];
    
    [_backgroundQueue addOperationWithBlock:^{
        
        @synchronized (eventsData) {
            
            // Session has not been started yet, check overlap with previous session
            NSNumber *previousSessionTime = [eventsData objectForKey:@"previous_session_time"];
            long long timeDelta = [now longLongValue] - [previousSessionTime longLongValue];
            
            if (!sessionStarted || _sessionId < 0) {
                if (timeDelta < kAMPMinTimeBetweenSessionsMillis) {
                    _sessionId = [[eventsData objectForKey:@"previous_session_id"] longLongValue];
                } else {
                    _sessionId = [now longLongValue];
                    [eventsData setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"previous_session_id"];
                }
            } else {
                if (timeDelta > kAMPSessionTimeoutMillis) {
                    // Session has expired
                    _sessionId = [now longLongValue];
                    [eventsData setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"previous_session_id"];
                }
                // else _sessionId = previous session id
            }
        }
        
        sessionStarted = YES;
    }];

    NSMutableDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_start" forKey:@"special"];
    [self logEvent:@"session_start" withEventProperties:nil apiProperties:apiProperties withTimestamp:now];
}

- (void)endSession
{
    NSDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_end" forKey:@"special"];
    [self logEvent:@"session_end" withEventProperties:nil apiProperties:apiProperties withTimestamp:nil];
    
    [_backgroundQueue addOperationWithBlock:^{
        sessionStarted = NO;
    }];
    
    [mainQueue addOperationWithBlock:^{
        [self performSelector:@selector(turnOffSessionLaterExecute) withObject:nil afterDelay:kAMPMinTimeBetweenSessionsMillis];
    }];
}

- (void)refreshSessionTime:(NSNumber*) timestamp
{
    @synchronized (eventsData) {
        [eventsData setValue:timestamp forKey:@"previous_session_time"];
    }
}

- (void)turnOffSessionLaterExecute
{
    [_backgroundQueue addOperationWithBlock:^{
        if (!sessionStarted) {
            _sessionId = -1;
        }
    }];
}

#pragma mark - configurations

- (void)setUserProperties:(NSDictionary*) userProperties
{
    if (![self isArgument:userProperties validType:[NSDictionary class] methodName:@"setUserProperties:"]) {
        return;
    }
    (void) SAFE_ARC_RETAIN(userProperties);
    SAFE_ARC_RELEASE(_userProperties);
    _userProperties = userProperties;
}

- (void)setUserId:(NSString*) userId
{
    if (![self isArgument:userId validType:[NSString class] methodName:@"setUserId:"]) {
        return;
    }
    
    [_backgroundQueue addOperationWithBlock:^{
        (void) SAFE_ARC_RETAIN(userId);
        SAFE_ARC_RELEASE(_userId);
        _userId = userId;
        @synchronized (eventsData) {
            [eventsData setObject:_userId forKey:@"user_id"];
            [self saveEventsData];
        }
    }];
}

#pragma mark - location methods

- (void)updateLocation
{
    if (locationListeningEnabled) {
        CLLocation *location = [locationManager location];
        @synchronized (locationManager) {
            if (location != nil) {
                (void) SAFE_ARC_RETAIN(location);
                SAFE_ARC_RELEASE(lastKnownLocation);
                lastKnownLocation = location;
            }
        }
    }
}

- (void)enableLocationListening
{
    locationListeningEnabled = YES;
    [self updateLocation];
}

- (void)disableLocationListening
{
    locationListeningEnabled = NO;
}

- (void)useAdvertisingIdForDeviceId
{
    useAdvertisingIdForDeviceId = YES;
}

#pragma mark - Getters for device data
- (NSString*) getDeviceId
{
    return _deviceId;
}

- (NSString*) initializeDeviceId
{
    @synchronized (eventsData) {
        if (_deviceId == nil) {
            _deviceId = [eventsData objectForKey:@"device_id"];
            if (_deviceId == nil ||
                [_deviceId isEqualToString:@"e3f5536a141811db40efd6400f1d0a4e"] ||
                [_deviceId isEqualToString:@"04bab7ee75b9a58d39b8dc54e8851084"]) {
                _deviceId = [self _getDeviceId];
                [eventsData setObject:_deviceId forKey:@"device_id"];
            }
        }
    }
    return _deviceId;
}

- (NSString*)_getDeviceId
{
    NSString *deviceId = nil;
    if (useAdvertisingIdForDeviceId) {
        deviceId = _deviceInfo.advertiserID;
    }

    // return identifierForVendor
    if (!deviceId) {
        deviceId = _deviceInfo.vendorID;
    }
    
    if (!deviceId) {
        // Otherwise generate random ID
        deviceId = _deviceInfo.generateUUID;
    }
    return deviceId;
}

- (NSDictionary*)replaceWithEmptyJSON:(NSDictionary*) dictionary
{
    return dictionary == nil ? [NSMutableDictionary dictionary] : dictionary;
}

- (id) makeJSONSerializable:(id) obj
{
    if (obj == nil) {
        return [NSNull null];
    }
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        if (!isfinite([obj floatValue])) {
            return [NSNull null];
        } else {
            return obj;
        }
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *arr = [NSMutableArray array];
        for (id i in obj) {
            [arr addObject:[self makeJSONSerializable:i]];
        }
        return [NSArray arrayWithArray:arr];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *coercedKey;
            if (![key isKindOfClass:[NSString class]]) {
                coercedKey = [key description];
                NSLog(@"WARNING: Non-string property key, received %@, coercing to %@", [key class], coercedKey);
            } else {
                coercedKey = key;
            }
            dict[coercedKey] = [self makeJSONSerializable:obj[key]];
        }
        return [NSDictionary dictionaryWithDictionary:dict];
    }
    NSString *str = [obj description];
    NSLog(@"WARNING: Invalid property value type, received %@, coercing to %@", [obj class], str);
    return str;
}


- (BOOL)isArgument:(id) argument validType:(Class) class methodName:(NSString*) methodName
{
    if ([argument isKindOfClass:class]) {
        return YES;
    } else {
        NSLog(@"ERROR: Invalid type argument to method %@, expected %@, received %@, ", methodName, class, [argument class]);
        return NO;
    }
}

- (NSString*)md5HexDigest:(NSString*)input
{
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG) strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

- (NSString*)urlEncodeString:(NSString*) string
{
    NSString *newString;
#if __has_feature(objc_arc)
    newString = (__bridge_transfer NSString*)
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (__bridge CFStringRef)string,
                                            NULL,
                                            CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
#else
    newString = NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                          (CFStringRef)string,
                                                                          NULL,
                                                                          CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                                                          CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    SAFE_ARC_AUTORELEASE(newString);
#endif
    if (newString) {
        return newString;
    }
    return @"";
}

- (void)printEventsCount
{
    NSLog(@"Events count:%ld", (long) [[eventsData objectForKey:@"events"] count]);
}

#pragma mark - Filesystem

- (BOOL)saveEventsData
{
    @synchronized (eventsData) {
        BOOL success = [self archive:eventsData toFile:eventsDataPath];
        if (!success) {
            NSLog(@"ERROR: Unable to save eventsData to file");
        }
        return success;
    }
}

- (BOOL)savePropertyList {
    @synchronized (propertyList) {
        BOOL success = [self serializePList:propertyList toFile:propertyListPath];
        if (!success) {
            NSLog(@"Error: Unable to save propertyList to file");
        }
        return success;
    }
}

- (id)deserializePList:(NSString*)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSData *pListData = [[NSFileManager defaultManager] contentsAtPath:path];
        if (pListData != nil) {
            NSError *error = nil;
            NSMutableDictionary *pList = (NSMutableDictionary *)[NSPropertyListSerialization
                                                                   propertyListWithData:pListData
                                                                   options:NSPropertyListMutableContainersAndLeaves
                                                                   format:NULL error:&error];
            if (error == nil) {
                return pList;
            } else {
                NSLog(@"ERROR: propertyList deserialization error:%@", error);
                error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error != nil) {
                    NSLog(@"ERROR: Can't remove corrupt propertyList file:%@", error);
                }
            }
        }
    }
    return nil;
}

- (BOOL)serializePList:(id)data toFile:(NSString*)path {
    NSError *error = nil;
    NSData *propertyListData = [NSPropertyListSerialization
                                dataWithPropertyList:data
                                format:NSPropertyListXMLFormat_v1_0
                                options:0 error:&error];
    if (error == nil) {
        if (propertyListData != nil) {
            BOOL success = [propertyListData writeToFile:path atomically:YES];
            if (!success) {
                NSLog(@"ERROR: Unable to save propertyList to file");
            }
            return success;
        } else {
            NSLog(@"ERROR: propertyListData is nil");
        }
    } else {
        NSLog(@"ERROR: Unable to serialize propertyList:%@", error);
    }
    return FALSE;
    
}

- (id)unarchive:(NSString*)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        @try {
            id data = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            return data;
        }
        @catch (NSException *e) {
            NSLog(@"EXCEPTION: Corrupt file %@: %@", [e name], [e reason]);
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error != nil) {
                NSLog(@"ERROR: Can't remove corrupt archiveDict file:%@", error);
            }
        }
    }
    return nil;
}

- (BOOL)archive:(id) obj toFile:(NSString*)path {
    return [NSKeyedArchiver archiveRootObject:obj toFile:path];
}

- (void)moveFileIfNotExists:(NSString*)from to:(NSString*)to
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager fileExistsAtPath:to] &&
        [fileManager fileExistsAtPath:from]) {
        if ([fileManager copyItemAtPath:from toPath:to error:&error]) {
            AMPLITUDE_LOG(@"INFO: copied %@ to %@", from, to);
            [fileManager removeItemAtPath:from error:NULL];
        } else {
            AMPLITUDE_LOG(@"WARN: Copy from %@ to %@ failed: %@", from, to, error);
        }
    }
}

#pragma clang diagnostic pop
@end
