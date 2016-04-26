//
//  TuneFileManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneManager.h"
#import "TuneConfiguration.h"
#import "DictionaryLoader.h"

@interface TuneFileManagerTests : XCTestCase
{
    NSString *directoryPath;
    NSString *remoteConfigPath;
    NSString *localConfigPath;
    NSString *playlistPath;
    NSString *analyticsPath;
    
    TuneFileManager *fileManager;
    TuneConfiguration *configuration;
}
@end

@implementation TuneFileManagerTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    configuration = [[TuneConfiguration alloc] initWithTuneManager:[TuneManager currentManager]];
    [TuneManager currentManager].configuration = configuration;
    pointMAUrlsToNothing();
    
    NSSearchPathDirectory queueParentFolder = NSDocumentDirectory;
#if TARGET_OS_TV // || TARGET_OS_WATCH
    queueParentFolder = NSCachesDirectory;
#endif
    NSArray *paths = NSSearchPathForDirectoriesInDomains(queueParentFolder, NSUserDomainMask, YES);
    
    directoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"tune"];
    remoteConfigPath = [directoryPath stringByAppendingPathComponent:@"tune_remote_config.plist"];
    localConfigPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TuneConfiguration" ofType:@"plist"];
    analyticsPath = [directoryPath stringByAppendingPathComponent:@"tune_analytics.plist"];
    playlistPath = [directoryPath stringByAppendingPathComponent:@"tune_playlist.plist"];
}

- (void)tearDown {
    [super tearDown];
}

# pragma mark - Analytics File Mgmt

- (void)testLoadAnalyticsFromDiskWhenNoneExists {
    [TuneFileUtils deleteFileOrDirectory: analyticsPath];
    NSDictionary *analytics = [TuneFileManager loadAnalyticsFromDisk];
    
    XCTAssertNil(analytics);
}

- (void)testLoadAnalyticsFromDiskWhenItExists {
    NSDictionary *testAnalytics = @{ @"a1" : @"{ json: \"string\", json2: intvalue }",
                                     @"a2" : @"{ json: \"string\", json2: intvalue }"
                                     };
    
    [TuneFileUtils deleteFileOrDirectory: directoryPath];
    [TuneFileManager saveAnalyticsToDisk:testAnalytics];
    NSDictionary *saveDictionary = [TuneFileManager loadAnalyticsFromDisk];
    
    XCTAssertTrue([[saveDictionary description] isEqualToString:[testAnalytics description]]);
}

- (void)testSaveAnalyticsToDiskNoDirectory {
    NSDictionary *testDictionary = @{ @"a1" : @"{ json: \"string\", json2: intvalue }",
                                      @"a2" : @"{ json: \"string\", json2: intvalue }"
                                      };
    
    [TuneFileUtils deleteFileOrDirectory: directoryPath];
    [TuneFileManager saveAnalyticsToDisk:testDictionary];
    
    XCTAssertTrue([TuneFileUtils fileExists:analyticsPath]);
}

- (void)testSaveAnalyticsToDiskWithDirectory {
    NSDictionary *testDictionary = @{ @"a1" : @"{ json: \"string\", json2: intvalue }",
                                      @"a2" : @"{ json: \"string\", json2: intvalue }"
                                      };
    
    [TuneFileUtils deleteFileOrDirectory: analyticsPath];
    [TuneFileManager saveAnalyticsToDisk:testDictionary];
    
    XCTAssertTrue([TuneFileUtils fileExists:analyticsPath]);
}

- (void)testSaveAnalyticsEventToDisk {
    NSDictionary *startingDictionary = @{ @"1439486620-a" : @"{ json: \"string\", json2: intvalue }",
                                      @"1439486759-b" : @"{ json: \"string1\", json2: intvalue2 }",
                                      @"1439486810-c" : @"{ json: \"string2\", json2: intvalue3 }"
                                    };
    
    NSString *testJSON = @"{ json: \"string3\", json2: intvalue4 }";
    NSString *eventId = @"1439486999-d";
    
    NSDictionary *expectedOutput = @{ @"1439486620-a" : @"{ json: \"string\", json2: intvalue }",
                                      @"1439486759-b" : @"{ json: \"string1\", json2: intvalue2 }",
                                      @"1439486810-c" : @"{ json: \"string2\", json2: intvalue3 }",
                                      @"1439486999-d" : @"{ json: \"string3\", json2: intvalue4 }"
                                    };
    
    [TuneFileUtils deleteFileOrDirectory: analyticsPath];
    
    [TuneFileManager saveAnalyticsToDisk:startingDictionary];
    [TuneFileManager saveAnalyticsEventToDisk:testJSON withId:eventId];
    
    NSDictionary *retrievedDictionary = [TuneFileManager loadAnalyticsFromDisk];
    
    XCTAssertTrue([[retrievedDictionary description] isEqualToString:[expectedOutput description]]);
}

- (void)testSaveAnalyticsEventToDiskWhenEmpty {
    NSString *testJSON = @"{ json: \"string3\", json2: intvalue4 }";
    NSString *eventId = @"1439486999-d";
    
    NSDictionary *expectedOutput = @{@"1439486999-d" : @"{ json: \"string3\", json2: intvalue4 }"};
    
    [TuneFileUtils deleteFileOrDirectory: analyticsPath];
    [TuneFileManager saveAnalyticsEventToDisk:testJSON withId:eventId];
    
    NSDictionary *retrievedDictionary = [TuneFileManager loadAnalyticsFromDisk];
    
    XCTAssertTrue([[retrievedDictionary description] isEqualToString:[expectedOutput description]]);
}

- (void)testSaveAnalyticsEventToDiskWhenFull {
    [[TuneManager currentManager].configuration setAnalyticsMessageStorageLimit:[NSNumber numberWithInt:12]];
    
    NSDictionary *startingDictionary = @{ @"1439486620-a" : @"{ json: \"string1\", json2: intvalue }",
                                      @"1439486759-b" : @"{ json: \"string2\", json2: intvalue2 }",
                                      @"1439486810-c" : @"{ json: \"string3\", json2: intvalue3 }",
                                      @"1439486999-d" : @"{ json: \"string4\", json2: intvalue4 }",
                                      @"1439487620-e" : @"{ json: \"string5\", json2: intvalue5 }",
                                      @"1439487759-f" : @"{ json: \"string6\", json2: intvalue6 }",
                                      @"1439487810-g" : @"{ json: \"string7\", json2: intvalue7 }",
                                      @"1439487999-h" : @"{ json: \"string8\", json2: intvalue8 }",
                                      @"1439488620-i" : @"{ json: \"string9\", json2: intvalue9 }",
                                      @"1439488759-j" : @"{ json: \"string10\", json2: intvalue10 }",
                                      @"1439488810-k" : @"{ json: \"string11\", json2: intvalue11 }",
                                      @"1439488999-l" : @"{ json: \"string12\", json2: intvalue12 }"
                                      };
    
    NSString *testJSON = @"{ json: \"string13\", json2: intvalue13 }";
    NSString *eventId = @"1439489999-d";
    
    NSDictionary *expectedOutput = @{
                                      @"1439488810-k" : @"{ json: \"string11\", json2: intvalue11 }",
                                      @"1439488999-l" : @"{ json: \"string12\", json2: intvalue12 }",
                                      @"1439489999-d" : @"{ json: \"string13\", json2: intvalue13 }"
                                    };
    
    [TuneFileUtils deleteFileOrDirectory: analyticsPath];
    [TuneFileManager saveAnalyticsToDisk:startingDictionary];
    [TuneFileManager saveAnalyticsEventToDisk:testJSON withId:eventId];
    
    NSDictionary *retrievedDictionary = [TuneFileManager loadAnalyticsFromDisk];
    
    // Should see that we're now at 13 saved messages ( > than 12, set as the analyticsMessageStorageLimit )
    // Should then delete out the 10 oldest (based off of an alphabetical sort of the keys)
    
    XCTAssertTrue([[retrievedDictionary description] isEqualToString:[expectedOutput description]]);
}

- (void)testDeleteAnalyticsEventsFromDisk {
    NSDictionary *startingDictionary = @{ @"1439486620-a" : @"{ json: \"string1\", json2: intvalue }",
                                          @"1439486759-b" : @"{ json: \"string2\", json2: intvalue2 }",
                                          @"1439486810-c" : @"{ json: \"string3\", json2: intvalue3 }",
                                          @"1439486999-d" : @"{ json: \"string4\", json2: intvalue4 }",
                                          @"1439487620-e" : @"{ json: \"string5\", json2: intvalue5 }"
                                          };
    
    NSArray *keysToDelete = @[@"1439486620-a", @"1439486759-b", @"1439486999-d"];
    
    NSDictionary *expectedOutput = @{
                                     @"1439486810-c" : @"{ json: \"string3\", json2: intvalue3 }",
                                     @"1439487620-e" : @"{ json: \"string5\", json2: intvalue5 }"
                                     };
    
    [TuneFileUtils deleteFileOrDirectory: analyticsPath];
    [TuneFileManager saveAnalyticsToDisk:startingDictionary];
    [TuneFileManager deleteAnalyticsEventsFromDisk:keysToDelete];
    
    NSDictionary *retrievedDictionary = [TuneFileManager loadAnalyticsFromDisk];
    
    XCTAssertTrue([[retrievedDictionary description] isEqualToString:[expectedOutput description]], @"Actually: %@", [retrievedDictionary description]);
}


- (void)testDeleteAnalyticsFromDisk {
    NSDictionary *testDictionary = @{ @"a1" : @"{ json: \"string\", json2: intvalue }",
                                      @"a2" : @"{ json: \"string\", json2: intvalue }"
                                      };
    
    [TuneFileManager saveRemoteConfigurationToDisk:testDictionary];
    [TuneFileManager deleteAnalyticsFromDisk];
    
    XCTAssertFalse([TuneFileUtils fileExists:analyticsPath]);
}

# pragma mark - Remote Config File Mgmt

- (void)testLoadConfigurationFromDiskWhenNoneExists {
    [TuneFileUtils deleteFileOrDirectory: remoteConfigPath];
    NSDictionary *config = [TuneFileManager loadRemoteConfigurationFromDisk];
    
    XCTAssertNil(config);
}

- (void)testLoadConfigurationFromDiskWhenItExists {
    NSDictionary *testDictionary = @{ @"test1" : @"value1",
                                      @"test2" : @"value2"
                                      };
    
    [TuneFileManager saveRemoteConfigurationToDisk:testDictionary];
    NSDictionary *saveDictionary = [TuneFileManager loadRemoteConfigurationFromDisk];
    
    XCTAssertEqualObjects([saveDictionary description], [testDictionary description]);
}

- (void)testSaveConfigurationToDiskNoDirectory {
    NSDictionary *testDictionary = @{ @"test1" : @"value1",
                                      @"test2" : @"value2"
                                      };
    
    [TuneFileUtils deleteFileOrDirectory: directoryPath];
    [TuneFileManager saveRemoteConfigurationToDisk:testDictionary];
    
    XCTAssertTrue([TuneFileUtils fileExists:remoteConfigPath]);
}

- (void)testSaveConfigurationToDiskWithDirectory {
    NSDictionary *testDictionary = @{ @"test1" : @"value1",
                                      @"test2" : @"value2"
                                      };
    
    [TuneFileUtils deleteFileOrDirectory: remoteConfigPath];
    [TuneFileManager saveRemoteConfigurationToDisk:testDictionary];
    
    XCTAssertTrue([TuneFileUtils fileExists:remoteConfigPath]);
}

- (void)testDeleteConfigurationFromDisk {
    NSDictionary *testDictionary = @{ @"test1" : @"value1",
                                      @"test2" : @"value2"
                                      };
    
    [TuneFileManager saveRemoteConfigurationToDisk:testDictionary];
    [TuneFileManager deleteRemoteConfigurationFromDisk];
    
    XCTAssertFalse([TuneFileUtils fileExists:remoteConfigPath]);
}

#pragma mark - Local Config File Tests

- (void)testLoadLocalConfigurationFromDiskWhenNoneExists {
    [TuneFileUtils deleteFileOrDirectory: localConfigPath];
    NSDictionary *config = [TuneFileManager loadLocalConfigurationFromDisk];
    
    XCTAssertNil(config);
}

- (void)testLoadLocalConfigurationFromDiskWhenItExists {
    // NOTE: These contents are stored in TuneConfiguration.plist in the Resources folder
    NSDictionary *knownDictionary = @{ @"AppDelegateClassName": @"TuneBlankAppDelegate",
                                       @"DisabledClasses": @[ @"DisabledInPlist" ] };
    
    NSDictionary *loadedDictionary = [TuneFileManager loadLocalConfigurationFromDisk];
    
    XCTAssertEqualObjects([loadedDictionary description], [knownDictionary description]);
}

#pragma mark - Playlist File Tests


- (void)testLoadPlaylistFromDiskWhenNoneExists {
    [TuneFileUtils deleteFileOrDirectory: playlistPath];
    
    NSDictionary *playlist = [TuneFileManager loadPlaylistFromDisk];
    
    XCTAssertNil(playlist);
}

- (void)testLoadPlaylistFromDiskWhenItExists {
    NSDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"];
    TunePlaylist *testPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    
    [TuneFileManager savePlaylistToDisk:testPlaylist];
    NSDictionary *savedDictionary = [TuneFileManager loadPlaylistFromDisk];
    
    XCTAssertEqualObjects([savedDictionary description], [playlistDictionary description]);
}

- (void)testSavePlaylistToDiskNoDirectory {
    NSDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"];
    TunePlaylist *testPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    
    [TuneFileUtils deleteFileOrDirectory: directoryPath];
    [TuneFileManager savePlaylistToDisk:testPlaylist];
    
    XCTAssertTrue([TuneFileUtils fileExists:playlistPath]);
}

- (void)testSavePlaylistToDiskWithDirectory {
    NSDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"];
    TunePlaylist *testPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    
    [TuneFileUtils deleteFileOrDirectory:playlistPath];
    [TuneFileManager savePlaylistToDisk:testPlaylist];
    
    XCTAssertTrue([TuneFileUtils fileExists:playlistPath]);
}

- (void)testDeletePlaylistFromDisk {
    NSDictionary *playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"];
    TunePlaylist *testPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
    
    [TuneFileManager savePlaylistToDisk:testPlaylist];
    [TuneFileManager deletePlaylistFromDisk];
    
    XCTAssertFalse([TuneFileUtils fileExists:playlistPath]);
}

@end
