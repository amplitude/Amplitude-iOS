//
//  DefaultTrackingOptionsTests.m
//  Amplitude
//
//  Created by Marvin Liu on 6/16/23.
//  Copyright © 2023 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPDefaultTrackingOptions.h"
#import "AMPConstants.h"

@interface DefaultTrackingOptionsTests : XCTestCase

@end

@implementation DefaultTrackingOptionsTests

- (void)testInit {
    AMPDefaultTrackingOptions *instance = [[AMPDefaultTrackingOptions alloc] init];
    
    XCTAssertFalse(instance.sessions);
    XCTAssertFalse(instance.appLifecycles);
    XCTAssertFalse(instance.deepLinks);
    XCTAssertFalse(instance.screenViews);
}

- (void)testInitWithCustomeOptions {
    AMPDefaultTrackingOptions *instance = [AMPDefaultTrackingOptions initWithSessions:NO
                                                                        appLifecycles:YES
                                                                            deepLinks:YES
                                                                          screenViews:YES];
    
    XCTAssertFalse(instance.sessions);
    XCTAssertTrue(instance.appLifecycles);
    XCTAssertTrue(instance.deepLinks);
    XCTAssertTrue(instance.screenViews);
}

- (void)testInitWithAllEnabled {
    AMPDefaultTrackingOptions *instance = [AMPDefaultTrackingOptions initWithAllEnabled];
    
    XCTAssertTrue(instance.sessions);
    XCTAssertTrue(instance.appLifecycles);
    XCTAssertTrue(instance.deepLinks);
    XCTAssertTrue(instance.screenViews);
}

- (void)testInitWithNoneEnabled {
    AMPDefaultTrackingOptions *instance = [AMPDefaultTrackingOptions initWithNoneEnabled];
    
    XCTAssertFalse(instance.sessions);
    XCTAssertFalse(instance.appLifecycles);
    XCTAssertFalse(instance.deepLinks);
    XCTAssertFalse(instance.screenViews);
}

@end
