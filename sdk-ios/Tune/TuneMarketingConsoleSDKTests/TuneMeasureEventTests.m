//
//  TuneMeasureEventTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "TuneAnalyticsEvent.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayload.h"
#import "TuneSkyhookPayloadConstants.h"
#import "Tune+Testing.h"
#import "TuneXCTestCase.h"

@interface TuneMeasureEventTests : TuneXCTestCase {
    TuneEvent* customEventFromSkyhook;
    TuneSkyhookCenter *skyhookCenter;
}

@end

@implementation TuneMeasureEventTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    skyhookCenter = [TuneSkyhookCenter defaultCenter];
}

- (void)tearDown {
    waitForQueuesToFinish();
    
    customEventFromSkyhook = nil;
    
    [skyhookCenter removeObserver:self];
    
    [super tearDown];
}

- (void)testMeasureEventPostsCustomEventSkyhook {
    
    NSLog(@"[TuneSkyhookCenter defaultCenter]: %@", [TuneSkyhookCenter defaultCenter]);
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(setCustomEventSkyhook:)
                                              name:TuneCustomEventOccurred
                                            object:nil];
    
    [Tune measureEventName:@"TestingCustomEventSkyhook"];
    
    [skyhookCenter startSkyhookQueue];
    
    // Need to wait due to operation queue.
    [Tune waitUntilAllOperationsAreFinishedOnQueue];
    [skyhookCenter waitTilQueueFinishes];
    
    XCTAssertNotNil(customEventFromSkyhook);
    XCTAssertEqual(@"TestingCustomEventSkyhook", customEventFromSkyhook.eventName);
}

-(void)setCustomEventSkyhook:(TuneSkyhookPayload*)payload {
    customEventFromSkyhook = [payload userInfo][TunePayloadCustomEvent];
}

@end
