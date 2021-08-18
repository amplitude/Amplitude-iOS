//
//  AMPStorage.m
//  Copyright (c) 2021 Amplitude Inc. (https://amplitude.com/)
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
#import <Amplitude.h>
#import "AMPStorage.h"
#import "AMPUtils.h"
#import "AMPConstants.h"

@implementation AMPStorage

+ (BOOL)hasFileStorage:(NSString *)instanceName {
    NSString *fileStoragePath = [AMPStorage getAppStorageAmpDir:instanceName];
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:fileStoragePath isDirectory:&isDir];
    return isDir;
}

+ (NSString *)getAppStorageAmpDir:(NSString *)instanceName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [paths firstObject];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (instanceName == nil || [AMPUtils isEmptyString:instanceName]) {
        instanceName = kAMPDefaultInstance;
    }
    return [NSString stringWithFormat:@"%@/%@/%@", path, bundleIdentifier, instanceName];
}

+ (NSString *)getDefaultEventsFile:(NSString *)instanceName {
    NSString *baseDir = [AMPStorage getAppStorageAmpDir:instanceName];
    NSString *path = [baseDir stringByAppendingString:@"/amplitude_event_storage.txt"];
    return path;
}

+ (NSString *)getDefaultIdentifyFile:(NSString *)instanceName {
    NSString *baseDir = [AMPStorage getAppStorageAmpDir:instanceName];
    NSString *path = [baseDir stringByAppendingString:@"/amplitude_identify_storage.txt"];
    return path;
}

+ (void)storeEvent:(NSString *)event instanceName:(NSString *)instanceName {
    NSString *path = [AMPStorage getDefaultEventsFile:instanceName];
    NSURL *url = [NSURL fileURLWithPath:path];
    [AMPStorage storeEventAtUrl:url event:event];
}

+ (void)storeIdentify:(NSString *)identify instanceName:(NSString *)instanceName {
    NSString *path = [AMPStorage getDefaultIdentifyFile:instanceName];
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
    NSString *contents = @"[";
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:NULL error:NULL];
    [[NSFileManager defaultManager] createFileAtPath:path contents:NULL attributes:NULL];
    [contents writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

+ (void)remove:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:path error:NULL];
}

+ (NSMutableArray *)getEventsFromDisk:(NSString *)path {
    NSArray *eventsArr = [AMPStorage JSONFromFile:path];
    return [eventsArr mutableCopy];
}

+ (NSArray*)JSONFromFile:(NSString *)path {
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (content == nil) {
        content = [[NSMutableString alloc] init];
        [content appendString:@"["];
    }

    [content appendString:@"]"];
    NSData *completeData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonAsDict = [NSJSONSerialization JSONObjectWithData:completeData options:kNilOptions error:nil];

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle closeFile];
    }

    return jsonAsDict;
}

@end
