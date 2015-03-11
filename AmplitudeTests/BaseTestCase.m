//
//  BaseTestCase.m
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"

NSString *const apiKey = @"000000";
NSString *const userId = @"userId";

@implementation BaseTestCase {
    id _archivedObj;
    id _partialMock;
}

- (void)setUp {
    [super setUp];
    self.amplitude = [Amplitude alloc];

    // Mock the methods before init
    _partialMock = OCMPartialMock(self.amplitude);
    OCMStub([_partialMock archive:[OCMArg any] toFile:[OCMArg any]]).andCall(self, @selector(archive:toFile:));
    OCMStub([_partialMock unarchive:[OCMArg any]]).andCall(self, @selector(unarchive:));

    [self.amplitude init];
}

- (void)tearDown {
    // Ensure all background operations are done
    [self.amplitude flushQueue];
    [super tearDown];
}

- (BOOL) archive:(id)rootObject toFile:(NSString *)path {
    _archivedObj = rootObject;
    return TRUE;
}

- (id) unarchive:(NSString *)path {
    return _archivedObj;
}

@end
