//
//  TunePlaylist.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const TunePlaylistExperimentDetailsKey;
FOUNDATION_EXPORT NSString *const TunePlaylistPowerHooksKey;
FOUNDATION_EXPORT NSString *const TunePlaylistInAppMessagesKey;
FOUNDATION_EXPORT NSString *const TunePLaylistSegmentsKey;
FOUNDATION_EXPORT NSString *const TunePlaylistSchemaVersionKey;

@interface TunePlaylist : NSObject

@property (nonatomic, copy) NSDictionary *powerHooks;
@property (nonatomic, copy) NSDictionary *inAppMessages;
@property (nonatomic, copy) NSDictionary *experimentDetails;
@property (nonatomic, copy) NSDictionary *segments;
@property (nonatomic, copy) NSString     *schemaVersion;

@property (assign, nonatomic) BOOL retrievingInAppMessageAssets;
@property (assign, nonatomic) BOOL fromDisk;
@property (assign, nonatomic) BOOL fromConnectedMode;

- (id)initWithDictionary:(NSDictionary *)playlist;
+ (id)playlistWithDictionary:(NSDictionary *)playlist;

- (void)retrieveInAppMessageAssets;
- (BOOL)hasAllInAppMessageAssets;

- (NSDictionary *)toDictionary;

@end
