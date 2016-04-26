//
//  TuneFileManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneModule.h"
#import "TunePlaylist.h"

@interface TuneFileManager : NSObject

+ (NSDictionary *)loadAnalyticsFromDisk;
+ (BOOL)saveAnalyticsEventToDisk:(NSString *)eventJSON withId:(NSString *)eventId;
+ (BOOL)saveAnalyticsToDisk: (NSDictionary *)analytics;
+ (BOOL)deleteAnalyticsEventsFromDisk:(NSArray *) eventsToDelete;
+ (BOOL)deleteAnalyticsFromDisk;

+ (NSDictionary *)loadRemoteConfigurationFromDisk;
+ (BOOL)saveRemoteConfigurationToDisk: (NSDictionary*)config;
+ (BOOL)deleteRemoteConfigurationFromDisk;

+ (NSDictionary *)loadPlaylistFromDisk;
+ (BOOL)savePlaylistToDisk:(TunePlaylist *)playlist;
+ (BOOL)deletePlaylistFromDisk;

+ (UIImage *)loadImageFromDiskNamed:(NSString *)name;
+ (BOOL)saveImageData:(NSData *)data toDiskWithName:(NSString *)name;

+ (NSDictionary *)loadLocalConfigurationFromDisk;

@end
