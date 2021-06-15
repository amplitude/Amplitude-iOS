//
//  File.m
//  
//
//  Created by Dante Tam on 6/10/21.
//

#import <Foundation/Foundation.h>

#import "AMPStorage.h"

@interface AMPStorage ()
@end

@implementation AMPStorage {
    
}

+ (void)storeEventDefaultURL:(NSString *) event {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    bundleIdentifier = [bundleIdentifier stringByAppendingString:@"/amplitude_event_storage"];
    NSString *path = [bundleIdentifier stringByAppendingPathExtension:@"txt"];
    NSLog(@"Storing event here");
    NSLog(@"%@", path);
    NSURL *url = [NSURL fileURLWithPath:path];
    [AMPStorage storeEvent:url event:event];
}

+ (void)storeEvent:(NSURL *)url event:(NSString *)event {
    NSFileManager *fm = [NSFileManager defaultManager];
    bool newFile = false;
    if (![fm fileExistsAtPath:[url path]]) {
        [AMPStorage start:url];
        newFile = true;
    }
    
    NSLog(@"Storing event here");
    
    NSData *jsonData = [event dataUsingEncoding:NSUTF8StringEncoding];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:url error:nil];
    [handle seekToEndOfFile];
    if (!newFile) {
        [handle writeData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [handle writeData:jsonData];
    [handle closeFile];
}

+ (void)start:(NSURL *)url {
    NSString *path = [url path];
    NSString *contents = @"{ \"batch\": [";
    [contents writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"Started url here");
}

+ (void)finish:(NSURL *)url {
    NSLog(@"Finishing url here");
    NSLog(@"%@", [url path]);
    NSURL *tempFile = url; //[url URLByAppendingPathExtension:@"txt"];
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:tempFile error:nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
    NSDate *now = [NSDate date];
    NSString *sentAt = [dateFormatter stringFromDate:now];
    
    NSString *fileEnding = @"],\"sentAt\":\"\(sentAt)\"}";
    NSData *endData = [fileEnding dataUsingEncoding:NSUTF8StringEncoding];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:tempFile error:nil];
    [handle seekToEndOfFile];
    [handle writeData:endData];
    [handle closeFile];
}

+ (void)remove:(NSURL *)url {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtURL:url error:nil];
    NSURL *actualFile = [url URLByDeletingPathExtension];
    [fm removeItemAtURL:actualFile error:nil];
}

@end
