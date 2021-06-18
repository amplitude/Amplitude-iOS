//
//  File.m
//
//
//  Created by Dante Tam on 6/10/21.
//

#import <Foundation/Foundation.h>
#import <Amplitude.h>
#import "AMPStorage.h"

@implementation AMPStorage

+ (NSString *)getAppStorageAmpDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [paths firstObject];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@/%@/%@", path, @"/", bundleIdentifier];
}

+ (NSString *)getDefaultEventsFile {
    NSString *baseDir = [AMPStorage getAppStorageAmpDir];
    NSString *path = [baseDir stringByAppendingString:@"/amplitude_event_storage.txt"];
    return path;
}

+ (NSString *)getDefaultIdentifyFile {
    NSString *baseDir = [AMPStorage getAppStorageAmpDir];
    NSString *path = [baseDir stringByAppendingString:@"/amplitude_identify_storage.txt"];
    return path;
}

+ (void)storeEvent:(NSString *) event {
    NSString *path = [AMPStorage getDefaultEventsFile];
    NSURL *url = [NSURL fileURLWithPath:path];
    [AMPStorage storeEventAtUrl:url event:event];
}

+ (void)storeIdentify:(NSString *) identify {
    NSString *path = [AMPStorage getDefaultIdentifyFile];
    NSURL *url = [NSURL fileURLWithPath:path];
    [AMPStorage storeEventAtUrl:url event:identify];
}

+ (void)storeEventAtUrl:(NSURL *)url event:(NSString *)event {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [url path];
    
    bool newFile = false;
    if (![fm fileExistsAtPath:path]) {
        [AMPStorage start:path];
        newFile = true;
    }
    
    NSData *jsonData = [event dataUsingEncoding:NSUTF8StringEncoding];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:url error:nil];
    [handle seekToEndOfFile];
    if (!newFile) {
        [handle writeData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [handle writeData:jsonData];
    [handle closeFile];
}

+ (void)start:(NSString *)path {
    NSString *contents = @"{ \"batch\": [";
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:NULL error:NULL];
    [[NSFileManager defaultManager] createFileAtPath:path contents:NULL attributes:NULL];
    [contents writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

+ (void)finish:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:path]) {
        NSString *fileEnding = @"]}";
        NSData *endData = [fileEnding dataUsingEncoding:NSUTF8StringEncoding];
        
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle seekToEndOfFile];
        [handle writeData:endData];
        [handle closeFile];
    }
}

+ (void)remove:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:path error:NULL];
}

+ (NSMutableArray *)getEventsFromDisk:(NSString *)path {
    NSDictionary *json = [AMPStorage JSONFromFile:path];
    NSArray *eventsArr = [json objectForKey:@"batch"];
    return [eventsArr mutableCopy];
}

+ (NSDictionary *)JSONFromFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];
}

@end
