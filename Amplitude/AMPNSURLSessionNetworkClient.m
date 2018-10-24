//
//  AMPNSURLSessionNetworkClient.m
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/24/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import "AMPNSURLSessionNetworkClient.h"
#import "AMPARCMacros.h"
#import "AMPEventUploadRequest.h"

@interface AMPNSURLSessionNetworkClient()
@property (nonatomic, strong, nonnull) NSURLSession *session;
@end

@implementation AMPNSURLSessionNetworkClient
- (instancetype) initWithNSURLSession: (NSURLSession *) session {
    self = [super init];
    _session = session;
    return self;
}

- (void)uploadEvents:(nonnull AMPEventUploadRequest *)uploadRequest completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadRequest.url];
    [request setTimeoutInterval:60.0];

    NSString *apiVersionString = [[NSNumber numberWithInt:uploadRequest.apiVersion] stringValue];

    NSMutableData *postData = [[NSMutableData alloc] init];
    [postData appendData:[@"v=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[apiVersionString dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&client=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[uploadRequest.apiKey dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"&e=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[self urlEncodeString:uploadRequest.events] dataUsingEncoding:NSUTF8StringEncoding]];

    // Add timestamp of upload
    [postData appendData:[@"&upload_time=" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *timestampString = [[NSNumber numberWithLongLong: uploadRequest.uploadTime] stringValue];
    [postData appendData:[timestampString dataUsingEncoding:NSUTF8StringEncoding]];

    [postData appendData:[@"&checksum=" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[uploadRequest.checksum dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];

    [request setHTTPBody:postData];

    SAFE_ARC_RELEASE(postData);

    [[self.session dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

- (NSString*)urlEncodeString:(NSString*) string {
    NSCharacterSet * allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"] invertedSet];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

- (void) dealloc {
    SAFE_ARC_RELEASE(_session);
    SAFE_ARC_SUPER_DEALLOC();
}

@end
