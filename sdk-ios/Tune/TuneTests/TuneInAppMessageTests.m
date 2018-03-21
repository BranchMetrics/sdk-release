//
//  TuneInAppMessageTests.m
//  TuneTests
//
//  Created by John Gu on 10/6/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneInAppMessageAction.h"
#import "TunePlaylistManager+Testing.h"
#import "TuneManager.h"
#import "DictionaryLoader.h"
#import "SimpleObserver.h"
#import "TuneFileManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneModalMessage.h"
#import "TuneBannerMessage.h"
#import "Tune+Testing.h"
#import "TuneXCTestCase.h"
#import "TuneUtils.h"
#import "TuneTriggerManager+Testing.h"
#import "TuneAnalyticsEvent.h"
#import "TuneAnalyticsConstants.h"
#import "TuneBlankViewController.h"
#import "TuneDeeplink.h"
#import "TuneKeyStrings.h"
#import "TuneNetworkUtils.h"
#import "TuneNotification.h"
#import "TuneUserDefaultsUtils.h"

@interface TuneInAppMessageTests : TuneXCTestCase {
    id playlistMock;
    id playlistInstanceMock;
    
    TuneManager *tuneManager;
    TunePlaylistManager *playlistManager;
    
    NSDictionary *playlistDictionary;
    
    SimpleObserver *simpleObserver;
    
    XCTestExpectation *expectation;
}

@end

@implementation TuneInAppMessageTests

const int EXPECTATION_TIMEOUT = 2;

- (void)setUp {
    [super setUp];
    
    tuneManager = [TuneManager currentManager];
    
    simpleObserver = [[SimpleObserver alloc] init];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests"].mutableCopy;
    
    playlistManager = tuneManager.playlistManager;
}

- (void)tearDown {
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    
    tuneManager = nil;
    simpleObserver = nil;
    [playlistManager unregisterSkyhooks];
    playlistManager = nil;
    
    [playlistMock stopMocking];
    [playlistInstanceMock stopMocking];
    
    [super tearDown];
}

// For monitoring when an in-app message becomes visible
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"visible"]) {
        [expectation fulfill];
    }
}

- (void)testHtmlParsedFromPlaylistMessage {
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];

    TuneBannerMessage *messageFactory = newPlaylist.inAppMessages[@"MESSAGE_ID_1"];
    
    XCTAssertEqual(1, [simpleObserver skyhookPostCount]);
    XCTAssertNotNil([messageFactory html]);
    XCTAssertTrue([@"<html>somehtmlhere</html>" isEqualToString:[messageFactory html]]);
}

- (void)testActionsParsedFromPlaylistMessage {
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    TuneBannerMessage *messageFactory = newPlaylist.inAppMessages[@"MESSAGE_ID_1"];
    
    XCTAssertEqual(1, [simpleObserver skyhookPostCount]);
    XCTAssertNotNil([messageFactory tuneActions]);
    
    NSMutableDictionary *expectedActions = [[NSMutableDictionary alloc] init];
    
    TuneInAppMessageAction *action1 = [[TuneInAppMessageAction alloc] init];
    action1.actionName = @"add";
    action1.url = @"somedeeplink";
    action1.type = TuneActionTypeDeeplink;
    
    TuneInAppMessageAction *action2 = [[TuneInAppMessageAction alloc] init];
    action2.actionName = @"enable";
    action2.url = @"somedeeplink2";
    action2.type = TuneActionTypeDeeplink;
    
    [expectedActions setObject:action1 forKey:@"add"];
    [expectedActions setObject:action2 forKey:@"enable"];
    
    XCTAssertTrue([[expectedActions description] isEqualToString:[[messageFactory tuneActions] description]]);
}

- (void)testWidthAndHeightParsedFromModalPlaylistMessage {
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    TuneModalMessage *messageFactory = newPlaylist.inAppMessages[@"MESSAGE_ID_4"];
    
    NSNumber *expectedWidth = @200;
    NSNumber *expectedHeight = @500;
    
    XCTAssertEqual(1, [simpleObserver skyhookPostCount]);
    XCTAssertEqual([expectedWidth intValue], [[messageFactory width] intValue]);
    XCTAssertEqual([expectedHeight intValue], [[messageFactory height] intValue]);
}

- (void)testDurationAndLocationTypeParsedFromBannerPlaylistMessage {
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    TuneBannerMessage *messageFactory = newPlaylist.inAppMessages[@"MESSAGE_ID_1"];
    
    XCTAssertEqual(1, [simpleObserver skyhookPostCount]);
    XCTAssertEqual(5, [[messageFactory duration] intValue]);
    XCTAssertEqual(TuneMessageLocationBottom, [messageFactory messageLocationType]);
}

#pragma mark Public API methods

//- (void)testMessageGetterByTriggerEvents {
//    NSDictionary *inAppMessages = [Tune getInAppMessagesByTriggerEvents];
//    XCTAssertEqual(0, [inAppMessages count]);
//
//    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
//    newPlaylist.fromDisk = NO;
//    newPlaylist.fromConnectedMode = NO;
//
//    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
//
//    inAppMessages = [Tune getInAppMessagesByTriggerEvents];
//    XCTAssertEqual(3, [inAppMessages count]);
//
//    XCTAssertNotNil([inAppMessages objectForKey:@"2e5ce41a94e99253ee47faf1b29f053b"]);
//    XCTAssertNotNil([inAppMessages objectForKey:@"551a45c7c768d7c5ae64a900ab967a58"]);
//    XCTAssertNotNil([inAppMessages objectForKey:@"2fd13866603b25d4981a4c00b50e08e9"]);
//}
//
//- (void)testMessageGetterForStartsApp {
//    NSArray *inAppMessages = [Tune getInAppMessagesForStartsApp];
//    XCTAssertEqual(0, [inAppMessages count]);
//
//    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithStartsAppTrigger"].mutableCopy;
//    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
//    newPlaylist.fromDisk = NO;
//    newPlaylist.fromConnectedMode = NO;
//
//    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
//
//    inAppMessages = [Tune getInAppMessagesForStartsApp];
//    XCTAssertEqual(1, [inAppMessages count]);
//
//    TuneInAppMessage *message = inAppMessages[0];
//    XCTAssertTrue([@"MESSAGE_ID_1" isEqualToString:[message messageID]]);
//}
//
//- (void)testMessageGetterForPushOpened {
//    NSArray *inAppMessages = [Tune getInAppMessagesForPushOpened:@"123"];
//    XCTAssertEqual(0, [inAppMessages count]);
//
//    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithPushOpenedTrigger"].mutableCopy;
//    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
//    newPlaylist.fromDisk = NO;
//    newPlaylist.fromConnectedMode = NO;
//
//    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
//
//    inAppMessages = [Tune getInAppMessagesForPushOpened:@"123"];
//    XCTAssertEqual(1, [inAppMessages count]);
//
//    TuneInAppMessage *message = inAppMessages[0];
//    XCTAssertTrue([@"MESSAGE_ID_1" isEqualToString:[message messageID]]);
//}
//
//- (void)testMessageGetterForPushEnabled {
//    NSArray *inAppMessages = [Tune getInAppMessagesForPushEnabled:YES];
//    XCTAssertEqual(0, [inAppMessages count]);
//
//    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithPushEnabledTrigger"].mutableCopy;
//    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
//    newPlaylist.fromDisk = NO;
//    newPlaylist.fromConnectedMode = NO;
//
//    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
//
//    inAppMessages = [Tune getInAppMessagesForPushEnabled:YES];
//    XCTAssertEqual(1, [inAppMessages count]);
//
//    TuneInAppMessage *message = inAppMessages[0];
//    XCTAssertTrue([@"MESSAGE_ID_1" isEqualToString:[message messageID]]);
//}

#pragma mark Triggering Tests

- (void)testMessageTriggeredByCustomEvent {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a trigger event
    TuneEvent *triggerEvent = [TuneEvent eventWithName:@"triggerFullscreen"];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent:triggerEvent }];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageTriggeredByStartsApp {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithStartsAppTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a Starts App event to trigger message
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistManagerFirstPlaylistDownloaded object:self userInfo:@{ TunePayloadFirstPlaylistDownloaded:newPlaylist }];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageTriggeredByDeeplinkOpened {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithDeeplinkOpenedTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a Deeplink Opened event to trigger message
    TuneDeeplink *deeplink = [[TuneDeeplink alloc] initWithNSURL:[NSURL URLWithString:@"test://deeplink"]];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneAppOpenedFromURL object:nil userInfo:@{TunePayloadDeeplink:deeplink}];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageTriggeredByPushOpened {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithPushOpenedTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a Push Opened event to trigger message
    TuneNotification *tuneNotification = [[TuneNotification alloc] init];
    tuneNotification.analyticsReportingAction = TUNE_EVENT_ACTION_NOTIFICATION_OPENED;
    tuneNotification.tunePushID = @"123";
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification : tuneNotification}];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageTriggeredByPushDisabled {
    [TuneUserDefaultsUtils setUserDefaultValue:@YES forKey:TUNE_KEY_PUSH_ENABLED_STATUS];

    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithPushDisabledTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;

    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];

    // deviceToken set is async on main because it relies on UIApplication
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneRegisteredForRemoteNotificationsWithDeviceToken object:self userInfo:@{@"deviceToken" : @"123"}];

    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    __block TuneInAppMessage *message;
    
    // wait for main to finish up setting deviceToken before trying to look at messages
    dispatch_async(dispatch_get_main_queue(), ^{

        // Check that the message that should be triggered is now visible
        message = [TuneManager currentManager].triggerManager.messageToShow;
        
        // Add an observer on message visible property
        [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    });
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageTriggeredByScreenViewed {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithScreenViewedTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a Screen Viewed event to trigger message
    TuneBlankViewController *viewController = [[TuneBlankViewController alloc] init];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneViewControllerAppeared object:viewController];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageNotTriggeredByWrongTriggerEvent {
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithScreenViewedTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a Push Opened event which should NOT trigger message
    TuneNotification *tuneNotification = [[TuneNotification alloc] init];
    tuneNotification.analyticsReportingAction = TUNE_EVENT_ACTION_NOTIFICATION_OPENED;
    tuneNotification.tunePushID = @"123";
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification : tuneNotification}];
    
    // Check that the message that should not be triggered is not visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    XCTAssertTrue([message.visibleViews count] == 0);
}

- (void)testMessageFromPriorDeeplinkOpenIsTriggeredOnPlaylistDownload {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];

    // Mock a Deeplink Opened event
    TuneDeeplink *deeplink = [[TuneDeeplink alloc] initWithNSURL:[NSURL URLWithString:@"test://deeplink"]];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneAppOpenedFromURL object:nil userInfo:@{TunePayloadDeeplink:deeplink}];
    
    // Check that no message was triggered, since we haven't received a playlist yet
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    XCTAssertTrue([message.visibleViews count] == 0);
    
    // Load the mock playlist
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithDeeplinkOpenedTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Check that the message that could have been triggered earlier is now visible
    message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testMessageFromPriorPushOpenIsTriggeredOnPlaylistDownload {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    // Mock a Push Opened event
    TuneNotification *tuneNotification = [[TuneNotification alloc] init];
    tuneNotification.analyticsReportingAction = TUNE_EVENT_ACTION_NOTIFICATION_OPENED;
    tuneNotification.tunePushID = @"123";
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification : tuneNotification}];
    
    // Check that no message was triggered, since we haven't received a playlist yet
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    XCTAssertTrue([message.visibleViews count] == 0);
    
    // Load the mock playlist
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneInAppMessageTests_SingleBannerWithPushOpenedTrigger"].mutableCopy;
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Check that the message that could have been triggered earlier is now visible
    message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

# pragma mark Offline Tests

- (void)testMessageNotDisplayedIfDeviceOffline {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock the network reachability call to return false
    __block BOOL forcedNetworkStatus = NO;
    id classMockTuneNetworkUtils = OCMClassMock([TuneNetworkUtils class]);
    OCMStub(ClassMethod([classMockTuneNetworkUtils isNetworkReachable])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedNetworkStatus];
    });
    
    // Mock a trigger event
    TuneEvent *triggerEvent = [TuneEvent eventWithName:@"triggerFullscreen"];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent:triggerEvent }];
    
    // Check that the message that should be triggered is not visible, because device is offline
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    XCTAssertTrue([message.visibleViews count] == 0);
    
    // Turn mock network back on
    forcedNetworkStatus = YES;
    
    // Mock a trigger event again
    triggerEvent = [TuneEvent eventWithName:@"triggerFullscreen"];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent:triggerEvent }];
    
    // Check that the message that should be triggered is now visible, because device is online again
    message = [TuneManager currentManager].triggerManager.messageToShow;

    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];

    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

#pragma mark Connected Mode Tests

- (void)testMessageDisplayedImmediatelyInConnectedMode {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = YES;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
}

- (void)testPreviousMessageGetsDismissedInConnectedMode {
    expectation = [self expectationWithDescription:@"Waiting for message to display"];
    
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = NO;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Mock a trigger event
    TuneEvent *triggerEvent = [TuneEvent eventWithName:@"triggerFullscreen"];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent:triggerEvent }];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *message = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [message addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([message.visibleViews count] > 0);
    [message removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
    
    expectation = [self expectationWithDescription:@"Waiting for connected message to display"];
    
    // Now download a connected mode playlist
    newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    newPlaylist.fromDisk = NO;
    newPlaylist.fromConnectedMode = YES;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistUpdatePlaylist object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistUpdatePlaylist object:newPlaylist userInfo:nil];
    
    // Check that the message that should be triggered is now visible
    TuneInAppMessage *connectedMessage = [TuneManager currentManager].triggerManager.messageToShow;
    
    // Add an observer on message visible property
    [connectedMessage addObserver:self forKeyPath:NSStringFromSelector(@selector(visible)) options:0 context:nil];
    // Wait for message visible status to change
    [self waitForExpectationsWithTimeout:EXPECTATION_TIMEOUT handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    XCTAssertTrue([connectedMessage.visibleViews count] > 0);
    [connectedMessage removeObserver:self forKeyPath:NSStringFromSelector(@selector(visible))];
    
    // Check that previous message was dismissed
    XCTAssertTrue([message.visibleViews count] == 0);
}

@end
