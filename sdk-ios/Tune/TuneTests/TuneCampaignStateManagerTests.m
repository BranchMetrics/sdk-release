//
//  TuneCampaignStateManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TuneCampaignStateManager.h"
#import "TuneSkyhookCenter.h"
#import "SimpleObserver.h"
#import "TuneCampaign.h"
#import "TuneStorageKeys.h"
#import "TuneManager+Testing.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneXCTestCase.h"

@interface TuneCampaignStateManagerTests : TuneXCTestCase {
    TuneCampaignStateManager *campaignStateManager;
    SimpleObserver *simpleObserver;
    TuneSkyhookCenter *skyhookCenter;
}

@end

@implementation TuneCampaignStateManagerTests

- (void)setUp {
    [super setUp];

    // This suite expects nothing else running in the background
    [[TuneManager currentManager] nilModules];
    
    [TuneUserDefaultsUtils clearUserDefaultValue:TuneViewedCampaignsKey];
    
    campaignStateManager = [TuneCampaignStateManager moduleWithTuneManager:[TuneManager currentManager]];
    [campaignStateManager registerSkyhooks];
    
    simpleObserver = [[SimpleObserver alloc] init];
    
    skyhookCenter = [TuneSkyhookCenter defaultCenter];
    [skyhookCenter startSkyhookQueue];
}

- (void)tearDown {
    [skyhookCenter removeObserver:campaignStateManager];
    [skyhookCenter removeObserver:simpleObserver];
    simpleObserver = nil;
    
    [TuneUserDefaultsUtils clearUserDefaultValue:TuneViewedCampaignsKey];
    
    [skyhookCenter stopAndClearSkyhookQueue];
    
    [super tearDown];
}

- (void)testStateManagerOnlyAddsSessionVariablesOnceForEachView {
    [skyhookCenter addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneSessionVariableToSet object:nil];
    
    TuneCampaign *campaign = [[TuneCampaign alloc] initWithCampaignId:@"CAMP_ID" variationId:@"VAR_ID" andNumberOfSecondsToReportAnalytics:@100000];
    [skyhookCenter postSkyhook:TuneCampaignViewed object:nil userInfo:@{ TunePayloadCampaign: campaign }];
    
    // Two more times to test that it only posts the session variables skyhook once per session.
    [skyhookCenter postSkyhook:TuneCampaignViewed object:nil userInfo:@{ TunePayloadCampaign: campaign }];
    [skyhookCenter postSkyhook:TuneCampaignViewed object:nil userInfo:@{ TunePayloadCampaign: campaign }];
    
    XCTAssertEqual(simpleObserver.skyhookPostCount, 2);
}

- (void)testStateManagerAddsSessionVariablesBackOnNewSession {
    [skyhookCenter addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneSessionVariableToSet object:nil];
    XCTAssertEqual(0, simpleObserver.skyhookPostCount);
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart];
    XCTAssertEqual(0, simpleObserver.skyhookPostCount);

    TuneCampaign *campaign = [[TuneCampaign alloc] initWithCampaignId:@"CAMP_ID" variationId:@"VAR_ID" andNumberOfSecondsToReportAnalytics:@100000];
    [skyhookCenter postSkyhook:TuneCampaignViewed object:nil userInfo:@{ TunePayloadCampaign: campaign }];
    
    XCTAssertEqual(simpleObserver.skyhookPostCount, 2);
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart];
    
    XCTAssertEqual(simpleObserver.skyhookPostCount, 4);
}

- (void)testStateManagerStopsAddingCampaignVariablesIfReportingTimeExpires {
    [skyhookCenter addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneSessionVariableToSet object:nil];
    XCTAssertEqual(0, simpleObserver.skyhookPostCount);
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart];
    XCTAssertEqual(0, simpleObserver.skyhookPostCount);
    
    TuneCampaign *campaign = [[TuneCampaign alloc] initWithCampaignId:@"CAMP_ID" variationId:@"VAR_ID" andNumberOfSecondsToReportAnalytics:@1];
    [skyhookCenter postSkyhook:TuneCampaignViewed object:nil userInfo:@{ TunePayloadCampaign: campaign }];
    
    XCTAssertEqual(simpleObserver.skyhookPostCount, 2);
    
    waitFor(1.);
    
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart];
    
    XCTAssertEqual(simpleObserver.skyhookPostCount, 2);
}

@end
