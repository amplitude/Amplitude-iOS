//
//  Header.h
//  
//
//  Created by Dante Tam on 6/10/21.
//

#import <Amplitude.h>

@interface AMPStorage : NSObject

+ (NSString *)getDefaultEventsFile;
+ (NSString *)getDefaultIdentifyFile;
+ (void)storeEvent:(NSString *)event;
+ (void)storeIdentify:(NSString *)identify;
+ (void)storeEventAtUrl:(NSURL *)url event:(NSString *)event;
+ (void)start:(NSString *)path;
+ (void)finish:(NSString *)path;
+ (void)remove:(NSString *)path;
+ (NSMutableArray *)getEventsFromDisk:(NSString *)path;

@end
