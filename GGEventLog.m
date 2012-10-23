//
//  GGEventLog.m
//  Fawkes
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 GiraffeGraph. All rights reserved.
//

#import "GGEventLog.h"
#import "GGLocationManagerDelegate.h"
#import "GGCJSONSerializer.h"
#import "GGCJSONDeserializer.h"
#import "GGARCMacros.h"
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *_apiKey;
static NSString *_userId;
static NSString *_deviceId;

static NSString *_versionName;
static NSString *_buildVersionRelease;
static NSString *_phoneModel;
static NSString *_phoneCarrier;
static NSString *_country;
static NSString *_language;

static NSDictionary *_globalProperties;

static NSString *_campaignInformation;
static bool isCurrentlyTrackingCampaign = NO;

static long long _sessionId = -1;
static bool sessionStarted = NO;

static bool updateScheduled = NO;
static bool updatingCurrently = NO;

static NSMutableDictionary *eventsData;

static NSString *eventsDataPath;

static NSOperationQueue *operationQueue;

static CLLocationManager *locationManager;
static bool canTrackLocation;
static CLLocation *lastKnownLocation;
static GGLocationManagerDelegate *locationManagerDelegate;

@implementation GGEventLog

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+ (void)initialize
{
    _deviceId = SAFE_ARC_RETAIN([GGEventLog getDeviceId]);
    
    _versionName = SAFE_ARC_RETAIN([[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"]);
    
    _buildVersionRelease = SAFE_ARC_RETAIN([[UIDevice currentDevice] systemVersion]);
    _phoneModel = SAFE_ARC_RETAIN([[UIDevice currentDevice] model]);
    
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
    
    NSString *eventsDataDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    eventsDataPath = SAFE_ARC_RETAIN([eventsDataDirectory stringByAppendingPathComponent:@"com.girraffegraph.archiveDict"]);
    
    operationQueue = [[NSOperationQueue alloc] init];
    
    @synchronized (eventsData) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:eventsDataPath]) {
            @try {
                eventsData = SAFE_ARC_RETAIN([NSKeyedUnarchiver unarchiveObjectWithFile:eventsDataPath]);
            }
            @catch (NSException *e) {
                NSLog(@"EXCEPTION: Corrupt file %@: %@", [e name], [e reason]);
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:eventsDataPath error:&error];
                if (error != nil) {
                    // Can't remove, unable to do anything about it
                    NSLog(@"ERROR: Can't remove corrupt file:%@", error);
                }
                eventsData = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
                [eventsData setObject:[NSMutableArray array] forKey:@"events"];
                [eventsData setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
                [eventsData setObject:@"{\"tracked\": false}" forKey:@"campaign_information"];
            }
        } else {
            eventsData = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
            [eventsData setObject:[NSMutableArray array] forKey:@"events"];
            [eventsData setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
            [eventsData setObject:@"{\"tracked\": false}" forKey:@"campaign_information"];
        }
        _campaignInformation = SAFE_ARC_RETAIN([eventsData objectForKey:@"campaign_information"]);
    }
    
    Class CLLocationManager = NSClassFromString(@"CLLocationManager");
    
    canTrackLocation = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized
                        && [CLLocationManager significantLocationChangeMonitoringAvailable]);
    
    if (canTrackLocation) {
        locationManager = [[CLLocationManager alloc] init];
        locationManagerDelegate = [[GGLocationManagerDelegate alloc] init];
        SEL setDelegate = NSSelectorFromString(@"setDelegate:");
        [locationManager performSelector:setDelegate withObject:locationManagerDelegate];
        SEL startMonitoringSignificantLocationChanges = NSSelectorFromString(@"startMonitoringSignificantLocationChanges");
        [locationManager performSelector:startMonitoringSignificantLocationChanges];
    }

}

+ (void)initializeApiKey:(NSString*) apiKey
{
    [GGEventLog initializeApiKey:apiKey userId:nil];
}

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId
{
    [GGEventLog initializeApiKey:apiKey userId:userId trackCampaignSource:NO];
}

+ (void)initializeApiKey:(NSString*) apiKey trackCampaignSource:(bool) trackCampaignSource
{
    [GGEventLog initializeApiKey:apiKey userId:nil trackCampaignSource:trackCampaignSource];
}

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId trackCampaignSource:(bool) trackCampaignSource
{
    if (apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil in initializeApiKey:");
        return;
    }
    
    if (![GGEventLog isArgument:apiKey validType:[NSString class] methodName:@"initializeApiKey:"]) {
        return;
    }
    if (userId != nil && ![GGEventLog isArgument:userId validType:[NSString class] methodName:@"initializeApiKey:"]) {
        return;
    }
    
    if ([apiKey length] == 0) {
        NSLog(@"ERROR: apiKey cannot be blank in initializeApiKey:");
        return;
    }
    
    (void) SAFE_ARC_RETAIN(apiKey);
    SAFE_ARC_RELEASE(_apiKey);
    _apiKey = apiKey;
    
    @synchronized (eventsData) {
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
               selector:@selector(uploadEvents)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(uploadEvents)
                   name:UIApplicationWillTerminateNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(uploadEvents)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(startSession)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(endSession)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    
    if (trackCampaignSource) {
        [GGEventLog trackCampaignSource];
    }
    
}

+ (void)enableCampaignTrackingApiKey:(NSString*) apiKey
{
    if (apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil in enableCampaignTrackingApiKey:");
        return;
    }
    
    if (![GGEventLog isArgument:apiKey validType:[NSString class] methodName:@"enableCampaignTrackingApiKey:"]) {
        return;
    }
    
    if ([apiKey length] == 0) {
        NSLog(@"ERROR: apiKey cannot be blank in enableCampaignTrackingApiKey:");
        return;
    }
    
    (void) SAFE_ARC_RETAIN(apiKey);
    SAFE_ARC_RELEASE(_apiKey);
    _apiKey = apiKey;
    
    [GGEventLog trackCampaignSource];
}

+ (void)trackCampaignSource
{
    
    NSNumber *hasTrackedCampaign = [NSNumber numberWithBool:NO];
    @synchronized (eventsData) {
        hasTrackedCampaign = [eventsData objectForKey:@"has_tracked_campaign"];
    }
    
    if (![hasTrackedCampaign boolValue] && !isCurrentlyTrackingCampaign) {
        
        isCurrentlyTrackingCampaign = YES;
        
        NSMutableDictionary *fingerprint = [NSMutableDictionary dictionary];
        [fingerprint setObject:[GGEventLog replaceWithJSONNull:_deviceId] forKey:@"device_id"];
        [fingerprint setObject:@"ios" forKey:@"client"];
        [fingerprint setObject:[GGEventLog replaceWithJSONNull:_country] forKey:@"country"];
        [fingerprint setObject:[GGEventLog replaceWithJSONNull:_language] forKey:@"language"];
        [fingerprint setObject:[GGEventLog replaceWithJSONNull:_phoneModel] forKey:@"phone_model"];
        [fingerprint setObject:[GGEventLog replaceWithJSONNull:_buildVersionRelease] forKey:@"build_version_release"];
        [fingerprint setObject:[GGEventLog replaceWithJSONNull:_phoneCarrier] forKey:@"carrier"];
        
        NSError *error = nil;
        NSData *fingerprintData = [[GGCJSONSerializer serializer] serializeDictionary:fingerprint error:&error];
        if (error != nil) {
            NSLog(@"ERROR: JSONSerializer error: %@", error);
            isCurrentlyTrackingCampaign = NO;
            return;
        }
        NSString *fingerprintString = SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:fingerprintData encoding:NSUTF8StringEncoding]);
        [GGEventLog makeCampaignTrackingPostRequest:@"http://ref.giraffegraph.com/install" fingerprint:fingerprintString];        
    }
}

+ (void)makeCampaignTrackingPostRequest:(NSString*) url fingerprint:(NSString*) fingerprintString
{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:60.0];
    
    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"key=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[_apiKey dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&fingerprint=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[GGEventLog urlEncodeString:fingerprintString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    SAFE_ARC_RELEASE(postData);
    
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
         if (response != nil) {
             if ([httpResponse statusCode] == 200) {
                 NSError *error = nil;
                 NSDictionary *result = [[GGCJSONDeserializer deserializer] deserialize:data error:&error];
                 
                 if (error != nil) {
                     NSLog(@"ERROR: Deserialization error:%@", error);
                 } else if (![result isKindOfClass:[NSDictionary class]]) {
                     NSLog(@"ERROR: JSON Dictionary not returned from server, invalid type:%@", [result class]);
                 } else {
                     
                     // success, save successful campaign tracking
                     NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                     @synchronized (eventsData) {
                         [eventsData setObject:[NSNumber numberWithBool:YES] forKey:@"has_tracked_campaign"];
                         [eventsData setObject:jsonString forKey:@"campaign_information"];
                     }
                     _campaignInformation = jsonString;
                     
                 }
             } else {
                 NSLog(@"ERROR: Connection response received:%d, %@", [httpResponse statusCode],
                       SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]));
             }
         } else if (error != nil) {
             if ([error code] == -1009) {
                 //NSLog(@"No internet connection found, unable to track campaign");
             } else {
                 NSLog(@"ERROR: Connection error:%@", error);
             }
         } else {
             NSLog(@"ERROR: response empty, error empty for NSURLConnection");
         }
         
         isCurrentlyTrackingCampaign = NO;
         
     }];
}

+ (NSDictionary*)getCampaignInformation
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling getCampaignInformation");
        return [NSDictionary dictionary];
    }
    
    NSError *error = nil;
    NSDictionary *result = [[GGCJSONDeserializer deserializer] deserialize:[_campaignInformation dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Deserialization error:%@", error);
    } else if (![result isKindOfClass:[NSDictionary class]]) {
        NSLog(@"ERROR: JSON Dictionary not stored locally, invalid type:%@", [result class]);
        return [NSDictionary dictionary];
    }
    return result;
}

+ (void)logEvent:(NSString*) eventType
{
    if (![GGEventLog isArgument:eventType validType:[NSString class] methodName:@"logEvent"]) {
        return;
    }
    [GGEventLog logEvent:eventType withCustomProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties
{
    if (![GGEventLog isArgument:eventType validType:[NSString class] methodName:@"logEvent:withCustomProperties:"]) {
        return;
    }
    if (customProperties != nil && ![GGEventLog isArgument:customProperties validType:[NSDictionary class] methodName:@"logEvent:withCustomProperties:"]) {
        return;
    }
    [GGEventLog logEvent:eventType withCustomProperties:customProperties apiProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties apiProperties:(NSDictionary*) apiProperties
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling logEvent:");
        return;
    }
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    
    @synchronized (eventsData) {
        long long newId = [[eventsData objectForKey:@"max_id"] longValue] + 1;
        
        [event setValue:[GGEventLog replaceWithJSONNull:eventType] forKey:@"event_type"];
        [event setValue:[NSNumber numberWithLongLong:newId] forKey:@"event_id"];
        [event setValue:[GGEventLog replaceWithEmptyJSON:customProperties] forKey:@"custom_properties"];
        [event setValue:[GGEventLog replaceWithEmptyJSON:apiProperties] forKey:@"properties"];
        [event setValue:[GGEventLog replaceWithEmptyJSON:apiProperties] forKey:@"api_properties"];
        [event setValue:[GGEventLog replaceWithEmptyJSON:_globalProperties] forKey:@"global_properties"];
        
        [GGEventLog addBoilerplate:event];
        
        [[eventsData objectForKey:@"events"] addObject:event];
        
        [eventsData setObject:[NSNumber numberWithLongLong:newId] forKey:@"max_id"];
        
        if ([[eventsData objectForKey:@"events"] count] >= 10) {
            [GGEventLog uploadEvents];
        } else {
            [GGEventLog uploadEventsLater];
        }
    }
}

+ (void)addBoilerplate:(NSMutableDictionary*) event
{
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    [event setValue:timestamp forKey:@"timestamp"];
    [event setValue:(_userId != nil ?
                     [GGEventLog replaceWithJSONNull:_userId] :
                     [GGEventLog replaceWithJSONNull:_deviceId]) forKey:@"user_id"];
    [event setValue:[GGEventLog replaceWithJSONNull:_deviceId] forKey:@"device_id"];
    [event setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"session_id"];
    [event setValue:[GGEventLog replaceWithJSONNull:_versionName] forKey:@"version_name"];
    [event setValue:[GGEventLog replaceWithJSONNull:_buildVersionRelease] forKey:@"build_version_release"];
    [event setValue:[GGEventLog replaceWithJSONNull:_phoneModel] forKey:@"phone_model"];
    [event setValue:[GGEventLog replaceWithJSONNull:_phoneCarrier] forKey:@"phone_carrier"];
    [event setValue:[GGEventLog replaceWithJSONNull:_country] forKey:@"country"];
    [event setValue:[GGEventLog replaceWithJSONNull:_language] forKey:@"language"];
    [event setValue:@"ios" forKey:@"client"];
    
    NSMutableDictionary *properties = [event valueForKey:@"properties"];
    NSMutableDictionary *apiProperties = [event valueForKey:@"api_properties"];
    
    if (lastKnownLocation != nil) {
        NSMutableDictionary *location = [NSMutableDictionary dictionary];
        NSMutableDictionary *apiLocation = [NSMutableDictionary dictionary];
        
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
        
        [properties setValue:location forKey:@"location"];
        
        [apiLocation setValue:[NSNumber numberWithDouble:lastKnownLocationCoordinate.latitude] forKey:@"lat"];
        [apiLocation setValue:[NSNumber numberWithDouble:lastKnownLocationCoordinate.longitude] forKey:@"lng"];
        
        [apiProperties setValue:apiLocation forKey:@"location"];

    }
    
    if (sessionStarted) {
        [GGEventLog refreshSessionTime];
    }
}

+ (void)uploadEvents
{
    if (_apiKey == nil) {
        NSLog(@"ERROR: apiKey cannot be nil or empty, set apiKey with initializeApiKey: before calling uploadEvents:");
        return;
    }
    
    [GGEventLog saveEventsData];
    
    @synchronized ([GGEventLog class]) {
        if (updatingCurrently) {
            return;
        }
        updatingCurrently = YES;
    }
    
    @synchronized (eventsData) {
        NSMutableArray *events = [eventsData objectForKey:@"events"];
        long long numEvents = [events count];
        if (numEvents == 0) {
            updatingCurrently = NO;
            return;
        }
        NSArray *uploadEvents = [events subarrayWithRange:NSMakeRange(0, numEvents)];
        NSError *error = nil;
        NSData *eventsDataLocal = [[GGCJSONSerializer serializer] serializeArray:uploadEvents error:&error];
        if (error != nil) {
            NSLog(@"ERROR: JSONSerializer error: %@", error);
            updatingCurrently = NO;
            return;
        }
        NSString *eventsString = SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:eventsDataLocal encoding:NSUTF8StringEncoding]);
        [GGEventLog makeEventUploadPostRequest:@"http://api.giraffegraph.com/" events:eventsString numEvents:numEvents];
    }
}

+ (void)uploadEventsLater
{
    if (!updateScheduled) {
        updateScheduled = YES;
        [[GGEventLog class] performSelector:@selector(uploadEventsLaterExecute) withObject:[GGEventLog class] afterDelay:10];
    }
}

+ (void)uploadEventsLaterExecute
{
    updateScheduled = NO;
    [GGEventLog uploadEvents];
}

+ (void)makeEventUploadPostRequest:(NSString*) url events:(NSString*) events numEvents:(long long) numEvents
{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:60.0];

    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"e=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[GGEventLog urlEncodeString:events] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&client=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[_apiKey dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&upload_time=" dataUsingEncoding:NSUTF8StringEncoding]];
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    [postData appendData:[[timestamp stringValue] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];

    [request setHTTPBody:postData];

    SAFE_ARC_RELEASE(postData);

    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (response != nil) {
            if ([httpResponse statusCode] == 200) {
                NSError *error = nil;
                NSDictionary *result = [[GGCJSONDeserializer deserializer] deserialize:data error:&error];
                
                if (error != nil) {
                    NSLog(@"ERROR: Deserialization error:%@", error);
                } else if (![result isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"ERROR: JSON Dictionary not returned from server, invalid type:%@", [result class]);
                } else if ([[result objectForKey:@"added"] longLongValue] == numEvents) {
                    // success, remove existing events from dictionary
                    @synchronized (eventsData) {
                        [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, numEvents)];
                    }
                } else {
                    NSLog(@"ERROR: Not all events uploaded");
                }
            } else {
                NSLog(@"ERROR: Connection response received:%d, %@", [httpResponse statusCode],
                    SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]));
            }
        } else if (error != nil) {
            if ([error code] == -1009) {
                //NSLog(@"No internet connection found, unable to upload events");
            } else {
                NSLog(@"ERROR: Connection error:%@", error);
            }
        } else {
            NSLog(@"ERROR: response empty, error empty for NSURLConnection");
        }
        
        [GGEventLog saveEventsData];
        
        updatingCurrently = NO;
    }];
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

+ (void)startSession
{
    
    // Remove turn off session later callback
    [NSObject cancelPreviousPerformRequestsWithTarget:[GGEventLog class]
                                             selector:@selector(turnOffSessionLaterExecute)
                                               object:[GGEventLog class]];
    
    if (!sessionStarted) {
        // Session has not been started yet, check overlap with previous session
        
        @synchronized (eventsData) {
            NSNumber *now = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
            
            NSNumber *previousSessionTime = [eventsData objectForKey:@"previous_session_time"];
            
            if ([now longLongValue] - [previousSessionTime longLongValue] < 10000) {
                _sessionId = [[eventsData objectForKey:@"previous_session_id"] longLongValue];
            } else {
                _sessionId = [now longLongValue];
                [eventsData setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"previous_session_id"];
            }
        }
        
        sessionStarted = YES;
    }
    
    NSMutableDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_start" forKey:@"special"];
    [GGEventLog logEvent:@"session_start" withCustomProperties:nil apiProperties:apiProperties];
}

+ (void)endSession
{
    NSDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_end" forKey:@"special"];
    [GGEventLog logEvent:@"session_end" withCustomProperties:nil apiProperties:apiProperties];
    
    sessionStarted = NO;
    
    [[GGEventLog class] performSelector:@selector(turnOffSessionLaterExecute) withObject:[GGEventLog class] afterDelay:10];
}

+ (void)refreshSessionTime
{
    NSNumber *now = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    @synchronized (eventsData) {
        [eventsData setValue:now forKey:@"previous_session_time"];
    }
}

+ (void)turnOffSessionLaterExecute
{
    if (!sessionStarted) {
        _sessionId = -1;
    }
}

+ (void)setGlobalUserProperties:(NSDictionary*) globalProperties
{
    if (![GGEventLog isArgument:globalProperties validType:[NSDictionary class] methodName:@"setGlobalUserProperties:"]) {
        return;
    }
    (void) SAFE_ARC_RETAIN(globalProperties);
    SAFE_ARC_RELEASE(_globalProperties);
    _globalProperties = globalProperties;
}

+ (void)setUserId:(NSString*) userId
{
    if (![GGEventLog isArgument:userId validType:[NSString class] methodName:@"setUserId:"]) {
        return;
    }
    (void) SAFE_ARC_RETAIN(userId);
    SAFE_ARC_RELEASE(_userId);
    _userId = userId;
    @synchronized (eventsData) {
        [eventsData setObject:_userId forKey:@"user_id"];
    }
}

+ (void)setLocation:(id) location
{
    Class CLLocation = NSClassFromString(@"CLLocation");
    if (![GGEventLog isArgument:location validType:CLLocation methodName:@"setLocation:"]) {
        return;
    }
    if (CLLocation && [location isMemberOfClass:CLLocation]) {
        (void) SAFE_ARC_RETAIN(location);
        SAFE_ARC_RELEASE(lastKnownLocation);
        lastKnownLocation = location;
    }
}

+ (void)startListeningForLocation
{
    SEL startMonitoringSignificantLocationChanges = NSSelectorFromString(@"startMonitoringSignificantLocationChanges");
    [locationManager performSelector:startMonitoringSignificantLocationChanges];
}

+ (void)stopListeningForLocation
{
    SEL stopMonitoringSignificantLocationChanges = NSSelectorFromString(@"stopMonitoringSignificantLocationChanges");
    [locationManager performSelector:stopMonitoringSignificantLocationChanges];
}

+ (void)saveEventsData
{
    @synchronized (eventsData) {
        bool success = [NSKeyedArchiver archiveRootObject:eventsData toFile:eventsDataPath];
        if (!success) {
            NSLog(@"ERROR: Unable to save eventsData to file");
        }
    }
}

+ (NSString*)getDeviceId
{
    // MD5 Hash of the mac address
    return [GGEventLog md5HexDigest:[GGEventLog getMacAddress]];
}

+ (id)replaceWithJSONNull:(id) obj
{
    return obj == nil ? [NSNull null] : obj;
}

+ (NSDictionary*)replaceWithEmptyJSON:(NSDictionary*) dictionary
{
    return dictionary == nil ? [NSMutableDictionary dictionary] : dictionary;
}

+ (bool)isArgument:(id) argument validType:(Class) class methodName:(NSString*) methodName
{
    if ([argument isKindOfClass:class]) {
        return YES;
    } else {
        NSLog(@"ERROR: Invalid type argument to method %@, expected %@, recieved %@, ", methodName, class, [argument class]);
        return NO;
    }
}

+ (NSString*)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    bool                msgBufferAllocated = false;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                msgBufferAllocated = true;
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        if (msgBufferAllocated) {
            free(msgBuffer);
        }
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

+ (NSString*)md5HexDigest:(NSString*)input {
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

@end
