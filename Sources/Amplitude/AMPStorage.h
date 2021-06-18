//
//  Header.h
//  
//
//  Created by Dante Tam on 6/10/21.
//

#import <Amplitude.h>

@interface AMPStorage : NSObject

+ (NSString *)getDefaultEventsFile:(NSString *)instanceName;
+ (NSString *)getDefaultIdentifyFile:(NSString *)instanceName;
+ (void)storeEvent:(NSString *)event instanceName:(NSString *)instanceName;
+ (void)storeIdentify:(NSString *)identify instanceName:(NSString *)instanceName;;
+ (void)storeEventAtUrl:(NSURL *)url event:(NSString *)event;
+ (void)start:(NSString *)path;
+ (void)finish:(NSString *)path;
+ (void)remove:(NSString *)path;
+ (NSMutableArray *)getEventsFromDisk:(NSString *)path;

@end
