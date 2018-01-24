//
//  TuneTriggerManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneTriggerManager+Testing.h"
#import "DictionaryLoader.h"
#import "TunePlaylist.h"
#import "TuneSkyhookCenter.h"
#import "TuneBannerMessageView.h"
#import "TuneAnalyticsEvent.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDeviceDetails.h"
#import "TuneBannerMessage.h"
#import "TuneXCTestCase.h"
#import "TuneEvent.h"

@interface TuneTriggerManagerTests : TuneXCTestCase {
    NSDictionary *bannerDictionary;
    TunePlaylist *bannerPlaylist;
    
    TuneSkyhookCenter *skyhookCenter;
    
    TuneEvent *testEvent;
    
    // Mocks
    id deviceDetailsMock;
    
    XCTestExpectation *expectation;
}

@end

@implementation TuneTriggerManagerTests

static int EXPECTATION_TIMEOUT = 2;

- (void)setUp {
    [super setUp];

    [TuneManager currentManager].configuration.debugLoggingOn = YES;
    
    skyhookCenter = [TuneSkyhookCenter defaultCenter];
    
    bannerDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"SlideInMessage1"];
    bannerPlaylist = [TunePlaylist playlistWithDictionary:bannerDictionary];
    
    testEvent = [TuneEvent eventWithName:@"testEvent"];
    
    deviceDetailsMock = OCMClassMock([TuneDeviceDetails class]);
    
    NSArray *supportedOrientations = @[@"UIInterfaceOrientationPortrait", @"UIInterfaceOrientationPortraitUpsideDown", @"UIInterfaceOrientationLandscapeLeft", @"UIInterfaceOrientationLandscapeRight" ];
    OCMStub(ClassMethod([deviceDetailsMock getSupportedDeviceOrientations])).andReturn(supportedOrientations);
}

- (void)tearDown {
    [deviceDetailsMock stopMocking];
    
    [[TuneManager currentManager].triggerManager clearMessageDisplayFrequencyDictionary];
    [[[TuneManager currentManager].triggerManager messageToShow] dismiss];
    
    [super tearDown];
}

#pragma mark - First Playlist Downloaded Trigger

- (void)testTriggerManagerTriggersFirstPlaylistDownloadedEvent {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    NSMutableDictionary *mutableSlideIn = bannerDictionary.mutableCopy;
    // Set the triggerEvent to the MD5 hash of the First Playlist Downloaded event. (Application|||FirstPlaylistDownloaded|SESSION)
    mutableSlideIn[@"messages"][@"message_id_1"][@"triggerEvent"] = @"c1f8bd652909257485fb70e803d93915";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block BOOL firstPlaylistDownloadedEventTriggeredMessage = NO;
    id bannerFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([bannerFactoryMock display]).andDo(^(NSInvocation *invocation) {
        firstPlaylistDownloadedEventTriggeredMessage = YES;
        [expectation fulfill];
    });

    [skyhookCenter postSkyhook:TunePlaylistManagerFirstPlaylistDownloaded object:nil userInfo:@{TunePayloadFirstPlaylistDownloaded: newPlaylist }];
    
    [self waitForMessageToDisplay];
    
    XCTAssertTrue(firstPlaylistDownloadedEventTriggeredMessage);
    
    [bannerFactoryMock stopMocking];
}

#pragma mark - Different Frequencies

- (void)testTriggerManagerTriggersInAppMessageForEveryTimeFrequency {
    // Setup the TriggerManager with out Slide In message
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: bannerPlaylist }];
    
     __block int callCount = 0;
    id bannerFactoryMock = OCMPartialMock(bannerPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([bannerFactoryMock display]).andDo(^(NSInvocation *invocation) {
        callCount++;
        [expectation fulfill];
    });
    
    for (int i = 0; i < 4; i++) {
        // Post the event that triggers the Slide In message
        [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
        
        expectation = [self expectationWithDescription:@"Waiting for message to display"];
        [self waitForMessageToDisplay];
    }
    
    // Test that the message continues to show even after foreground/background
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    for (int i = 0; i < 4; i++) {
        // Post the event that triggers the Slide In message
        [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
        
        expectation = [self expectationWithDescription:@"Waiting for message to display"];
        [self waitForMessageToDisplay];
    }
    
    XCTAssertEqual(callCount, 8);
    
    [bannerFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersOnlyOnceFrequency {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    NSMutableDictionary *mutableSlideIn = bannerDictionary.mutableCopy;
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"1";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"1";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block int callCount = 0;
    id bannerFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([bannerFactoryMock display]).andDo(^(NSInvocation *invocation) {
        callCount++;
        [expectation fulfill];
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [self waitForMessageToDisplay];
    
    XCTAssertEqual(callCount, 1);
    
    [bannerFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersXTimesPerSessionFrequency {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    NSMutableDictionary *mutableBanner = bannerDictionary.mutableCopy;
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"3";
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"scope"] = @"SESSION";
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"0";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableBanner];
    
    __block int callCount = 0;
    id bannerFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([bannerFactoryMock display]).andDo(^(NSInvocation *invocation) {
        callCount++;
        if (callCount == 3 || callCount == 5) {
            [expectation fulfill];
        }
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [self waitForMessageToDisplay];
    
    XCTAssertEqual(callCount, 3);
    
    expectation = [self expectationWithDescription:@"Waiting for message to display"];

    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];

    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];

    [self waitForMessageToDisplay];

    XCTAssertEqual(callCount, 5);
    
    [bannerFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersXTimesAnEventHappensFrequency {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    NSMutableDictionary *mutableBanner = bannerDictionary.mutableCopy;
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"2";
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"scope"] = @"EVENT";
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"0";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableBanner];
    
    __block int callCount = 0;
    id bannerFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([bannerFactoryMock display]).andDo(^(NSInvocation *invocation) {
        callCount++;
        if (callCount == 2) {
            [expectation fulfill];
        }
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [self waitForMessageToDisplay];
    
    XCTAssertEqual(callCount, 2);
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    XCTAssertEqual(callCount, 2);
    
    [bannerFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersXDaysSinceEventHappensFrequency {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    NSMutableDictionary *mutableBanner = bannerDictionary.mutableCopy;
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"3";
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"scope"] = @"DAYS";
    mutableBanner[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"0";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableBanner];
    
    __block int callCount = 0;
    id bannerFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([bannerFactoryMock display]).andDo(^(NSInvocation *invocation) {
        callCount++;
        [expectation fulfill];
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [self waitForMessageToDisplay];
    
    XCTAssertEqual(callCount, 1);
    
    NSDate *threeDaysFromNow = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * 4];
    id nsDateMock = OCMClassMock([NSDate class]);
    OCMStub(ClassMethod([nsDateMock date])).andReturn(threeDaysFromNow);
    
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    [skyhookCenter postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: testEvent }];
    
    [self waitForMessageToDisplay];
    
    XCTAssertEqual(callCount, 2);
    
    [nsDateMock stopMocking];
    
    [bannerFactoryMock stopMocking];
}

- (void)waitForMessageToDisplay {
    // Wait for message to get displayed, expectation is fulfilled in message display method
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

@end
