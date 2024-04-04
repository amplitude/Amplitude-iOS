//
//  AMPIngestionMetadata.m
//  Copyright (c) 2022 Amplitude Inc. (https://amplitude.com/)
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

#ifndef AMPLITUDE_LOG
#if AMPLITUDE_DEBUG
#   define AMPLITUDE_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define AMPLITUDE_LOG(...)
#endif
#endif

#import "AMPIngestionMetadata.h"
#import "AMPConstants.h"
#import "AMPUtils.h"

@implementation AMPIngestionMetadata

/*
 * Create an AMPIngestionMetadata object
 */
+ (instancetype)ingestionMetadata {
    return [[self alloc] init];
}

- (AMPIngestionMetadata *)setSourceName:(NSString *)sourceName {
    if ([AMPUtils isEmptyString:sourceName]) {
        AMPLITUDE_LOG(@"Invalid empty sourceName");
        return self;
    }

    _sourceName = sourceName;
    return self;
}

- (AMPIngestionMetadata *)setSourceVersion:(NSString *)sourceVersion {
    if ([AMPUtils isEmptyString:sourceVersion]) {
        AMPLITUDE_LOG(@"Invalid empty sourceVersion");
        return self;
    }

    _sourceVersion = sourceVersion;
    return self;
}

- (NSDictionary *)toNSDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (_sourceName) {
        [dict setValue:_sourceName forKey:AMP_INGESTION_METADATA_SOURCE_NAME];
    }
    if (_sourceVersion) {
        [dict setValue:_sourceVersion forKey:AMP_INGESTION_METADATA_SOURCE_VERSION];
    }
    return dict;
}

@end
