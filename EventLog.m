//
//  EventLog.m
//  Hash Helper
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EventLog.h"
#import "DatabaseHelper.h"
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

static long _sessionId = -1;

static bool updateScheduled = NO;

@implementation EventLog

+ (void)initialize
{
    _deviceId = [EventLog getDeviceId];
    
    _versionName = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    
    _buildVersionRelease = [[[UIDevice currentDevice] systemVersion] retain];
    _phoneModel = [[UIDevice currentDevice] model];
    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    _phoneCarrier = [[info subscriberCellularProvider] carrierName];
    [info release];
    
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
    
    [event setValue:[EventLog replaceWithJSONNull:eventType] forKey:@"event_type"];
    [event setValue:[EventLog replaceWithEmptyJSON:customProperties] forKey:@"custom_properties"];
    [event setValue:[EventLog replaceWithEmptyJSON:apiProperties] forKey:@"api_properties"];
    [event setValue:[EventLog replaceWithEmptyJSON:_globalProperties] forKey:@"global_properties"];
    
    [EventLog addBoilerplate:event];
    
    // TODO: make this run on a separate thread
    [DatabaseHelper addEvent:[event JSONString]];
    
    if ([DatabaseHelper getNumberRows] >= 1) {
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
    NSNumber *timestamp = [NSNumber numberWithLong:0]; //TODO: set this
    [event setValue:timestamp forKey:@"timestamp"];
    [event setValue:[EventLog replaceWithJSONNull:_userId] forKey:@"user_id"];
    [event setValue:[EventLog replaceWithJSONNull:_deviceId] forKey:@"device_id"];
    [event setValue:[NSNumber numberWithLong:_sessionId] forKey:@"session_id"];
    [event setValue:[EventLog replaceWithJSONNull:_versionName] forKey:@"version_name"];
    [event setValue:[EventLog replaceWithJSONNull:_buildVersionRelease] forKey:@"build_version_release"];
    [event setValue:[EventLog replaceWithJSONNull:_phoneModel] forKey:@"phone_model"];
    [event setValue:[EventLog replaceWithJSONNull:_phoneCarrier] forKey:@"phone_carrier"];
    [event setValue:@"iphone" forKey:@"client"];
    
}

+ (void)updateServer
{
    long maxId = 0;
    NSDictionary *pair = [DatabaseHelper getEvents];
    NSArray *events = [pair objectForKey:@"events"];
    maxId = [[pair objectForKey:@"max_id"] longValue];
    bool success = [EventLog makePostRequest:@"http://analytics.snlt.co/event/" events:[events JSONString] numEvents:[events count]];
    
    if (success) {
        [DatabaseHelper removeEvents:maxId];
    } else {
        NSLog(@"ERROR: Upload failed, post request not successful");
    }
}

+ (void)updateServerLater
{
    if(!updateScheduled){
        updateScheduled = YES;
        //TODO:post delayed
    }
}

+ (bool)makePostRequest:(NSString*) url events:(NSString*) events numEvents:(long) numEvents
{
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"e=" dataUsingEncoding:NSUnicodeStringEncoding]];
    [postData appendData:[[EventLog urlEncodeString:events] dataUsingEncoding:NSUnicodeStringEncoding]];
    [postData appendData:[@"&client=" dataUsingEncoding:NSUnicodeStringEncoding]];
    [postData appendData:[_apiKey dataUsingEncoding:NSUnicodeStringEncoding]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
        
    [postData release];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:(&error)];
    
    if (response != nil) {
        if ([response statusCode] == 200) {
            NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            // TODO: handle invalid JSON
            NSDictionary *result = [stringResult objectFromJSONString];
            if ([[result objectForKey:@"added"] longValue] == numEvents) {
                NSLog(@"Upload successful!");
                return YES;
            } else {
                NSLog(@"ERROR: Not all events uploaded");
                return NO;
            }
        } else {
            NSLog(@"ERROR: Connection response received:%d, %@", response.statusCode, data);
            return NO;
        }
    } else if (error != nil) {
        NSLog(@"ERROR: Connection error:%@", error);
        return NO;
    } else {
        NSLog(@"ERROR: response empty, error empty for NSURLConnection");
        return NO;
    }
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
