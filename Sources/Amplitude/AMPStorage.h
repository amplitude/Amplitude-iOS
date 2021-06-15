//
//  Header.h
//  
//
//  Created by Dante Tam on 6/10/21.
//

@interface AMPStorage : NSObject

+ (void)storeEventDefaultURL:(NSString *)event;
+ (void)storeEvent:(NSURL *)url event:(NSString *)event;
+ (void)start:(NSURL *)url;
+ (void)finish:(NSURL *)url;
+ (void)remove:(NSURL *)url;

@end
