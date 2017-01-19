//
//  TuneAppDelegateTests.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SimpleObserver.h"
#import "Tune+Testing.h"
#import "TuneAppDelegate.h"
#import "TuneBlankAppDelegate.h"
#import "TuneDeviceDetails.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneTestsHelper.h"
#import "TuneXCTestCase.h"

@import UIKit;

#if IDE_XCODE_8_OR_HIGHER
#import <UserNotifications/UserNotifications.h>
#endif

@interface UIApplication (TuneTestAppDelegateTests)

@property(nonatomic, readonly) UIApplication *sharedApplication;

@end

#if IDE_XCODE_8_OR_HIGHER

@interface TuneUNNotification : UNNotification

@property (nonatomic, readwrite, copy) NSDate *date;

// The notification request that caused the notification to be delivered.
@property (nonatomic, readwrite, copy) UNNotificationRequest *request;

@end

@implementation TuneUNNotification

@synthesize date, request;

@end

@interface TuneUNNotificationResponse : UNNotificationResponse

@property (NS_NONATOMIC_IOSONLY, readwrite, copy) UNNotification *notification;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSString *actionIdentifier;

@end

@implementation TuneUNNotificationResponse

@synthesize notification, actionIdentifier;

@end

#endif

@interface TuneAppDelegateTests : TuneXCTestCase {
    SimpleObserver *pushObserver;
    SimpleObserver *campaignObserver;
    SimpleObserver *deeplinkObserver;
    SimpleObserver *deepActionObserver;
    SimpleObserver *deviceTokenObserver;
    TuneBlankAppDelegate *appDelegate;
    NSMutableDictionary *receivedUserInfo;
    OCMockObject *mockApplication;
}

@end

static NSString *tune_swizzledMethod;

@implementation TuneAppDelegateTests

- (void)setUp {
    [super setUp];

    pushObserver = [[SimpleObserver alloc] init];
    campaignObserver = [[SimpleObserver alloc] init];
    deeplinkObserver = [[SimpleObserver alloc] init];
    deepActionObserver = [[SimpleObserver alloc] init];
    deviceTokenObserver = [[SimpleObserver alloc] init];
    appDelegate = [[TuneBlankAppDelegate alloc] init];
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([(UIApplication *)mockApplication sharedApplication]).andReturn(mockApplication);
    tune_swizzledMethod = nil;
}

- (void)tearDown {
    [mockApplication stopMocking];
    
    [super tearDown];
}

#pragma mark - Testing Swizzles on push notification callbacks

- (void)testSwizzledDidReceiveRemoteNotificationSendsOpenAndViewSkyhooksFromBackground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateBackground)] applicationState];
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ARTPID":@"54da8cd07d891c23a0000017", @"CAMPAIGN_ID": @"54da85647d891c629c000011", @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 2);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.didReceiveCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

- (void)testSwizzledDidReceiveRemoteNotificationSendsOpenAndViewSkyhooksFromForeground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateActive)] applicationState];
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ARTPID":@"54da8cd07d891c23a0000017", @"CAMPAIGN_ID": @"54da85647d891c629c000011", @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 1);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.didReceiveCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

#if IDE_XCODE_8_OR_HIGHER
- (void)testSwizzledUNUserNotificationDidReceiveRemoteNotificationSendsOpenAndViewSkyhooksFromBackground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateBackground)] applicationState];
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ARTPID":@"54da8cd07d891c23a0000017", @"CAMPAIGN_ID": @"54da85647d891c629c000011", @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    
    UNMutableNotificationContent *cont = [UNMutableNotificationContent new];
    cont.userInfo = userInfo;
    
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"" content:cont trigger:nil];
    
    TuneUNNotification *notif = [TuneUNNotification new];
    notif.request = req;
    notif.date = [NSDate date];
    
    TuneUNNotificationResponse *resp = [TuneUNNotificationResponse new];
    resp.actionIdentifier = UNNotificationDefaultActionIdentifier;
    resp.notification = notif;
    
    [appDelegate userNotificationCenter:(id)[NSObject new] didReceiveNotificationResponse:resp withCompletionHandler:^{
        NSLog(@"TuneAppDelegateTests: userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: called");
    }];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 2);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.didReceiveCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

- (void)testSwizzledUNUserNotificationDidReceiveRemoteNotificationSendsOpenAndViewSkyhooksFromForeground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateActive)] applicationState];
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ARTPID":@"54da8cd07d891c23a0000017", @"CAMPAIGN_ID": @"54da85647d891c629c000011", @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    UNMutableNotificationContent *cont = [UNMutableNotificationContent new];
    cont.userInfo = userInfo;
    
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"" content:cont trigger:nil];
    
    TuneUNNotification *notif = [TuneUNNotification new];
    notif.request = req;
    notif.date = [NSDate date];
    
    TuneUNNotificationResponse *resp = [TuneUNNotificationResponse new];
    resp.actionIdentifier = UNNotificationDefaultActionIdentifier;
    resp.notification = notif;
    
    [appDelegate userNotificationCenter:(id)[NSObject new] didReceiveNotificationResponse:resp withCompletionHandler:^{
        NSLog(@"TuneAppDelegateTests: userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: called");
    }];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 1);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.didReceiveCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}
#endif

- (void)testSwizzledHandleActionWithIdentifierSendsOpenAndViewSkyhooksFromHandleAction {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateActive)] applicationState];
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ARTPID":@"54da8cd07d891c23a0000017", @"CAMPAIGN_ID": @"54da85647d891c629c000011", @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication handleActionWithIdentifier:@"id" forRemoteNotification:userInfo completionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 1);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.handleActionCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

- (void)testSwizzledNotHandlingNonIAMPush0 {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateActive)] applicationState];
    NSDictionary *userInfo = @{ @"aps": @{ @"alert": @"OTHER PUSH PROVIDER"}};
    [appDelegate application:(UIApplication *)mockApplication handleActionWithIdentifier:@"id" forRemoteNotification:userInfo completionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 0);
    XCTAssertEqual([campaignObserver skyhookPostCount], 0);
    XCTAssertEqual(appDelegate.handleActionCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

- (void)testSwizzledDidRegisterSendsRegisteredForRemoteNotificationsWithDeviceTokenSkyhook {
    [[TuneSkyhookCenter defaultCenter] addObserver:deviceTokenObserver selector:@selector(skyhookPosted:) name:TuneRegisteredForRemoteNotificationsWithDeviceToken object:nil];
    
    [appDelegate application:(UIApplication *)mockApplication didRegisterForRemoteNotificationsWithDeviceToken:[@"testToken" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTAssertEqual([deviceTokenObserver skyhookPostCount], 1);
    XCTAssertEqual([deviceTokenObserver lastPayload].object, appDelegate);
    XCTAssertEqual(appDelegate.didRegisterCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:deviceTokenObserver name:TuneRegisteredForRemoteNotificationsWithDeviceToken object:nil];
}

#pragma mark - Test Push Notification deeplinks send campaign and analytics data

- (void)testDeeplinkOpenedFromPushNotificationFromBackground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateBackground)] applicationState];
    
    NSDictionary *userInfo = @{@"ANA":@{@"URL":@"artisan://cart?SRC=EMAIL&ACID=278730"}, @"ARTPID": @"test", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush queues
    waitForQueuesToFinish();
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 2);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.didReceiveCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

- (void)testDeeplinkOpenedFromPushNotificationFromForeground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateActive)] applicationState];
    
    NSDictionary *userInfo = @{@"ANA":@{@"URL":@"artisan://cart?SRC=EMAIL&ACID=278730"}, @"ARTPID": @"test", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush queues
    waitForQueuesToFinish();
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    XCTAssertEqual([pushObserver skyhookPostCount], 1);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.didReceiveCount, 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
}

#pragma mark - Test Push Notification deep actions get received

// UIApplication sharedApplication being nil in unit test prevents the DA from being found in TuneNotificationProcessing
// Can't bypass with ANAF as NSThread is also nil in TuneDeepActionManager, so unable to trigger TuneDeepActionTriggered
- (void)testDeepActionOpenedFromPushNotificationFromBackground {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:deepActionObserver selector:@selector(skyhookPosted:) name:TuneDeepActionTriggered object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateBackground)] applicationState];
    
    [appDelegate applicationDidFinishLaunching:(UIApplication *)mockApplication];
    
    NSDictionary *userInfo = @{@"ANAF":@{@"DA":@"myBlankAppDelegatesDeepAction", @"DAD":@{@"message":@"Received deep action!"}}, @"ARTPID": @"TEST", @"aps": @{ @"alert":@"Pushy pow wow! A", @"LENGTH_TO_REPORT":@(20000)}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush queues
    waitForQueuesToFinish();
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    waitFor(1.);
    
    XCTAssertEqual([pushObserver skyhookPostCount], 2);
    XCTAssertEqual([campaignObserver skyhookPostCount], 1);
    XCTAssertEqual([deepActionObserver skyhookPostCount], 1);
    XCTAssertEqual(appDelegate.deepActionCount, 1);
    XCTAssertEqual(appDelegate.deepActionValue, @"Received deep action!");
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:deepActionObserver name:TuneDeepActionTriggered object:nil];
}

#pragma mark - Test TunePushInfo

- (void)testPushInfoFromPushNotification {
    [[TuneSkyhookCenter defaultCenter] addObserver:pushObserver selector:@selector(skyhookPosted:) name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:campaignObserver selector:@selector(skyhookPosted:) name:TuneCampaignViewed object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:deepActionObserver selector:@selector(skyhookPosted:) name:TuneDeepActionTriggered object:nil];
    [(UIApplication *)[[mockApplication stub] andReturnValue:@(UIApplicationStateBackground)] applicationState];
    
    [appDelegate applicationDidFinishLaunching:(UIApplication *)mockApplication];
    
    TunePushInfo *pushInfoBefore = [Tune getTunePushInfoForSession];
    XCTAssertNil(pushInfoBefore.pushId);
    XCTAssertNil(pushInfoBefore.campaignId);
    XCTAssertNil(pushInfoBefore.extrasPayload);
    
    NSString *pushId = @"TEST_PUSH_ID";
    NSString *campaignId = @"TEST_CAMPAIGN_ID";
    NSDictionary *extrasPayload = @{@"DA":@"myBlankAppDelegatesDeepAction", @"DAD":@{@"message":@"Received deep action!"}};
    
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ANAF":extrasPayload, @"ARTPID":pushId, @"CAMPAIGN_ID":campaignId, @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Flush queues
    waitForQueuesToFinish();
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    
    TunePushInfo *pushInfoAfter = [Tune getTunePushInfoForSession];
    
    XCTAssertEqualObjects(pushInfoAfter.pushId, pushId);
    XCTAssertEqualObjects(pushInfoAfter.campaignId, campaignId);
    XCTAssertEqualObjects(pushInfoAfter.extrasPayload, @{@"ANAF":extrasPayload});
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:pushObserver name:TunePushNotificationOpened object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:campaignObserver name:TuneCampaignViewed object:nil];
    [[TuneSkyhookCenter defaultCenter] removeObserver:deepActionObserver name:TuneDeepActionTriggered object:nil];
}

#pragma mark - Test TuneAppDelegate UIApplicationDelegate Swizzles

/**
 Helps test TuneAppDelegate swizzleTheirSelector: functionality.
 */
- (void)testSwizzling {
    NSDictionary *userInfo = @{@"ANA":@{@"CS" :@"54da8cd07d891c23a0000016",@"D":@"0"}, @"ARTPID":@"54da8cd07d891c23a0000017", @"CAMPAIGN_ID": @"54da85647d891c629c000011", @"LENGTH_TO_REPORT":@"604800", @"aps": @{ @"alert":@"Pushy pow wow! A"}};
    [appDelegate application:(UIApplication *)mockApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    [self checkSwizzledMethod:@"application:didReceiveRemoteNotification:fetchCompletionHandler:"];
    tune_swizzledMethod = nil;
    
    [appDelegate application:(UIApplication *)mockApplication handleActionWithIdentifier:@"id" forRemoteNotification:userInfo completionHandler:^(UIBackgroundFetchResult result){}];
    [self checkSwizzledMethod:@"application:handleActionWithIdentifier:forRemoteNotification:completionHandler:"];
    tune_swizzledMethod = nil;
    
    [appDelegate application:(UIApplication *)mockApplication didRegisterForRemoteNotificationsWithDeviceToken:[@"testToken" dataUsingEncoding:NSUTF8StringEncoding]];
    [self checkSwizzledMethod:@"application:didRegisterForRemoteNotificationsWithDeviceToken:"];
    tune_swizzledMethod = nil;
    
#if IDE_XCODE_8_OR_HIGHER
    UNMutableNotificationContent *cont = [UNMutableNotificationContent new];
    cont.userInfo = userInfo;
    
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"" content:cont trigger:nil];
    
    TuneUNNotification *notif = [TuneUNNotification new];
    notif.request = req;
    notif.date = [NSDate date];
    
    TuneUNNotificationResponse *resp = [TuneUNNotificationResponse new];
    resp.actionIdentifier = UNNotificationDefaultActionIdentifier;
    resp.notification = notif;
    
    [appDelegate userNotificationCenter:(id)[NSObject new] didReceiveNotificationResponse:resp withCompletionHandler:^{
        NSLog(@"TuneAppDelegateTests: userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: called");
    }];
    [self checkSwizzledMethod:@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"];
    tune_swizzledMethod = nil;
#endif
    
    [appDelegate applicationDidFinishLaunching:(UIApplication *)mockApplication];
    [self checkSwizzledMethod:nil];
}

#pragma mark - Helper Methods

+ (void)_tuneSuperSecretTestingCallbackSwizzleCalled:(NSString *)swizzledMethod {
    tune_swizzledMethod = swizzledMethod;
}

- (void)checkSwizzledMethod:(NSString *)expectedSwizzledMethod {
    XCTAssertEqual(expectedSwizzledMethod, tune_swizzledMethod);
}

@end
