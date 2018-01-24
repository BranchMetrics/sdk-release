//
//  TunePlaylist.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePlaylist.h"
#import "TuneInAppMessage.h"
#import "TuneSkyhookCenter.h"

NSString *const TunePlaylistExperimentDetailsKey = @"experiment_details";
NSString *const TunePlaylistPowerHooksKey = @"power_hooks";
NSString *const TunePlaylistInAppMessagesKey = @"messages";
NSString *const TunePlaylistSegmentsKey = @"segments";
NSString *const TunePlaylistSchemaVersionKey = @"schema_version";

@implementation TunePlaylist

#pragma mark - Initialization

- (id)init {
    self = [super init];
    self.experimentDetails = [[NSDictionary alloc] init];
    self.powerHooks = [[NSDictionary alloc] init];
    self.inAppMessages = [[NSDictionary alloc] init];
    self.segments = [[NSDictionary alloc] init];
    self.schemaVersion = nil;
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [[TunePlaylist alloc] init];
    if (self) {
        [self setupWithDictionary:dictionary];
    }
    return self;
}

+ (id)playlistWithDictionary:(NSDictionary *)dictionary {
    return [[TunePlaylist alloc] initWithDictionary:dictionary];
}

- (void)setupWithDictionary:(NSDictionary *)playlistDictionary {
    if (playlistDictionary[TunePlaylistSchemaVersionKey]) {
        self.schemaVersion = playlistDictionary[TunePlaylistSchemaVersionKey];
    }
    
    NSMutableDictionary *inAppMessages = [NSMutableDictionary dictionary];
    
    [playlistDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *dictionary, BOOL *stopPlaylist) {
        if ([key isEqualToString:TunePlaylistPowerHooksKey]) {
            self.powerHooks = dictionary;
        } else if ([key isEqualToString:TunePlaylistExperimentDetailsKey]) {
            self.experimentDetails = dictionary;
        } else if ([key isEqualToString:TunePlaylistInAppMessagesKey]) {
            [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *messageID, NSDictionary *messageDictionary, BOOL *stopDict) {
                TuneInAppMessage *messageFactory = [TuneInAppMessage buildMessageFromMessageDictionary:messageDictionary];
                // Do we have a valid factory?
                if (messageFactory) {
                    inAppMessages[messageID] = messageFactory;
                } else {
                    ErrorLog(@"Ignoring Message ID:%@. Unable to create factory.", messageID);
                }
            }];
        } else if ([key isEqualToString:TunePlaylistSegmentsKey]) {
            self.segments = dictionary;
        }
    }];
    
    self.inAppMessages = inAppMessages;
}

#pragma mark - Comparison

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[TunePlaylist class]]) { return NO; }
    
    TunePlaylist *playlist = (TunePlaylist *)object;
    return  [self.experimentDetails isEqualToDictionary:playlist.experimentDetails] &&
            [self.powerHooks isEqualToDictionary:playlist.powerHooks] &&
            [self.inAppMessages isEqualToDictionary:playlist.inAppMessages] &&
            [self.segments isEqualToDictionary:playlist.segments] &&
            [self.schemaVersion isEqualToString:playlist.schemaVersion];
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + [self.experimentDetails hash];
    result = prime * result + [self.powerHooks hash];
    result = prime * result + [self.inAppMessages hash];
    result = prime * result + [self.segments hash];
    result = prime * result + [self.schemaVersion hash];
    
    return result;
}

#pragma mark - To Dictionary

- (NSDictionary *)toDictionary {
    
    NSMutableDictionary *playlist = [NSMutableDictionary dictionary];

    if (self.schemaVersion) {
        playlist[TunePlaylistSchemaVersionKey] = self.schemaVersion ;
    } else {
        playlist[TunePlaylistSchemaVersionKey] = @"1.0";
    }
    
    if (self.powerHooks) {
        playlist[TunePlaylistPowerHooksKey] = self.powerHooks;
    } else {
        playlist[TunePlaylistPowerHooksKey] = @{};
    }
    
    if (self.experimentDetails) {
        playlist[TunePlaylistExperimentDetailsKey] = self.experimentDetails;
    } else {
        playlist[TunePlaylistExperimentDetailsKey] = @{};
    }
    
    if (self.segments) {
        playlist[TunePlaylistSegmentsKey] = self.segments;
    } else {
        playlist[TunePlaylistSegmentsKey] = @{};
    }
    
    NSMutableDictionary *inAppMessageDictionary = [NSMutableDictionary dictionary];
    [self.inAppMessages enumerateKeysAndObjectsUsingBlock:^(NSString *message_id, TuneInAppMessage *message, BOOL *stop) {
        inAppMessageDictionary[message_id] = [message toDictionary];
    }];
    playlist[TunePlaylistInAppMessagesKey] = inAppMessageDictionary;
    
    return playlist;
}

@end
