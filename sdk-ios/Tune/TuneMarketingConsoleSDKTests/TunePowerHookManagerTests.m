//
//  TunePowerHookManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TunePowerHookManager+Testing.h"
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "DictionaryLoader.h"
#import "TunePlaylist.h"
#import "TunePlaylistManager+Testing.h"
#import "TuneSkyhookCenter.h"
#import "TuneFileManager.h"
#import "TunePowerHookExperimentDetails+Internal.h"
#import "TuneXCTestCase.h"

@interface TunePowerHookManagerTests : TuneXCTestCase
{
    id fileManagerMock;
}
@end

@implementation TunePowerHookManagerTests

- (void)setUp {
    [super setUp];

    fileManagerMock = OCMClassMock([TuneFileManager class]);
    OCMStub([fileManagerMock loadPlaylistFromDisk]).andReturn(nil);
    
    [[TuneManager currentManager].powerHookManager performSelector:@selector(reset)];
}

- (void)tearDown {
    [fileManagerMock stopMocking];
    
    [super tearDown];
}

- (void)testRegisterSingleValuePowerHooks_withBadCharacters {
    [Tune registerHookWithId:@"Hook_$." friendlyName:@"Hook_friendly_bad_character" defaultValue:@"321"];
    NSString *value = [Tune getValueForHookById:@"Hook_$."];
    NSString *value2 = [Tune getValueForHookById:@"Hook___"];
    
    XCTAssertTrue([value isEqualToString:@"321"], @"Actually: %@", value);
    XCTAssertTrue([value2 isEqualToString:@"321"], @"Actually: %@", value2);
}


- (void)testRegisterSingleValuePowerHooks {
    [Tune registerHookWithId:@"Hook_1" friendlyName:@"Hook_friendly_1" defaultValue:@"1" description:@"hook test" approvedValues:@[ @"YES", @"NO"]];
    
    NSString *value = [Tune getValueForHookById:@"Hook_1"];
    
    XCTAssertTrue([value isEqualToString:@"1"], @"Actually: %@", value);
    
    NSDictionary *dict = [TunePowerHookManager getSingleValuePowerHooks];
    NSDictionary *hook1Dict = dict[@"Hook_1"];
    
    XCTAssertNotNil(hook1Dict, @"Hook_1 not found in dictionary");
    
    XCTAssertTrue([hook1Dict[@"default_value"] isEqualToString:@"1"], @"Actually: %@", hook1Dict[@"default_value"]);
    
    XCTAssertTrue([hook1Dict[@"friendly_name"] isEqualToString:@"Hook_friendly_1"], @"Actually: %@", hook1Dict[@"friendly_name"]);
    
    [Tune setValueForHookById:@"Hook_1" value:@"2"];
    
    value = [Tune getValueForHookById:@"Hook_1"];
    
    XCTAssertTrue([value isEqualToString:@"2"], @"Actually: %@", value);
}

- (void)testRegisterPowerHookWithInvalidApprovedValuesFailsToRegister {
    NSDictionary *currentPowerHooks = [TunePowerHookManager getSingleValuePowerHooks];
    XCTAssertEqual(0 , [currentPowerHooks count]);
    
    // Empty approvedValues
    [Tune registerHookWithId:@"hook" friendlyName:@"hook" defaultValue:@"hook" description:@"hook" approvedValues:@[  ]];
    
    currentPowerHooks = [TunePowerHookManager getSingleValuePowerHooks];
    XCTAssertEqual(0 , [currentPowerHooks count]);
    
    [Tune registerHookWithId:@"hook" friendlyName:@"hook" defaultValue:@"hook" description:@"hook" approvedValues:@[ @1, @"SHRED" ]];
    
    currentPowerHooks = [TunePowerHookManager getSingleValuePowerHooks];
    XCTAssertEqual(0 , [currentPowerHooks count]);
}

- (void)testRegisteringDuplicatePowerHook {
    [Tune registerHookWithId:@"name" friendlyName:@"friendly" defaultValue:@"default"];
    XCTAssertEqual(@"default", [Tune getValueForHookById:@"name"]);
    
    [Tune registerHookWithId:@"name" friendlyName:@"friendly" defaultValue:@"default1"];
    XCTAssertEqual(@"default", [Tune getValueForHookById:@"name"]);
}

#pragma mark - No Power Hooks Tests

- (void)testGetSingleValuePowerHooks {
    NSDictionary *currentDict = [TunePowerHookManager getSingleValuePowerHooks];
    XCTAssertEqual(0 ,[currentDict count], @"Empty playlist should have an empty dictionary of power hooks.");
}

- (void)getPowerHookVariableExperimentDetails {
    NSDictionary *currentDict = [Tune getPowerHookVariableExperimentDetails];
    XCTAssertEqual(0 ,[currentDict count], @"Empty playlist should have an empty dictionary of power hooks experiment details.");
}

#pragma mark - Playlist Change Tests

- (void)testPowerHookValuesLoadedFromDiskApplyBeforeRegistration {
    NSMutableDictionary *newPlaylistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    newPlaylistDictionary[@"power_hooks"][@"couponDiscount"][@"value"] = @"0.99";
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:newPlaylistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:newPlaylist];
    
    XCTAssertTrue([[Tune getValueForHookById:@"couponDiscount"] isEqualToString:@"0.99"]);
}

- (void)testPowerHookValuesLoadedFromDiskApplyBeforeRegistrationAndDontUpdateToRegisteredDefaultValue {
    NSMutableDictionary *newPlaylistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    newPlaylistDictionary[@"power_hooks"][@"couponDiscount"][@"value"] = @"0.99";
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:newPlaylistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:newPlaylist];
    
    XCTAssertTrue([[Tune getValueForHookById:@"couponDiscount"] isEqualToString:@"0.99"]);
    
    [Tune registerHookWithId:@"couponDiscount" friendlyName:@"Friendly" defaultValue:@"0.49"];
    
    XCTAssertTrue([[Tune getValueForHookById:@"couponDiscount"] isEqualToString:@"0.99"]);
}


- (void)testPowerHookValuesChangeOnPlaylistUpdateAndChangeBackOnSecondUpdate {
    [Tune registerHookWithId:@"couponDiscount" friendlyName:@"Friendly" defaultValue:@"0.99"];
    
    XCTAssertTrue([[Tune getValueForHookById:@"couponDiscount"] isEqualToString:@"0.99"]);
    
    NSMutableDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    TunePlaylist *playlist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:playlist];
    
    XCTAssertEqualObjects(@"0.35", [Tune getValueForHookById:@"couponDiscount"]);
    
    NSMutableDictionary *newPlaylistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    newPlaylistDictionary[@"power_hooks"][@"couponDiscount"][@"value"] = @"0.99";
    TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:newPlaylistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:newPlaylist];
    
    XCTAssertEqualObjects(@"0.99", [Tune getValueForHookById:@"couponDiscount"]);
}

#pragma mark - Changed Callbacks

- (void)testRegisteringPowerHookChangedBlockCallsThatBlockOnPowerHookChanged {
    [Tune registerHookWithId:@"couponDiscount" friendlyName:@"Friendly" defaultValue:@"0.99"];
    
    __block BOOL blockCalled = NO;
    [Tune onPowerHooksChanged:^{
        blockCalled = YES;
    }];
    
    NSMutableDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    playlistDictionary[@"power_hooks"][@"couponDiscount"][@"value"] = @"0.89";
    TunePlaylist *playlist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(blockCalled);
    
    // The powerhooks changed callback should happen each time
    blockCalled = NO;
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    playlistDictionary[@"power_hooks"][@"couponDiscount"][@"value"] = @"0.79";
    playlist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    [[TuneManager currentManager].playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(blockCalled);
}

@end
