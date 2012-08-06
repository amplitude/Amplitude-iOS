//
//  EventLog.m
//  Hash Helper
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EventLog.h"
#import "JSONKit.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

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

static NSMutableDictionary *eventsData;

static NSString *databasePath;

@implementation EventLog

+ (void)initialize
{
    _deviceId = [EventLog getDeviceId];
    
    _versionName = [[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"] retain];
    
    _buildVersionRelease = [[[UIDevice currentDevice] systemVersion] retain];
    _phoneModel = [[[UIDevice currentDevice] model] retain];
    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    _phoneCarrier = [[[info subscriberCellularProvider] carrierName] retain];
    [info release];
    
    NSString *databaseDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    databasePath = [[databaseDirectory stringByAppendingPathComponent:@"com.girraffegraph.archiveDict"] retain];
    
    eventsData = [NSMutableDictionary dictionaryWithContentsOfFile:databasePath];
    if (eventsData == nil) {
        eventsData = [[NSMutableDictionary dictionary] retain];
        [eventsData setObject:[[NSMutableArray array] retain] forKey:@"events"];
        [eventsData setObject:[[NSNumber numberWithLongLong:0LL] retain] forKey:@"max_id"];
    }
}

+ (void)initializeApiKey:(NSString*) apiKey
{
    [EventLog initializeApiKey:apiKey userId:nil];
}

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId
{
    if (apiKey == nil) {
        //TODO: throw exception, no apiKey
    }
    
    [apiKey retain];
    [_apiKey release];
    _apiKey = apiKey;
    [userId retain];
    [_userId release];
    _userId = userId;
    
}

+ (void)logEvent:(NSString*) eventType
{
    [EventLog logEvent:eventType withCustomProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties
{
    [EventLog logEvent:eventType withCustomProperties:customProperties apiProperties:nil];
}

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties apiProperties: apiProperties
{
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    
    [eventsData retain];
    
    long long newId = [[eventsData objectForKey:@"max_id"] longValue] + 1;
    
    [event setValue:[EventLog replaceWithJSONNull:eventType] forKey:@"event_type"];
    [event setValue:[NSNumber numberWithLongLong:newId] forKey:@"event_id"];
    [event setValue:[EventLog replaceWithEmptyJSON:customProperties] forKey:@"custom_properties"];
    [event setValue:[EventLog replaceWithEmptyJSON:apiProperties] forKey:@"properties"];
    [event setValue:[EventLog replaceWithEmptyJSON:_globalProperties] forKey:@"global_properties"];
    
    [EventLog addBoilerplate:event];
    
    [[eventsData objectForKey:@"events"] addObject:event];
    
    [eventsData setObject:[NSNumber numberWithLongLong:newId] forKey:@"max_id"];
    
    if ([[eventsData objectForKey:@"events"] count] >= 3) {
        [EventLog updateServer];
    } else {
        [EventLog updateServerLater];
    }
}

+ (void)uploadEvents
{
    //TODO: post to runnable
}

+ (void)addBoilerplate:(NSMutableDictionary*) event
{
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    [event setValue:timestamp forKey:@"timestamp"];
    [event setValue:[EventLog replaceWithJSONNull:_userId] forKey:@"user_id"];
    [event setValue:[EventLog replaceWithJSONNull:_deviceId] forKey:@"device_id"];
    [event setValue:[NSNumber numberWithLongLong:_sessionId] forKey:@"session_id"];
    [event setValue:[EventLog replaceWithJSONNull:_versionName] forKey:@"version_name"];
    [event setValue:[EventLog replaceWithJSONNull:_buildVersionRelease] forKey:@"build_version_release"];
    [event setValue:[EventLog replaceWithJSONNull:_phoneModel] forKey:@"phone_model"];
    [event setValue:[EventLog replaceWithJSONNull:_phoneCarrier] forKey:@"phone_carrier"];
    [event setValue:@"iphone" forKey:@"client"];
    
}

+ (void)updateServer
{
    NSMutableArray *events = [eventsData objectForKey:@"events"];
    long long numEvents = [events count];
    NSArray *uploadEvents = [events subarrayWithRange:NSMakeRange(0, numEvents)];
    [EventLog constructAndSendRequest:@"http://giraffegraph.com/event/" events:[uploadEvents JSONString] numEvents:numEvents];
    
}

+ (void)updateServerLater
{
    if(!updateScheduled){
        updateScheduled = YES;
        NSLog(@"scheduling updateServerLaterExecute");
        [[EventLog class] performSelector:@selector(updateServerLaterExecute) withObject:nil afterDelay:10];
    }
}

+ (void)updateServerLaterExecute
{
    NSLog(@"updateServerLaterExecute called");
    updateScheduled = NO;
    [EventLog updateServer];
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
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (response != nil) {
            if ([httpResponse statusCode] == 200) {
                NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // TODO: handle invalid JSON
                NSDictionary *result = [stringResult objectFromJSONString];
                [stringResult release];
                if ([[result objectForKey:@"added"] longLongValue] == numEvents) {
                    [[eventsData objectForKey:@"events"] removeObjectsInRange:NSMakeRange(0, numEvents)];
                    [EventLog saveEventsData];
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
    }];
}

+ (void)postRequestCompletetionHandlerResponse:(NSURLResponse*) response data:(NSData *) data error:(NSError *) error
{
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
    [_globalProperties retain];
    [globalProperties release];
    _globalProperties = globalProperties;
}

+ (void)setUserId:(NSString*) userId
{
    [userId retain];
    [_userId release];
    _userId = userId;
}

+ (void)saveEventsData
{
    bool success = [eventsData writeToFile:databasePath atomically:YES];
    if (!success) {
        NSLog(@"ERROR: Unable to save eventsData to file");
    }
}

+ (NSString*)getDeviceId
{
    //TODO: need to implement unique identifier tracking
    return nil;
}

+ (id)replaceWithJSONNull:(id) obj
{
    return obj == nil ? [NSNull null] : obj;
}

+ (NSDictionary*)replaceWithEmptyJSON:(NSDictionary*) dictionary
{
    return dictionary == nil ? [NSDictionary dictionary] : dictionary;
}

@end
