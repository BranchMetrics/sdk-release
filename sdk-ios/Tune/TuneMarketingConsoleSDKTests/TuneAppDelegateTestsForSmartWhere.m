//
//  TuneAppDelegateTestsForSmartWhere.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 6/28/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneBlankAppDelegate.h"
#import "TuneXCTestCase.h"
#import "TuneSmartWhereHelper.h"
#import "SmartWhereForDelegateTest.h"

@import UIKit;

#if IDE_XCODE_8_OR_HIGHER
#import <UserNotifications/UserNotifications.h>
#endif

@interface TuneAppDelegateTestsForSmartWhere : TuneXCTestCase {
    TuneBlankAppDelegate *appDelegate;
    OCMockObject *mockApplication;
    OCMockObject *mockTuneSmartWhereHelper ;
    id mockNotification;
    id mockUNNotification;
    id mockUNNotificationResponse;
    OCMockObject *mockSmartWhere;
}

@end

@implementation TuneAppDelegateTestsForSmartWhere
- (void)setUp {
    [super setUp];
    
    appDelegate = [[TuneBlankAppDelegate alloc] init];
    mockApplication = OCMClassMock([UIApplication class]);
    mockTuneSmartWhereHelper = OCMStrictClassMock([TuneSmartWhereHelper class]);
    mockNotification = OCMStrictClassMock([UILocalNotification class]);
    mockUNNotification = OCMStrictClassMock([UNNotification class]);
    mockUNNotificationResponse = OCMClassMock([UNNotificationResponse class]);
    mockSmartWhere = OCMStrictClassMock([SmartWhereForDelegateTest class]);
}

- (void)tearDown {
    [mockTuneSmartWhereHelper stopMocking];
    [super tearDown];
}

#pragma mark - Testing Swizzles on local notification callbacks

#if IDE_XCODE_8_OR_HIGHER

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)testSwizzledDidReceiveNotificationResponseCallsSmartWhereHandler {
    
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper expect] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere expect] performSelector:@selector(didReceiveNotificationResponse:) withObject:mockUNNotificationResponse];
    
    [appDelegate userNotificationCenter:(id)[NSObject new] didReceiveNotificationResponse:mockUNNotificationResponse withCompletionHandler:^{
        NSLog(@"TuneAppDelegateTests: userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: called");
    }];
    
    [mockSmartWhere verify];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)testSwizzledDidReceiveNotificationResponseDoesntCallSmartWhereHandlerWhenNotAvailable {
    
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper reject] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper reject] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere reject] performSelector:@selector(didReceiveNotificationResponse:) withObject:mockUNNotificationResponse];
    
    [appDelegate userNotificationCenter:(id)[NSObject new] didReceiveNotificationResponse:mockUNNotificationResponse withCompletionHandler:^{
        NSLog(@"TuneAppDelegateTests: userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: called");
    }];
    
    [mockSmartWhere verify];
}
#pragma clang diagnostic pop
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)testSwizzledDidReceiveLocalNotificationCallSmartWhereDidReceiveLocalNotification {
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper expect] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere expect] performSelector:@selector(didReceiveLocalNotification:) withObject:mockNotification];
    
    [appDelegate application:(UIApplication *)mockApplication didReceiveLocalNotification:mockNotification];
    
    [mockTuneSmartWhereHelper verify];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)testSwizzledDidReceiveLocalNotificationDoesntCallSmartWhereDidReceiveLocalNotificationWhenNotAvailable {
    
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper reject] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper reject] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere expect] performSelector:@selector(didReceiveLocalNotification:) withObject:mockNotification];
    
    [appDelegate application:(UIApplication *)mockApplication didReceiveLocalNotification:mockNotification];
    
    [mockTuneSmartWhereHelper verify];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)testSwizzledDidReceiveLocalNotificationCallOriginalDidReceiveLocalNotification {
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper reject] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper reject] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere expect] performSelector:@selector(didReceiveLocalNotification:) withObject:mockNotification];
    
    [appDelegate application:(UIApplication *)mockApplication didReceiveLocalNotification:mockNotification];
    
    [mockTuneSmartWhereHelper verify];
    XCTAssertEqual(appDelegate.didReceiveLocalCount, 1);
    
}
#pragma clang diagnostic pop

- (void)testSwizzledWillPresentNotificationCallsSmartWhereWillPresentNotificationWhenAvailable {
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper expect] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere expect] performSelector:@selector(willPresentNotification:) withObject:mockUNNotification];
    
    [appDelegate userNotificationCenter:(id)[NSObject new] willPresentNotification:mockUNNotification withCompletionHandler:^(UNNotificationPresentationOptions options){
    }];
    
    [mockSmartWhere verify];
    [mockTuneSmartWhereHelper verify];
}

- (void)testSwizzledWillPresentNotificationDoesntCallSmartWhereWhenNotAvailable {
    [[[[mockTuneSmartWhereHelper expect] classMethod] andReturnValue: OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper reject] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper reject] andReturn:mockSmartWhere] getSmartWhere];
    
    [[mockSmartWhere reject] performSelector:@selector(willPresentNotification:) withObject:mockUNNotification];
    
    [appDelegate userNotificationCenter:(id)[NSObject new] willPresentNotification:mockUNNotification withCompletionHandler:^(UNNotificationPresentationOptions options){
    }];
    
    [mockSmartWhere verify];
    [mockTuneSmartWhereHelper verify];
}

- (void)testSwizzledWillPresentNotificationUsesOriginalCompleationHandlersValue {
    __block BOOL wasCompletionCalled = NO;
    
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue: OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    [(TuneSmartWhereHelper *)[[mockTuneSmartWhereHelper stub] andReturn:mockSmartWhere] getSmartWhere];
    
    [[[mockSmartWhere expect] andReturn:[NSObject new]] performSelector:@selector(willPresentNotification:) withObject:mockUNNotification];
    
    [appDelegate userNotificationCenter:(id)[NSObject new] willPresentNotification:mockUNNotification withCompletionHandler:^(UNNotificationPresentationOptions options){
        XCTAssertEqual(UNNotificationPresentationOptionNone, options);
        wasCompletionCalled = YES;
    }];
    
    XCTAssertTrue(wasCompletionCalled);
    [mockSmartWhere verify];
    [mockTuneSmartWhereHelper verify];
}

@end

