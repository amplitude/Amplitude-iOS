//
//  AMPPlan.m
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

#ifndef AMPLITUDE_LOG
#if AMPLITUDE_DEBUG
#   define AMPLITUDE_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define AMPLITUDE_LOG(...)
#endif
#endif

#import "AMPPlan.h"
#import "AMPConstants.h"
#import "AMPUtils.h"

@implementation AMPPlan

/*
 * Create an AMPPlan object
 */
+ (instancetype)plan {
    return [[self alloc] init];
}

- (AMPPlan *)setBranch:(NSString *)branch {
    if ([AMPUtils isEmptyString:branch]) {
        AMPLITUDE_LOG(@"Invalid empty branch");
        return self;
    }

    _branch = branch;
    return self;
}

- (AMPPlan *)setSource:(NSString *)source {
    if ([AMPUtils isEmptyString:source]) {
        AMPLITUDE_LOG(@"Invalid empty source");
        return self;
    }

    _source = source;
    return self;
}

- (AMPPlan *)setVersion:(NSString *)version {
    if ([AMPUtils isEmptyString:version]) {
        AMPLITUDE_LOG(@"Invalid empty version");
        return self;
    }

    _version = version;
    return self;
}

- (AMPPlan *)setVersionId:(NSString *)versionId {
    if ([AMPUtils isEmptyString:versionId]) {
        AMPLITUDE_LOG(@"Invalid empty versionId");
        return self;
    }

    _versionId = versionId;
    return self;
}

- (NSDictionary *)toNSDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (_branch) {
        [dict setValue:_branch forKey:AMP_PLAN_BRANCH];
    }
    if (_source) {
        [dict setValue:_source forKey:AMP_PLAN_SOURCE];
    }
    if (_version) {
        [dict setValue:_version forKey:AMP_PLAN_VERSION];
    }
    if (_versionId) {
        [dict setValue:_versionId forKey:AMP_PLAN_VERSION_ID];
    }
    return dict;
}

@end
