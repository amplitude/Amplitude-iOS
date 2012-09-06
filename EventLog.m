//
//  EventLog.m
//  Fawkes
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 GiraffeGraph. All rights reserved.
//

#import "EventLog.h"
#import "LocationManagerDelegate.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"
#import "ARCMacros.h"
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

static NSDictionary *_globalProperties;

static long long _sessionId = -1;
static bool sessionStarted = NO;

static bool updateScheduled = NO;
static bool updatingCurrently = NO;

static NSMutableDictionary *eventsData;

static NSString *eventsDataPath;

static CLLocationManager *locationManager;
static bool canTrackLocation;
static CLLocation *lastKnownLocation;
static LocationManagerDelegate *locationManagerDelegate;

@implementation EventLog

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+ (void)initialize
{
    _deviceId = SAFE_ARC_RETAIN([EventLog getDeviceId]);
    
    _versionName = SAFE_ARC_RETAIN([[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"]);
    
    _buildVersionRelease = SAFE_ARC_RETAIN([[UIDevice currentDevice] systemVersion]);
    _phoneModel = SAFE_ARC_RETAIN([[UIDevice currentDevice] model]);
    
    // Requires a linked library
    Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
    SEL subscriberCellularProvider = NSSelectorFromString(@"subscriberCellularProvider");
    SEL carrierName = NSSelectorFromString(@"carrierName");
    if (CTTelephonyNetworkInfo && subscriberCellularProvider && carrierName) {
        NSObject *info = [[NSClassFromString(@"CTTelephonyNetworkInfo") alloc] init];
        _phoneCarrier = SAFE_ARC_RETAIN([[info performSelector:subscriberCellularProvider] performSelector:carrierName]);
        SAFE_ARC_RELEASE(info);
    }
    
    NSString *eventsDataDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    eventsDataPath = SAFE_ARC_RETAIN([eventsDataDirectory stringByAppendingPathComponent:@"com.girraffegraph.archiveDict"]);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:eventsDataPath]) {
        eventsData = SAFE_ARC_RETAIN([NSKeyedUnarchiver unarchiveObjectWithFile:eventsDataPath]);
    } else {
        eventsData = SAFE_ARC_RETAIN([NSMutableDictionary dictionary]);
        [eventsData setObject:[NSMutableArray array] forKey:@"events"];
        [eventsData setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
    }
    
    Class CLLocationManager = NSClassFromString(@"CLLocationManager");
    
    canTrackLocation = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized
                        && [CLLocationManager significantLocationChangeMonitoringAvailable]);
    
    if (canTrackLocation) {
        locationManager = [[CLLocationManager alloc] init];
        locationManagerDelegate = [[LocationManagerDelegate alloc] init];
        SEL setDelegate = NSSelectorFromString(@"setDelegate:");
        [locationManager performSelector:setDelegate withObject:locationManagerDelegate];
        SEL startMonitoringSignificantLocationChanges = NSSelectorFromString(@"startMonitoringSignificantLocationChanges");
        [locationManager performSelector:startMonitoringSignificantLocationChanges];
    }

}

+ (void)initializeApiKey:(NSString*) apiKey
{
    [EventLog initializeApiKey:apiKey userId:nil];
}

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId
{
    if (apiKey == nil) {
        [NSException raise:@"apiKey cannot be nil"
                    format:@"Set apiKey to the application key found at giraffegraph.com"];
    }
    
    (void) SAFE_ARC_RETAIN(apiKey);
    SAFE_ARC_RELEASE(_apiKey);
    _apiKey = apiKey;
    (void) SAFE_ARC_RETAIN(userId);
    SAFE_ARC_RELEASE(_userId);
    _userId = userId;
    
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
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(startSession)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(endSession)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
}

+ (void)logEvent:(NSString*) eventType
{
    [EventLog logEvent:eventType withCustomProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties
{
    [EventLog logEvent:eventType withCustomProperties:customProperties apiProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties apiProperties:(NSDictionary*) apiProperties
{
    if (_apiKey == nil) {
        [NSException raise:@"apiKey is nil, apiKey must be set before calling logEvent"
                    format:@"Set apiKey first with initializeApiKey"];
    }
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    
    long long newId = [[eventsData objectForKey:@"max_id"] longValue] + 1;
    
    [event setValue:[EventLog replaceWithJSONNull:eventType] forKey:@"event_type"];
    [event setValue:[NSNumber numberWithLongLong:newId] forKey:@"event_id"];
    [event setValue:[EventLog replaceWithEmptyJSON:customProperties] forKey:@"custom_properties"];
    [event setValue:[EventLog replaceWithEmptyJSON:apiProperties] forKey:@"properties"];
    [event setValue:[EventLog replaceWithEmptyJSON:_globalProperties] forKey:@"global_properties"];
    
    [EventLog addBoilerplate:event];
    
    [[eventsData objectForKey:@"events"] addObject:event];
    
    [eventsData setObject:[NSNumber numberWithLongLong:newId] forKey:@"max_id"];
    
    if ([[eventsData objectForKey:@"events"] count] >= 10) {
        [EventLog uploadEvents];
    } else {
        [EventLog uploadEventsLater];
    }
}

+ (void)addBoilerplate:(NSMutableDictionary*) event
{
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    [event setValue:timestamp forKey:@"timestamp"];
    [event setValue:(_userId != nil ?
                     [EventLog replaceWithJSONNull:_userId] :
                     [EventLog replaceWithJSONNull:_deviceId]) forKey:@"user_id"];
    [event setValue:[EventLog replaceWithJSONNull:_deviceId] forKey:@"device_id"];
    [event setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"session_id"];
    [event setValue:[EventLog replaceWithJSONNull:_versionName] forKey:@"version_name"];
    [event setValue:[EventLog replaceWithJSONNull:_buildVersionRelease] forKey:@"build_version_release"];
    [event setValue:[EventLog replaceWithJSONNull:_phoneModel] forKey:@"phone_model"];
    [event setValue:[EventLog replaceWithJSONNull:_phoneCarrier] forKey:@"phone_carrier"];
    [event setValue:@"iphone" forKey:@"client"];
    
    NSMutableDictionary *apiProperties = [event valueForKey:@"properties"];
    
    if (lastKnownLocation != nil) {
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
    
    if (sessionStarted) {
        [EventLog refreshSessionTime];
    }
}

+ (void)uploadEvents
{
    @synchronized ([EventLog class]) {
        if (updatingCurrently) {
            return;
        }
        updatingCurrently = YES;
    }
    NSMutableArray *events = [eventsData objectForKey:@"events"];
    long long numEvents = [events count];
    if (numEvents == 0) {
        updatingCurrently = NO;
        return;
    }
    NSArray *uploadEvents = [events subarrayWithRange:NSMakeRange(0, numEvents)];
    NSError *error = nil;
    NSData *eventsData = [[CJSONSerializer serializer] serializeArray:uploadEvents error:&error];
    if (error != nil) {
        NSLog(@"ERROR: JSONSerializer error: %@", error);
        updatingCurrently = NO;
        return;
    }
    NSString *eventsString = SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:eventsData encoding:NSUTF8StringEncoding]);
    [EventLog constructAndSendRequest:@"http://api.giraffegraph.com/" events:eventsString numEvents:numEvents];
}

+ (void)uploadEventsLater
{
    if (!updateScheduled) {
        updateScheduled = YES;
        [[EventLog class] performSelector:@selector(uploadEventsLaterExecute) withObject:[EventLog class] afterDelay:10];
    }
}

+ (void)uploadEventsLaterExecute
{
    updateScheduled = NO;
    [EventLog uploadEvents];
}

+ (void)constructAndSendRequest:(NSString*) url events:(NSString*) events numEvents:(long long) numEvents
{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"e=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[EventLog urlEncodeString:events] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&client=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[_apiKey dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];

    [request setHTTPBody:postData];

    SAFE_ARC_RELEASE(postData);

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (response != nil) {
            if ([httpResponse statusCode] == 200) {
                NSError *error = nil;
                NSDictionary *result = [[CJSONDeserializer deserializer] deserialize:data error:&error];
                
                if (error != nil) {
                    NSLog(@"ERROR: Deserialization error:%@", error);
                } else if (![result isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"ERROR: JSON Dictionary not returned from server, invalid type:%@", [result class]);
                } else if ([[result objectForKey:@"added"] longLongValue] == numEvents) {
                    // success, remove existing events from dictionary
                    [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, numEvents)];
                } else {
                    NSLog(@"ERROR: Not all events uploaded");
                }
            } else {
                NSLog(@"ERROR: Connection response received:%d, %@", [httpResponse statusCode],
                    SAFE_ARC_AUTORELEASE([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]));
            }
        } else if (error != nil) {
            NSLog(@"ERROR: Connection error:%@", error);
        } else {
            NSLog(@"ERROR: response empty, error empty for NSURLConnection");
        }
        
        [EventLog saveEventsData];
        
        updatingCurrently = NO;
        SAFE_ARC_RELEASE(queue);
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
    [NSObject cancelPreviousPerformRequestsWithTarget:[EventLog class]
                                             selector:@selector(turnOffSessionLaterExecute)
                                               object:[EventLog class]];
    
    if (!sessionStarted) {
        // Session has not been started yet, check overlap with previous session
        
        NSNumber *now = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
        
        NSNumber *previousSessionTime = [eventsData objectForKey:@"last_session_time"];
        
        if ([now longLongValue] - [previousSessionTime longLongValue] < 10000) {
            _sessionId = [[eventsData objectForKey:@"last_session_id"] longLongValue];
        } else {
            _sessionId = [now longLongValue];
            [eventsData setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"last_session_id"];
        }
        
        sessionStarted = YES;
    }
    
    NSMutableDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_start" forKey:@"special"];
    [EventLog logEvent:@"session_start" withCustomProperties:nil apiProperties:apiProperties];
}

+ (void)endSession
{
    NSDictionary *apiProperties = [NSMutableDictionary dictionary];
    [apiProperties setValue:@"session_end" forKey:@"special"];
    [EventLog logEvent:@"session_end" withCustomProperties:nil apiProperties:apiProperties];
    
    sessionStarted = NO;
    
    [[EventLog class] performSelector:@selector(turnOffSessionLaterExecute) withObject:[EventLog class] afterDelay:10];
}

+ (void)refreshSessionTime
{
    NSNumber *now = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    [eventsData setValue:now forKey:@"last_session_time"];
}

+ (void)turnOffSessionLaterExecute
{
    if (!sessionStarted) {
        _sessionId = -1;
    }
}

+ (void)setGlobalProperties:(NSDictionary*) globalProperties
{
    (void) SAFE_ARC_RETAIN(globalProperties);
    SAFE_ARC_RELEASE(_globalProperties);
    _globalProperties = globalProperties;
}

+ (void)setUserId:(NSString*) userId
{
    (void) SAFE_ARC_RETAIN(userId);
    SAFE_ARC_RELEASE(_userId);
    _userId = userId;
}

+ (void)setLocation:(id) location
{
    Class CLLocation = NSClassFromString(@"CLLocation");
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
    bool success = [NSKeyedArchiver archiveRootObject:eventsData toFile:eventsDataPath];
    if (!success) {
        NSLog(@"ERROR: Unable to save eventsData to file");
    }
}

+ (NSString*)getDeviceId
{
    // MD5 Hash of the mac address
    return [EventLog md5HexDigest:[EventLog getMacAddress]];
}

+ (id)replaceWithJSONNull:(id) obj
{
    return obj == nil ? [NSNull null] : obj;
}

+ (NSDictionary*)replaceWithEmptyJSON:(NSDictionary*) dictionary
{
    return dictionary == nil ? [NSMutableDictionary dictionary] : dictionary;
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
