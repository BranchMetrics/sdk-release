//
//  TuneExperimentManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/30/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TunePlaylistManager+Testing.h"
#import "TuneFileManager.h"
#import "DictionaryLoader.h"
#import "Tune+Testing.h"
#import "TunePowerHookExperimentDetails+Internal.h"
#import "TuneInAppMessageExperimentDetails+Internal.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneSkyhookPayload.h"
#import "TuneXCTestCase.h"

@interface TuneExperimentManagerTests : TuneXCTestCase {
    BOOL hasVariation_abc;
    BOOL hasVariation_def;
    id fileManagerMock;
}
@end

@implementation TuneExperimentManagerTests

- (void)setUp {
    [super setUp];

    fileManagerMock = OCMClassMock([TuneFileManager class]);
    OCMStub([fileManagerMock loadPlaylistFromDisk]).andReturn(nil);
    
    hasVariation_abc = NO;
    hasVariation_def = NO;
}

- (void)tearDown {
    [fileManagerMock stopMocking];
    
    [super tearDown];
}

- (void)testPowerHookDetailsUpdateWithPlaylist {
    NSMutableDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneExperimentManagerTests"].mutableCopy;
    TunePlaylist *playlist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:playlist];
    
    NSDictionary *experimentDetails = [Tune getPowerHookVariableExperimentDetails];
    
    XCTAssertTrue(experimentDetails.count == 2, @"Actually: %@", @(experimentDetails.count));
    TunePowerHookExperimentDetails *details = experimentDetails[@"itemsToDisplay"];
    XCTAssertTrue([details.experimentId isEqualToString:@"123"], @"Actually: %@", details.experimentId);
    XCTAssertTrue([details.experimentName isEqualToString:@"Number of Items to Display Experiment"]);
    XCTAssertTrue([details.experimentType isEqualToString:@"power_hook"]);
    XCTAssertTrue([details.currentVariantId isEqualToString:@"abc"]);
    XCTAssertTrue([details.currentVariantName isEqualToString:@"Variation A"]);
    XCTAssertTrue([details.hookId isEqualToString:@"itemsToDisplay"]);
    XCTAssertTrue(details.isRunning);
    
    details = experimentDetails[@"showMainScreen"];
    XCTAssertTrue([details.experimentId isEqualToString:@"456"], @"Actually: %@", details.experimentId);
    XCTAssertTrue([details.experimentName isEqualToString:@"Testing w/ Main screen hidden"]);
    XCTAssertTrue([details.experimentType isEqualToString:@"power_hook"]);
    XCTAssertTrue([details.currentVariantId isEqualToString:@"def"]);
    XCTAssertTrue([details.currentVariantName isEqualToString:@"Variation B"]);
    XCTAssertTrue([details.hookId isEqualToString:@"showMainScreen"]);
    XCTAssertTrue(details.isRunning);
}

- (void)testInAppMessageDetailsUpdateWithPlaylist {
    NSMutableDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneExperimentManagerTests"].mutableCopy;
    TunePlaylist *playlist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:playlist];
    
    NSDictionary *experimentDetails = [Tune getInAppMessageExperimentDetails];
    
    XCTAssertTrue(experimentDetails.count == 1, @"Actually: %@", @(experimentDetails.count));
    TuneInAppMessageExperimentDetails *details = experimentDetails[@"Testing a Message"];
    XCTAssertTrue([details.experimentId isEqualToString:@"789"], @"Actually: %@", details.experimentId);
    XCTAssertTrue([details.experimentName isEqualToString:@"Testing a Message"]);
    XCTAssertTrue([details.experimentType isEqualToString:@"in_app"]);
    XCTAssertTrue([details.currentVariantId isEqualToString:@"foobar"]);
    XCTAssertTrue([details.currentVariantName isEqualToString:@"Variation B"]);
}

- (void)testVariationIdsGottenCorrectly {
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(variationHandler:)
                                              name:TuneSessionVariableToSet
                                            object:nil];
    
    NSMutableDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TuneExperimentManagerTests"].mutableCopy;
    TunePlaylist *playlist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:playlist];
    
    XCTAssertTrue(hasVariation_abc);
    XCTAssertTrue(hasVariation_def);
}

- (void)variationHandler:(TuneSkyhookPayload *)payload {
    NSString *variationId = (NSString *)[payload userInfo][TunePayloadSessionVariableValue];
    
    if ([variationId isEqualToString:@"abc"]) {
        hasVariation_abc = YES;
    } else if ([variationId isEqualToString:@"def"]) {
        hasVariation_def = YES;
    }
}

@end
