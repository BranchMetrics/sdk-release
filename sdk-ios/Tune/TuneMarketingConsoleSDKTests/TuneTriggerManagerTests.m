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
#import "TuneiOS8SlideInMessageView.h"
#import "TuneAnalyticsEvent.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDeviceDetails.h"
#import "TuneSlideInMessageFactory.h"

@interface TuneTriggerManagerTests : XCTestCase {
    NSDictionary *slideInDictionary;
    TunePlaylist *slideInPlaylist;
    
    TuneSkyhookCenter *skyhookCenter;
    
    TuneAnalyticsEvent *pageViewEvent;
    NSString *pageViewEventMd5;
    
    // Mocks
    id deviceDetailsMock;
}

@end

@implementation TuneTriggerManagerTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    [TuneManager currentManager].configuration.debugLoggingOn = YES;
    
    skyhookCenter = [TuneSkyhookCenter defaultCenter];
    
    slideInDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"SlideInMessage1"];
    slideInPlaylist = [TunePlaylist playlistWithDictionary:slideInDictionary];
    
    pageViewEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PAGEVIEW
                                                           action:nil
                                                         category:@"ADProductListCollectionViewController::ODS-eB-Bvq-view-RLy-jj-RKC"
                                                          control:nil
                                                     controlEvent:nil
                                                             tags:nil
                                                            items:nil];
    pageViewEventMd5 = [pageViewEvent getEventMd5];
    
    deviceDetailsMock = OCMClassMock([TuneDeviceDetails class]);
    
    NSArray *supportedOrientations = @[@"UIInterfaceOrientationPortrait", @"UIInterfaceOrientationPortraitUpsideDown", @"UIInterfaceOrientationLandscapeLeft", @"UIInterfaceOrientationLandscapeRight" ];
    OCMStub(ClassMethod([deviceDetailsMock getSupportedDeviceOrientations])).andReturn(supportedOrientations);
}

- (void)tearDown {
    [deviceDetailsMock stopMocking];
    
    [[TuneManager currentManager].triggerManager clearMessageDisplayFrequencyDictionary];
    
    [super tearDown];
}

#pragma mark - First Playlist Downloaded Trigger

- (void)testTriggerManagerTriggersFirstPlaylistDownloadedEvent {
    NSMutableDictionary *mutableSlideIn = slideInDictionary.mutableCopy;
    // Set the triggerEvent to the MD5 hash of the First Playlist Downloaded event. (Application|||FirstPlaylistDownloaded|SESSION)
    mutableSlideIn[@"messages"][@"message_id_1"][@"triggerEvent"] = @"c1f8bd652909257485fb70e803d93915";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block BOOL firstPlaylistDownloadedEventTriggeredMessage = NO;
    id slideInFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        firstPlaylistDownloadedEventTriggeredMessage = YES;
    });

    [skyhookCenter postSkyhook:TunePlaylistManagerFirstPlaylistDownloaded object:nil userInfo:@{TunePayloadFirstPlaylistDownloaded: newPlaylist }];
    
    XCTAssertTrue(firstPlaylistDownloadedEventTriggeredMessage);
    
    [slideInFactoryMock stopMocking];
}

#pragma mark - Different Frequencies

- (void)testTriggerManagerTriggersInAppMessageForEveryTimeFrequency {
    // Setup the TriggerManager with out Slide In message
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: slideInPlaylist }];
    
     __block int callCount = 0;
    id slideInFactoryMock = OCMPartialMock(slideInPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    
    for (int i = 0; i < 4; i++) {
        // Post the event that triggers the Slide In message
        [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    }
    
    // Test that the message continues to show even after foreground/background
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    for (int i = 0; i < 4; i++) {
        // Post the event that triggers the Slide In message
        [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    }
    
    XCTAssertEqual(callCount, 8);
    
    [slideInFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersOnlyOnceFrequency {
    NSMutableDictionary *mutableSlideIn = slideInDictionary.mutableCopy;
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"1";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"1";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block int callCount = 0;
    id slideInFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 1);
    
    [slideInFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersXTimesPerSessionFrequency {
    NSMutableDictionary *mutableSlideIn = slideInDictionary.mutableCopy;
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"3";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"scope"] = @"SESSION";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"0";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block int callCount = 0;
    id slideInFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 3);
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 5);
    
    [slideInFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersXTimesAnEventHappensFrequency {
    NSMutableDictionary *mutableSlideIn = slideInDictionary.mutableCopy;
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"2";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"scope"] = @"EVENT";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"0";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block int callCount = 0;
    id slideInFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 2);
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 2);
    
    [slideInFactoryMock stopMocking];
}

- (void)testTriggerManagerTriggersXDaysSinceEventHappensFrequency {
    NSMutableDictionary *mutableSlideIn = slideInDictionary.mutableCopy;
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"limit"] = @"3";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"scope"] = @"DAYS";
    mutableSlideIn[@"messages"][@"message_id_1"][@"displayFrequency"][@"lifetimeMaximum"] = @"0";
    TunePlaylist *newPlaylist = [[TunePlaylist alloc] initWithDictionary:mutableSlideIn];
    
    __block int callCount = 0;
    id slideInFactoryMock = OCMPartialMock(newPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: newPlaylist }];
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 1);
    
    NSDate *threeDaysFromNow = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * 4];
    id nsDateMock = OCMClassMock([NSDate class]);
    OCMStub(ClassMethod([nsDateMock date])).andReturn(threeDaysFromNow);
    
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    
    XCTAssertEqual(callCount, 2);
    
    [nsDateMock stopMocking];
    
    [slideInFactoryMock stopMocking];
}

- (void)testDontShowIfNotAllImagesDownloaded {
    // Setup the TriggerManager with out Slide In message
    [skyhookCenter postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:nil userInfo:@{ TunePayloadNewPlaylist: slideInPlaylist }];
    
    __block int callCount = 0;
    id slideInFactoryMock = OCMPartialMock(slideInPlaylist.inAppMessages[@"message_id_1"]);
    OCMStub([slideInFactoryMock buildAndShowMessage]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    OCMStub([slideInFactoryMock hasAllAssets]).andReturn(NO);
    
    for (int i = 0; i < 4; i++) {
        // Post the event that triggers the Slide In message
        [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    }
    
    // Test that the message continues to show even after foreground/background
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    for (int i = 0; i < 4; i++) {
        // Post the event that triggers the Slide In message
        [skyhookCenter postSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent: pageViewEvent }];
    }
    
    XCTAssertEqual(callCount, 0);
    
    [slideInFactoryMock stopMocking];
}

@end
