//
//  BaseTestCase.h
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPDatabaseHelper.h"
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

extern NSString *const apiKey;
extern NSString *const userId;

@interface BaseTestCase : XCTestCase

@property (nonatomic, strong) Amplitude *amplitude;
@property (nonatomic, strong) AMPDatabaseHelper *databaseHelper;

- (BOOL) archive:(id)rootObject toFile:(NSString *)path;
- (id) unarchive:(NSString *)path;

@end
