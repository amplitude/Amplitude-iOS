//
//  Header.h
//  
//
//  Created by Dante Tam on 6/10/21.
//

@interface AMPStorage : NSObject

+ (NSString *)getDefaultEventsFile;
+ (NSString *)getDefaultIdentifyFile;
+ (void)storeEvent:(NSString *)event;
+ (void)storeIdentify:(NSString *)event;
+ (void)storeEventAtUrl:(NSURL *)url event:(NSString *)event;
+ (void)start:(NSString *)path;
+ (void)finish:(NSString *)path;
+ (void)remove:(NSString *)path;
+ (NSMutableArray *)getEventsFromDisk:(NSString *)path;

@end
