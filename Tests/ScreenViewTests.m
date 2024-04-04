//
//  ScreenViewTests.m
//  Amplitude
//
//  Created by Marvin Liu on 6/28/23.
//  Copyright © 2023 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "UIViewController+AMPScreen.h"

#if !TARGET_OS_OSX && !TARGET_OS_WATCH
@interface ScreenViewTests : BaseTestCase

@end

@implementation ScreenViewTests {
    UIWindow *window;
    UIViewController *rootViewController;
}

- (void)setUp {
    [super setUp];
    Amplitude *amplitude = [Amplitude instance];
    amplitude.defaultTracking.screenViews = YES;
    [amplitude initializeApiKey:@"test-api-key"];
    
    window = [[UIWindow alloc] init];
    rootViewController = [[UIViewController alloc] init];
    [window addSubview:rootViewController.view];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testTopViewControllerReturnsRootController {
    UIViewController *controller = [UIViewController amp_topViewController:rootViewController];

    XCTAssertEqual(controller, rootViewController);
}

- (void)testTopViewControllerReturnsPresentedController {
    UIViewController *presentController = [[UIViewController alloc] init];
    [rootViewController presentViewController:presentController animated:NO completion:^{}];
    
    XCTAssertEqual(presentController, [UIViewController amp_topViewController:rootViewController]);
}

- (void)testTopViewControllerReturnsNavigationPushedController {
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    [rootViewController presentViewController:navigationController animated:NO completion:^{}];

    UIViewController *controller = [[UIViewController alloc] init];
    [navigationController pushViewController:controller animated:NO];
    
    XCTAssertEqual(controller, [UIViewController amp_topViewController:rootViewController]);
}

- (void)testTopViewControllerReturnsSelectedTabBarController {
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [rootViewController presentViewController:tabBarController animated:NO completion:^{}];

    UIViewController *controller = [[UIViewController alloc] init];
    [tabBarController setViewControllers:@[[[UIViewController alloc] init], controller]];
    [tabBarController setSelectedIndex:1];
    
    XCTAssertEqual(controller, [UIViewController amp_topViewController:rootViewController]);
}

- (void)testTopViewControllerReturnsFirstChildViewController {
    UIViewController *containerController = [[UIViewController alloc] init];
    [rootViewController presentViewController:containerController animated:NO completion:^{}];
    

    UIViewController *controller = [[UIViewController alloc] init];
    [containerController addChildViewController:controller];
    [containerController addChildViewController:[[UIViewController alloc] init]];
    
    XCTAssertEqual(controller, [UIViewController amp_topViewController:rootViewController]);
}

@end
#endif
