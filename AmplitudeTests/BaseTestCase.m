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
#import "Amplitude+SSLPinning.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPARCMacros.h"
#import "AMPDatabaseHelper.h"

NSString *const apiKey = @"000000";
NSString *const userId = @"userId";

@implementation BaseTestCase {
    id _archivedObj;
}

- (void)setUp {
    [super setUp];
    self.amplitude = [Amplitude alloc];
    self.databaseHelper = [AMPDatabaseHelper getDatabaseHelper];
    XCTAssertTrue([self.databaseHelper resetDB:NO]);

    [self.amplitude init];
    self.amplitude.sslPinningEnabled = NO;
}

- (void)tearDown {
    // Ensure all background operations are done
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];
    [self.amplitude flushQueue];
    SAFE_ARC_RELEASE(_amplitude);
    SAFE_ARC_RELEASE(_databaseHelper);
    [super tearDown];
}

- (BOOL)archive:(id)rootObject toFile:(NSString *)path {
    _archivedObj = rootObject;
    return YES;
}

- (id)unarchive:(NSString *)path {
    return _archivedObj;
}

@end
