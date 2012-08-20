//
//  EventLog.m
//  Fawkes
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 GiraffeGraph. All rights reserved.
//

#import "EventLog.h"
#import "LocationManagerDelegate.h"
#import "JSONKit.h"
//#import <CoreTelephony/CTTelephonyNetworkInfo.h>
//#import <CoreTelephony/CTCarrier.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import "CommonCrypto/CommonDigest.h"
#import <CoreLocation/CoreLocation.h>

static NSString *_apiKey;
static NSString *_userId;
static NSString *_deviceId;

static NSString *_versionName;
static NSString *_buildVersionRelease;
static NSString *_phoneModel;
static NSString *_phoneCarrier;

static NSDictionary *_globalProperties;

static long long _sessionId = -1;

static bool updateScheduled = NO;
static bool updatingCurrently = NO;

static NSMutableDictionary *eventsData;

static NSString *eventsDataPath;

static CLLocationManager *locationManager;
static bool canTrackLocation;
static CLLocation *lastKnownLocation;
static LocationManagerDelegate *locationManagerDelegate;

@implementation EventLog

+ (void)initialize
{
    _deviceId = [[EventLog getDeviceId] retain];
    
    _versionName = [[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"] retain];
    
    _buildVersionRelease = [[[UIDevice currentDevice] systemVersion] retain];
    _phoneModel = [[[UIDevice currentDevice] model] retain];
    
    // Requires a linked library
    //CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    //_phoneCarrier = [[[info subscriberCellularProvider] carrierName] retain];
    //[info release];
    
    NSString *eventsDataDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    eventsDataPath = [[eventsDataDirectory stringByAppendingPathComponent:@"com.girraffegraph.archiveDict"] retain];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:eventsDataPath]) {
        eventsData = [[NSKeyedUnarchiver unarchiveObjectWithFile:eventsDataPath] retain];
    } else {
        eventsData = [[NSMutableDictionary dictionary] retain];
        [eventsData setObject:[NSMutableArray array] forKey:@"events"];
        [eventsData setObject:[NSNumber numberWithLongLong:0LL] forKey:@"max_id"];
    }
    
    canTrackLocation = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized
                        && [CLLocationManager significantLocationChangeMonitoringAvailable]);
    
    if (canTrackLocation) {
        locationManager = [[CLLocationManager alloc] init];
        locationManagerDelegate = [[LocationManagerDelegate alloc] init];
        locationManager.delegate = locationManagerDelegate;
        [locationManager startMonitoringSignificantLocationChanges];
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
    
    [apiKey retain];
    [_apiKey release];
    _apiKey = apiKey;
    [userId retain];
    [_userId release];
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
}

+ (void)logEvent:(NSString*) eventType
{
    [EventLog logEvent:eventType withCustomProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSMutableDictionary*) customProperties
{
    [EventLog logEvent:eventType withCustomProperties:customProperties apiProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSMutableDictionary*) customProperties apiProperties: apiProperties
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
        [location setValue:[NSNumber numberWithDouble:lastKnownLocation.coordinate.latitude] forKey:@"lat"];
        [location setValue:[NSNumber numberWithDouble:lastKnownLocation.coordinate.longitude] forKey:@"lng"];
        [apiProperties setValue:location forKey:@"location"];
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
    [EventLog constructAndSendRequest:@"http://api.giraffegraph.com/" events:[uploadEvents JSONString] numEvents:numEvents];
}

+ (void)uploadEventsLater
{
    if(!updateScheduled){
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

    [postData release];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (response != nil) {
            if ([httpResponse statusCode] == 200) {
                NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // TODO: handle invalid JSON
                NSDictionary *result = [stringResult objectFromJSONString];
                [stringResult release];
                if ([[result objectForKey:@"added"] longLongValue] == numEvents) {
                    [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, numEvents)];
                } else {
                    NSLog(@"ERROR: Not all events uploaded");
                }
            } else {
                NSLog(@"ERROR: Connection response received:%d, %@", [httpResponse statusCode],
                    [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
            }
        } else if (error != nil) {
            NSLog(@"ERROR: Connection error:%@", error);
        } else {
            NSLog(@"ERROR: response empty, error empty for NSURLConnection");
        }
        
        [EventLog saveEventsData];
        
        updatingCurrently = NO;
        [queue release];
    }];
}

+ (NSString*)urlEncodeString:(NSString*) string
{
    NSString *newString = [NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                     (CFStringRef)string,
                                                                                     NULL,
                                                                                     CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)))
                           autorelease];
	if (newString) {
		return newString;
	}
	return @"";
}

+ (void)setGlobalProperties:(NSDictionary*) globalProperties
{
    [globalProperties retain];
    [_globalProperties release];
    _globalProperties = globalProperties;
}

+ (void)setUserId:(NSString*) userId
{
    [userId retain];
    [_userId release];
    _userId = userId;
}

+ (void)setLocation:(CLLocation*) location
{
    [location retain];
    [lastKnownLocation release];
    lastKnownLocation = location;
}

+ (void)startListeningForLocation
{
    [locationManager startMonitoringSignificantLocationChanges];
}

+ (void)stopListeningForLocation
{
    [locationManager stopMonitoringSignificantLocationChanges];
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

@end
