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

#define MAX_EVENTS_BEFORE_UPLOAD 30
#define MAX_EVENTS_BEFORE_DELETION 1000
#define SECONDS_BEFORE_UPLOAD 30

#import "Amplitude.h"
#import "AmplitudeLocationManagerDelegate.h"
#import "AmplitudeARCMacros.h"
#import <math.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static int apiVersion = 2;

static NSString *_apiKey;
static NSString *_userId;
static NSString *_deviceId;

static NSString *_versionName;
static NSString *_buildVersionRelease;
static NSString *_platformString;
static NSString *_phoneModel;
static NSString *_phoneCarrier;
static NSString *_country;
static NSString *_language;

static NSDictionary *_userProperties;

static long long _sessionId = -1;
static BOOL sessionStarted = NO;

static BOOL updateScheduled = NO;
static BOOL updatingCurrently = NO;

static NSMutableDictionary *propertyList;
static NSString *propertyListPath;
static NSMutableDictionary *eventsData;
static NSString *eventsDataPath;

static NSOperationQueue *mainQueue;
static NSOperationQueue *initializerQueue;
static NSOperationQueue *backgroundQueue;
static UIBackgroundTaskIdentifier uploadTaskID;

static BOOL locationListeningEnabled = YES;
static CLLocationManager *locationManager;
static CLLocation *lastKnownLocation;
static AmplitudeLocationManagerDelegate *locationManagerDelegate;

static BOOL useAdvertisingIdForDeviceId = NO;

@implementation Amplitude

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma mark - Main class methods
+ (void)initialize
{
    initializerQueue = [[NSOperationQueue alloc] init];
    backgroundQueue = [[NSOperationQueue alloc] init];
    // Force method calls to happen in FIFO order by only allowing 1 concurrent operation
    [backgroundQueue setMaxConcurrentOperationCount:1];
    // Ensure initialize finishes running asynchronously before other calls are run
    [backgroundQueue setSuspended:YES];
    
    [initializerQueue addOperationWithBlock:^{
        
        _versionName = SAFE_ARC_RETAIN([[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"]);
        
        _buildVersionRelease = SAFE_ARC_RETAIN([[UIDevice currentDevice] systemVersion]);
        
        _platformString = SAFE_ARC_RETAIN([self getPlatformString]);
        _phoneModel = SAFE_ARC_RETAIN([self getPhoneModel]);
        
        Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
        SEL subscriberCellularProvider = NSSelectorFromString(@"subscriberCellularProvider");
        SEL carrierName = NSSelectorFromString(@"carrierName");
        if (CTTelephonyNetworkInfo && subscriberCellularProvider && carrierName) {
            NSObject *info = [[NSClassFromString(@"CTTelephonyNetworkInfo") alloc] init];
            _phoneCarrier = SAFE_ARC_RETAIN([[info performSelector:subscriberCellularProvider] performSelector:carrierName]);
            SAFE_ARC_RELEASE(info);
        }
        NSLocale *developerLanguage = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        _country = SAFE_ARC_RETAIN([developerLanguage displayNameForKey:NSLocaleCountryCode value:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]]);
        _language = SAFE_ARC_RETAIN([developerLanguage displayNameForKey:NSLocaleLanguageCode value:[[NSLocale preferredLanguages] objectAtIndex:0]]);
        SAFE_ARC_RELEASE(developerLanguage);
        
        mainQueue = SAFE_ARC_RETAIN([NSOperationQueue mainQueue]);
        uploadTaskID = UIBackgroundTaskInvalid;
        
        NSString *eventsDataDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
        
        // Load propertyList object
        propertyListPath = SAFE_ARC_RETAIN([eventsDataDirectory stringByAppendingPathComponent:@"com.amplitude.plist"]);
        BOOL successfullyLoadedPropertyList = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:propertyListPath]) {
            NSData *propertyListData = [[NSFileManager defaultManager] contentsAtPath:propertyListPath];
            if (propertyListData != nil) {
                NSError *error = nil;
                propertyList = SAFE_ARC_RETAIN((NSMutableDictionary *)[NSPropertyListSerialization
                                                                       propertyListWithData:propertyListData
                                                                       options:NSPropertyListMutableContainersAndLeaves
                                                                       format:NULL error:&error]);
                if (error == nil) {
                    if (propertyList != nil) {
                        successfullyLoadedPropertyList = YES;
                    }
                } else {
                    NSLog(@"ERROR: propertyList deserialization error:%@", error);
                    error = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:eventsDataPath error:&error];
                    if (error != nil) {
                        NSLog(@"ERROR: Can't remove corrupt propertyList file:%@", error);
                    }
                }
            }
        }
        if (!successfullyLoadedPropertyList) {
            propertyList = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
            [propertyList setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
            NSError *error = nil;
            NSData *propertyListData = [NSPropertyListSerialization
                                        dataWithPropertyList:propertyList
                                        format:NSPropertyListXMLFormat_v1_0
                                        options:0 error:&error];
            if (error == nil) {
                if (propertyListData != nil) {
                    BOOL success = [propertyListData writeToFile:propertyListPath atomically:YES];
                    if (!success) {
                        NSLog(@"ERROR: Unable to save propertyList to file on initialization");
                    }
                } else {
                    NSLog(@"ERROR: propertyListData is nil on initialization");
                }
            } else {
                NSLog(@"ERROR: Unable to serialize propertyList on initialization:%@", error);
            }
        }
        
        // Load eventData object
        eventsDataPath = SAFE_ARC_RETAIN([eventsDataDirectory stringByAppendingPathComponent:@"com.amplitude.archiveDict"]);
        BOOL successfullyLoadedEventsData = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:eventsDataPath]) {
            @try {
                eventsData = SAFE_ARC_RETAIN([NSKeyedUnarchiver unarchiveObjectWithFile:eventsDataPath]);
                if (eventsData != nil) {
                    successfullyLoadedEventsData = YES;
                }
            }
            @catch (NSException *e) {
                NSLog(@"EXCEPTION: Corrupt file %@: %@", [e name], [e reason]);
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:eventsDataPath error:&error];
                if (error != nil) {
                    NSLog(@"ERROR: Can't remove corrupt archiveDict file:%@", error);
                }
            }
        }
        if (!successfullyLoadedEventsData) {
            eventsData = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
            [eventsData setObject:[NSMutableArray array] forKey:@"events"];
            [eventsData setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
            BOOL success = [NSKeyedArchiver archiveRootObject:eventsData toFile:eventsDataPath];
            if (!success) {
                NSLog(@"ERROR: Unable to save eventsData to file on initialization");
            }
        }
        
        [backgroundQueue setSuspended:NO];
    }];
    
    // CLLocationManager must be created on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        Class CLLocationManager = NSClassFromString(@"CLLocationManager");
        locationManager = [[CLLocationManager alloc] init];
        locationManagerDelegate = [[AmplitudeLocationManagerDelegate alloc] init];
        SEL setDelegate = NSSelectorFromString(@"setDelegate:");
        [locationManager performSelector:setDelegate withObject:locationManagerDelegate];
    });
}

+ (void)initializeApiKey:(NSString*) apiKey
{
    [Amplitude initializeApiKey:apiKey userId:nil];
}

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId
{
    if (apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil in initializeApiKey:");
        return;
    }
    
    if (![Amplitude isArgument:apiKey validType:[NSString class] methodName:@"initializeApiKey:"]) {
        return;
    }
    if (userId != nil && ![Amplitude isArgument:userId validType:[NSString class] methodName:@"initializeApiKey:"]) {
        return;
    }
    
    if ([apiKey length] == 0) {
        NSLog(@"ERROR: apiKey cannot be blank in initializeApiKey:");
        return;
    }
    
    (void) SAFE_ARC_RETAIN(apiKey);
    SAFE_ARC_RELEASE(_apiKey);
    _apiKey = apiKey;
    
    [backgroundQueue addOperationWithBlock:^{

        @synchronized (eventsData) {
            _deviceId = [Amplitude getDeviceId];
            if (userId != nil) {
                (void) SAFE_ARC_RETAIN(userId);
                SAFE_ARC_RELEASE(_userId);
                _userId = userId;
                [eventsData setObject:_userId forKey:@"user_id"];
            } else {
                _userId = SAFE_ARC_RETAIN([eventsData objectForKey:@"user_id"]);
            }
        }
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        [center addObserver:self
                   selector:@selector(enterForeground)
                       name:UIApplicationWillEnterForegroundNotification
                     object:nil];
        
        [center addObserver:self
                   selector:@selector(enterBackground)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        
    }];
    
    [Amplitude enterForeground];
}

+ (void)logEvent:(NSString*) eventType
{
    if (![Amplitude isArgument:eventType validType:[NSString class] methodName:@"logEvent"]) {
        return;
    }
    [Amplitude logEvent:eventType withEventProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties
{
    if (![Amplitude isArgument:eventType validType:[NSString class] methodName:@"logEvent:withEventProperties:"]) {
        return;
    }
    if (eventProperties != nil && ![Amplitude isArgument:eventProperties validType:[NSDictionary class] methodName:@"logEvent:withEventProperties:"]) {
        return;
    }
    [Amplitude logEvent:eventType withEventProperties:eventProperties apiProperties:nil withTimestamp:nil];
}

+ (void)logEvent:(NSString*) eventType withEventProperties:(NSDictionary*) eventProperties apiProperties:(NSDictionary*) apiProperties withTimestamp:(NSNumber*) timestamp
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling logEvent:");
        return;
    }
    if (timestamp == nil) {
        timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    }
    
    [backgroundQueue addOperationWithBlock:^{
        
        NSMutableDictionary *event = [NSMutableDictionary dictionary];
        
        @synchronized (eventsData) {
            // Increment propertyList max_id and save immediately
            NSNumber *propertyListMaxId = [NSNumber numberWithLongLong:[[propertyList objectForKey:@"max_id"] longLongValue] + 1];
            [propertyList setObject: propertyListMaxId forKey:@"max_id"];
            [Amplitude savePropertyList];
            
            // Increment eventsData max_id
            long long newId = [[eventsData objectForKey:@"max_id"] longLongValue] + 1;
            
            [event setValue:[Amplitude replaceWithJSONNull:eventType] forKey:@"event_type"];
            [event setValue:[NSNumber numberWithLongLong:newId] forKey:@"event_id"];
            [event setValue:[Amplitude replaceWithEmptyJSON:eventProperties] forKey:@"custom_properties"];
            [event setValue:[Amplitude replaceWithEmptyJSON:apiProperties] forKey:@"api_properties"];
            [event setValue:[Amplitude replaceWithEmptyJSON:_userProperties] forKey:@"global_properties"];
            
            [Amplitude addBoilerplate:event timestamp:timestamp maxIdCheck:propertyListMaxId];
            
            [[eventsData objectForKey:@"events"] addObject:event];
            
            [eventsData setObject:[NSNumber numberWithLongLong:newId] forKey:@"max_id"];
            
            if ([[eventsData objectForKey:@"events"] count] >= MAX_EVENTS_BEFORE_DELETION) {
                // Delete old events if list starting to become too large to comfortably work with in memory
                [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, 20)];
                [Amplitude saveEventsData];
            } else if ([[eventsData objectForKey:@"events"] count] >= 20 && [[eventsData objectForKey:@"events"] count] % 20 == 0) {
                [Amplitude saveEventsData];
            }
            
            if ([[eventsData objectForKey:@"events"] count] >= MAX_EVENTS_BEFORE_UPLOAD) {
                [Amplitude uploadEvents];
            } else {
                [Amplitude uploadEventsLater];
            }

        }
        
    }];
}

+ (void)addBoilerplate:(NSMutableDictionary*) event timestamp:(NSNumber*) timestamp maxIdCheck:(NSNumber*) propertyListMaxId
{
    [event setValue:timestamp forKey:@"timestamp"];
    [event setValue:(_userId != nil ?
                     [Amplitude replaceWithJSONNull:_userId] :
                     [Amplitude replaceWithJSONNull:_deviceId]) forKey:@"user_id"];
    [event setValue:[Amplitude replaceWithJSONNull:_deviceId] forKey:@"device_id"];
    [event setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"session_id"];
    [event setValue:[Amplitude replaceWithJSONNull:_versionName] forKey:@"version_name"];
    [event setValue:[Amplitude replaceWithJSONNull:_buildVersionRelease] forKey:@"build_version_release"];
    [event setValue:[Amplitude replaceWithJSONNull:_platformString] forKey:@"platform_string"];
    [event setValue:[Amplitude replaceWithJSONNull:_phoneModel] forKey:@"phone_model"];
    [event setValue:[Amplitude replaceWithJSONNull:_phoneCarrier] forKey:@"phone_carrier"];
    [event setValue:[Amplitude replaceWithJSONNull:_country] forKey:@"country"];
    [event setValue:[Amplitude replaceWithJSONNull:_language] forKey:@"language"];
    [event setValue:@"ios" forKey:@"client"];
    
    NSMutableDictionary *apiProperties = [event valueForKey:@"api_properties"];
    
    [apiProperties setValue:[Amplitude replaceWithJSONNull:propertyListMaxId] forKey:@"max_id"];
    
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
            
            [location setValue:[Amplitude replaceWithJSONNull:[NSNumber numberWithDouble:lastKnownLocationCoordinate.latitude]] forKey:@"lat"];
            [location setValue:[Amplitude replaceWithJSONNull:[NSNumber numberWithDouble:lastKnownLocationCoordinate.longitude]] forKey:@"lng"];
            
            [apiProperties setValue:location forKey:@"location"];
        }
    }
    
    if (sessionStarted) {
        [Amplitude refreshSessionTime:timestamp];
    }
}

+ (void)uploadEventsLater
{
    if (!updateScheduled) {
        updateScheduled = YES;
        
        [mainQueue addOperationWithBlock:^{
            [[Amplitude class] performSelector:@selector(uploadEventsLaterExecute) withObject:[Amplitude class] afterDelay:SECONDS_BEFORE_UPLOAD];
        }];
    }
}

+ (void)uploadEventsLaterExecute
{
    updateScheduled = NO;
    
    [backgroundQueue addOperationWithBlock:^{
        [Amplitude uploadEvents];
    }];
}

+ (void)uploadEvents
{
    [Amplitude uploadEventsLimit:YES];
}

+ (void)uploadEventsLimit:(BOOL) limit
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
    
    [backgroundQueue addOperationWithBlock:^{
        
        @synchronized (eventsData) {
            NSMutableArray *events = [eventsData objectForKey:@"events"];
            long long numEvents = limit ? fminl([events count], 100) : [events count];
            if (numEvents == 0) {
                updatingCurrently = NO;
                return;
            }
            NSArray *uploadEvents = [events subarrayWithRange:NSMakeRange(0, (int) numEvents)];
            long long lastEventIDUploaded = [[[uploadEvents lastObject] objectForKey:@"event_id"] longLongValue];
            NSError *error = nil;
            NSData *eventsDataLocal = nil;
            @try {
                eventsDataLocal = [NSJSONSerialization dataWithJSONObject:[Amplitude makeJSONSerializable:uploadEvents] options:0 error:&error];
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
                [Amplitude makeEventUploadPostRequest:@"https://api.amplitude.com/" events:eventsString lastEventIDUploaded:lastEventIDUploaded];
            }
        }
        
    }];
}

+ (void)makeEventUploadPostRequest:(NSString*) url events:(NSString*) events lastEventIDUploaded:(long long) lastEventIDUploaded
{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:60.0];
    
    NSString *apiVersionString = [[NSNumber numberWithInt:apiVersion] stringValue];
    
    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"v=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[apiVersionString dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&client=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[_apiKey dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&e=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[Amplitude urlEncodeString:events] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Add timestamp of upload
    [postData appendData:[@"&upload_time=" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *timestampString = [[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000] stringValue];
    [postData appendData:[timestampString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Add checksum
    [postData appendData:[@"&checksum=" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *checksumData = [NSString stringWithFormat: @"%@%@%@%@", apiVersionString, _apiKey, events, timestampString];
    NSString *checksum = [Amplitude md5HexDigest: checksumData];
    [postData appendData:[checksum dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    SAFE_ARC_RELEASE(postData);
    
    [NSURLConnection sendAsynchronousRequest:request queue:backgroundQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
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
                         [Amplitude saveEventsData];
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
                 NSLog(@"ERROR: Connection response received:%d, %@", [httpResponse statusCode],
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
         
         updatingCurrently = NO;
         
         if (uploadSuccessful && [[eventsData objectForKey:@"events"] count] > MAX_EVENTS_BEFORE_UPLOAD) {
             [Amplitude uploadEventsLimit:NO];
         } else if (uploadTaskID != UIBackgroundTaskInvalid) {
             // Upload finished, allow background task to be ended
             [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
             uploadTaskID = UIBackgroundTaskInvalid;
         }
     }];
}

+ (void)printEventsCount
{
    NSLog(@"Events count:%ld", (long) [[eventsData objectForKey:@"events"] count]);
}

+ (void)saveEventsData
{
    @synchronized (eventsData) {
        BOOL success = [NSKeyedArchiver archiveRootObject:eventsData toFile:eventsDataPath];
        if (!success) {
            NSLog(@"ERROR: Unable to save eventsData to file");
        }
    }
}

// amount is a double in units of dollars
// ex. $3.99 would be passed as [NSNumber numberWithDouble:3.99]
+ (void)logRevenue:(NSNumber*) amount
{
    [Amplitude logRevenue:nil quantity:1 price:amount];
}


+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price
{
    [Amplitude logRevenue:productIdentifier quantity:quantity price:price receipt:nil];
}


+ (void)logRevenue:(NSString*) productIdentifier quantity:(NSInteger) quantity price:(NSNumber*) price receipt:(NSData*) receipt
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling logRevenue:");
        return;
    }
    if (![Amplitude isArgument:price validType:[NSNumber class] methodName:@"logRevenue:"]) {
        return;
    }
    NSDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"revenue_amount" forKey:@"special"];
    [apiProperties setValue:[Amplitude replaceWithJSONNull:productIdentifier] forKey:@"productId"];
    [apiProperties setValue:[NSNumber numberWithInteger:quantity] forKey:@"quantity"];
    [apiProperties setValue:price forKey:@"price"];
    [apiProperties setValue:[Amplitude replaceWithJSONNull: [receipt base64Encoding]] forKey:@"receipt"];
    [Amplitude logEvent:@"revenue_amount" withEventProperties:nil apiProperties:apiProperties withTimestamp:nil];
}



+ (NSString*)urlEncodeString:(NSString*) string
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

#pragma mark - application lifecycle methods

+ (void)enterForeground
{
    [Amplitude updateLocation];
    [Amplitude startSession];
    if (uploadTaskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
        uploadTaskID = UIBackgroundTaskInvalid;
    }
    [backgroundQueue addOperationWithBlock:^{
        [Amplitude uploadEvents];
    }];
}

+ (void)enterBackground
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
    
    [Amplitude endSession];
    [backgroundQueue addOperationWithBlock:^{
        [Amplitude saveEventsData];
        [Amplitude uploadEventsLimit:NO];
    }];
}

+ (void)startSession
{
    NSNumber *now = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    
    [mainQueue addOperationWithBlock:^{
        // Remove turn off session later callback
        [NSObject cancelPreviousPerformRequestsWithTarget:[Amplitude class]
                                                 selector:@selector(turnOffSessionLaterExecute)
                                                   object:[Amplitude class]];
    }];
    
    if (!sessionStarted) {
        [backgroundQueue addOperationWithBlock:^{
            
            @synchronized (eventsData) {
                
                // Session has not been started yet, check overlap with previous session
                NSNumber *previousSessionTime = [eventsData objectForKey:@"previous_session_time"];
                
                if ([now longLongValue] - [previousSessionTime longLongValue] < 10000) {
                    _sessionId = [[eventsData objectForKey:@"previous_session_id"] longLongValue];
                } else {
                    _sessionId = [now longLongValue];
                    [eventsData setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"previous_session_id"];
                }
            }
            
            sessionStarted = YES;
        }];
    }
    
    NSMutableDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_start" forKey:@"special"];
    [Amplitude logEvent:@"session_start" withEventProperties:nil apiProperties:apiProperties withTimestamp:now];
}

+ (void)endSession
{
    NSDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_end" forKey:@"special"];
    [Amplitude logEvent:@"session_end" withEventProperties:nil apiProperties:apiProperties withTimestamp:nil];
    
    [backgroundQueue addOperationWithBlock:^{
        sessionStarted = NO;
    }];
    
    [mainQueue addOperationWithBlock:^{
        [[Amplitude class] performSelector:@selector(turnOffSessionLaterExecute) withObject:[Amplitude class] afterDelay:10];
    }];
}

+ (void)refreshSessionTime:(NSNumber*) timestamp
{
    @synchronized (eventsData) {
        [eventsData setValue:timestamp forKey:@"previous_session_time"];
    }
}

+ (void)turnOffSessionLaterExecute
{
    if (!sessionStarted) {
        _sessionId = -1;
    }
}

#pragma mark - configurations

+ (void)setUserProperties:(NSDictionary*) userProperties
{
    if (![Amplitude isArgument:userProperties validType:[NSDictionary class] methodName:@"setUserProperties:"]) {
        return;
    }
    (void) SAFE_ARC_RETAIN(userProperties);
    SAFE_ARC_RELEASE(_userProperties);
    _userProperties = userProperties;
}

+ (void)setUserId:(NSString*) userId
{
    if (![Amplitude isArgument:userId validType:[NSString class] methodName:@"setUserId:"]) {
        return;
    }
    
    [backgroundQueue addOperationWithBlock:^{
        (void) SAFE_ARC_RETAIN(userId);
        SAFE_ARC_RELEASE(_userId);
        _userId = userId;
        @synchronized (eventsData) {
            [eventsData setObject:_userId forKey:@"user_id"];
        }
    }];
}

+ (void)savePropertyList
{
    @synchronized (propertyList) {
        NSError *error = nil;
        NSData *propertyListData = [NSPropertyListSerialization
                                    dataWithPropertyList:propertyList
                                    format:NSPropertyListXMLFormat_v1_0
                                    options:0 error:&error];
        if (error == nil) {
            if (propertyListData != nil) {
                BOOL success = [propertyListData writeToFile:propertyListPath atomically:YES];
                if (!success) {
                    NSLog(@"ERROR: Unable to save propertyList to file");
                }
            } else {
                NSLog(@"ERROR: propertyListData is nil");
            }
        } else {
            NSLog(@"ERROR: Unable to serialize propertyList:%@", error);
        }
    }
}

#pragma mark - location methods

+ (void)updateLocation
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

+ (void)enableLocationListening
{
    locationListeningEnabled = YES;
    [Amplitude updateLocation];
}

+ (void)disableLocationListening
{
    locationListeningEnabled = NO;
}

+ (void)useAdvertisingIdForDeviceId
{
    useAdvertisingIdForDeviceId = YES;
}

#pragma mark - Getters for device data
+ (NSString*)getDeviceId
{
    @synchronized (eventsData) {
        if (_deviceId == nil) {
            _deviceId = SAFE_ARC_RETAIN([eventsData objectForKey:@"device_id"]);
            if (_deviceId == nil ||
                [_deviceId isEqualToString:@"e3f5536a141811db40efd6400f1d0a4e"] ||
                [_deviceId isEqualToString:@"04bab7ee75b9a58d39b8dc54e8851084"]) {
                _deviceId = SAFE_ARC_RETAIN([Amplitude _getDeviceId]);
                [eventsData setObject:_deviceId forKey:@"device_id"];
            }
        }
    }
    return _deviceId;
}

+ (NSString*)_getDeviceId
{
    if (useAdvertisingIdForDeviceId) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= (float) 6.0) {
            NSString *advertiserId = [Amplitude getAdvertiserID:0];
            if (advertiserId != nil && ![advertiserId isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                return advertiserId;
            }
        }
    }

    // On iOS 6+, return identifierForVendor
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= (float) 6.0) {
        NSString *identifierForVendor = [Amplitude getVendorID:0];
        if (identifierForVendor != nil && ![identifierForVendor isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            return identifierForVendor;
        }
    }
    
    // Otherwise generate random ID
    NSString *randomId = [Amplitude generateRandomId];
    return randomId;
}

+ (NSString*)getAdvertiserID:(int) timesCalled
{
    Class ASIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    SEL sharedManager = NSSelectorFromString(@"sharedManager");
    SEL advertisingIdentifier = NSSelectorFromString(@"advertisingIdentifier");
    SEL UUIDString = NSSelectorFromString(@"UUIDString");
    if (ASIdentifierManager && sharedManager && advertisingIdentifier && UUIDString) {
        NSString *identifier = [[[ASIdentifierManager performSelector: sharedManager] performSelector: advertisingIdentifier] performSelector: UUIDString];
        if (identifier == nil && timesCalled < 5) {
            // Try again every 5 seconds
            [NSThread sleepForTimeInterval:5.0];
            return [Amplitude getAdvertiserID:timesCalled + 1];
        } else {
            return identifier;
        }
    } else {
        return nil;
    }
}

+ (NSString*)getVendorID:(int) timesCalled
{
    NSString *identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (identifier == nil && timesCalled < 5) {
        // Try again every 5 seconds
        [NSThread sleepForTimeInterval:5.0];
        return [Amplitude getVendorID:timesCalled + 1];
    } else {
        return identifier;
    }
}

+ (NSString*)generateRandomId
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
#if __has_feature(objc_arc)
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
#else
    NSString *uuidStr = (NSString *) CFUUIDCreateString(kCFAllocatorDefault, uuid);
#endif
    CFRelease(uuid);
    // Add "R" at the end of the ID to distinguish it from advertiserId
    return [uuidStr stringByAppendingString:@"R"];
}

+ (id)replaceWithJSONNull:(id) obj
{
    return obj == nil ? [NSNull null] : obj;
}

+ (NSDictionary*)replaceWithEmptyJSON:(NSDictionary*) dictionary
{
    return dictionary == nil ? [NSMutableDictionary dictionary] : dictionary;
}

+ (id) makeJSONSerializable:(id) obj
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
            [arr addObject:[Amplitude makeJSONSerializable:i]];
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
            dict[coercedKey] = [Amplitude makeJSONSerializable:obj[key]];
        }
        return [NSDictionary dictionaryWithDictionary:dict];
    }
    NSString *str = [obj description];
    NSLog(@"WARNING: Invalid property value type, received %@, coercing to %@", [obj class], str);
    return str;
}


+ (BOOL)isArgument:(id) argument validType:(Class) class methodName:(NSString*) methodName
{
    if ([argument isKindOfClass:class]) {
        return YES;
    } else {
        NSLog(@"ERROR: Invalid type argument to method %@, expected %@, received %@, ", methodName, class, [argument class]);
        return NO;
    }
}

// Taken from http://stackoverflow.com/a/3950748/340520
+ (NSString *)getPlatformString
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSString *)getPhoneModel{
    NSString *platform = [self getPlatformString];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad 1";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}

+ (NSString*)md5HexDigest:(NSString*)input
{
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

#pragma clang diagnostic pop

#pragma mark - Getters for testing

+(void)flushQueue {
    [eventsData setObject:[NSMutableArray array] forKey:@"events"];
}
+(int)apiVersion {
    return apiVersion;
}
+(NSString*)apiKey {
    return _apiKey;
}
+(NSString*)userId {
    return _userId;
}
+(NSString*)deviceId{
    return _deviceId;
}
+(NSString*)versionName {
    return _versionName;
}
+(NSString*)buildVersionRelease {
    return _buildVersionRelease;
}
+(NSString*)platformString {
    return _platformString;
}
+(NSString*)phoneModel {
    return _phoneModel;
}
+(NSString*)phoneCarrier {
    return _phoneCarrier;
}
+(NSString*)country {
    return _country;
}
+(NSString*)language {
    return _language;
}
+(NSDictionary*)userProperties {
    return _userProperties;
}

+(long long)sessionId {
    return _sessionId;
}
+(BOOL)sessionStarted {
    return sessionStarted;
}
+(BOOL)updateScheduled {
    return updateScheduled;
}
+(BOOL)updatingCurrently {
    return updatingCurrently;
}
+(NSMutableDictionary*)propertyList {
    return propertyList;
}
+(NSString*)propertyListPath {
    return propertyListPath;
}
+(NSMutableDictionary*)eventsData {
    return eventsData;
}
+(NSString*)eventsDataPath {
    return eventsDataPath;
}
+(NSOperationQueue*)mainQueue {
    return mainQueue;
}
+(NSOperationQueue*)initializerQueue {
    return initializerQueue;
}
+(NSOperationQueue*)backgroundQueue {
    return backgroundQueue;
}
+(UIBackgroundTaskIdentifier)uploadTaskID {
    return uploadTaskID;
}
+(BOOL)locationListeningEnabled {
    return locationListeningEnabled;
}
+(CLLocationManager*)locationManager {
    return locationManager;
}
+(CLLocation*)lastKnownLocation {
    return lastKnownLocation;
}
+(AmplitudeLocationManagerDelegate*)locationManagerDelegate {
    return locationManagerDelegate;
}
@end
