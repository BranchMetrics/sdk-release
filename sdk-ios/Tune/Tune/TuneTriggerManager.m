//
//  TuneTriggerManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneTriggerManager.h"
#import "TuneConfiguration.h"
#import "TuneSkyhookCenter.h"
#import "TunePlaylist.h"
#import "TuneMessageDisplayFrequency.h"
#import "TuneManager.h"
#import "TuneAnalyticsConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneAnalyticsEvent.h"
#import "TuneState.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"

static NSString *MessageDisplayFrequencyDictionaryKey = @"tune-message-display-frequency";

@implementation TuneTriggerManager

#pragma mark - Initialization

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    if (self) {
        [self initTriggers];
        [self restoreMessageDisplayFrequencyDictionary];
    }
    return self;
}

-(void)bringUp {
    [self registerSkyhooks];
    [self handleSessionStarted:nil];
}

-(void)bringDown{
    [self unregisterSkyhooks];
}

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleTrackedEvent:)
                                              name:TuneEventTracked
                                            object:nil
                                          priority:TuneSkyhookPriorityFirst];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleFirstPlaylistDownloaded:)
                                              name:TunePlaylistManagerFirstPlaylistDownloaded
                                            object:nil
                                          priority:TuneSkyhookPriorityFirst];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleCurrentPlaylistUpdated:)
                                              name:TunePlaylistManagerCurrentPlaylistChanged
                                            object:nil
                                          priority:TuneSkyhookPriorityFirst];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleSessionStarted:)
                                              name:TuneSessionManagerSessionDidStart
                                            object:nil
                                          priority:TuneSkyhookPriorityFirst];
    
    
}

- (void)initTriggers {
    self.messageTriggers = [[NSMutableDictionary alloc] init];
}

- (void)triggerMessage:(TuneBaseMessageFactory *)inAppMessage fromEvent:(NSString *)event {
    @synchronized(self) {
        (self.messageTriggers)[event] = inAppMessage;
    }
}

#pragma mark - Skyhook Handlers

- (void)handleSessionStarted:(TuneSkyhookPayload *)payload {
    
    [_messageDisplayFrequencyDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *messageID, TuneMessageDisplayFrequency *frequencyModel, BOOL *stop) {
        frequencyModel.numberOfTimesShownThisSession = 0;
    }];
    [self storeMessageDisplayFrequencyDictionary];
}

- (void)handleTrackedEvent:(TuneSkyhookPayload *)payload {
    TuneAnalyticsEvent *event = (TuneAnalyticsEvent *)[payload userInfo][TunePayloadTrackedEvent];
    if (event) {
        [self eventOccured:event];
    }
}

- (void)handleFirstPlaylistDownloaded:(TuneSkyhookPayload *)payload {
    TunePlaylist *playlist = [payload userInfo][TunePayloadFirstPlaylistDownloaded];
    [self updateTriggersWithPlaylist:playlist];
    
    // Create first Playlist Downloaded Event for tracking purposes
    // This message is not tracked, it's only used to trigger events off of
    TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_SESSION
                                                                       action:TUNE_EVENT_ACTION_FIRST_PLAYLIST_DOWNLOADED
                                                                     category:TUNE_EVENT_CATEGORY_APPLICATION
                                                                      control:nil
                                                                 controlEvent:nil
                                                                         tags:nil
                                                                        items:nil];
    
    // Tell the trigger tracker about the first download for this session
    [self eventOccured:event];
}

- (void)handleCurrentPlaylistUpdated:(TuneSkyhookPayload *)payload {
    TunePlaylist *playlist = [payload userInfo][TunePayloadNewPlaylist];
    [self updateTriggersWithPlaylist:playlist];
}

- (void)updateTriggersWithPlaylist:(TunePlaylist *)playlist {
    // remove all the triggers
    [self initTriggers];
    
    // add the new triggers from the playlist
    [playlist.inAppMessages enumerateKeysAndObjectsUsingBlock:^(NSString *ignored, TuneBaseMessageFactory *inAppMessage, BOOL *stop) {
        NSString *triggerEvent = [inAppMessage getTriggerEvent];
        
        if ( (triggerEvent) && ([triggerEvent length] > 0) && (inAppMessage != nil) ) {
            [self triggerMessage:inAppMessage fromEvent:triggerEvent];
        }
    }];
}

- (void)eventOccured:(TuneAnalyticsEvent *)event {
    if ([TuneState isTMADisabled]) { return; }
    
    if(self.tuneManager.configuration.echoFiveline) {
        NSLog(@"TUNE SDK - Event Tracked -- Fiveline: %@ MD5: %@", [event getFiveline], [event getEventMd5]);
    }
    
    if ( (event) && ((self.messageTriggers)[[event getEventMd5]]) ) {
        // Even if we have a message to show, if they are 13 or younger don't show it.
        if ([self.tuneManager.userProfile tooYoungForTargetedAds]) {
            return;
        }
        @synchronized(self) {
            // Need to make sure this message is created on the main thread
            TuneBaseMessageFactory *previouslyShownMessage = self.messageToShow;
            
            self.messageToShow = (self.messageTriggers)[[event getEventMd5]];
            [self markEventTriggeredForMessage:self.messageToShow];
            
            if ([self shouldShowMessage:self.messageToShow] && [self.messageToShow hasAllAssets]) {
                
                [self markMessageShown:self.messageToShow];
                
                if (previouslyShownMessage) {
                    [previouslyShownMessage dismissMessage];
                }
                
                [self performSelectorOnMainThread:@selector(showMessageOnMainThread:)
                                       withObject:self.messageToShow
                                    waitUntilDone:YES];
            } else {
                self.messageToShow = previouslyShownMessage;
            }
        }
    }
}

- (void)showMessageOnMainThread:(TuneBaseMessageFactory *)message {
    [message buildAndShowMessage];
}


#pragma mark - Message Display Frequency methods

- (BOOL)shouldShowMessage:(TuneBaseMessageFactory *)message {
    TuneMessageDisplayFrequency *frequencyModel = [self getFrequencyModelForMessage:message];
    return [message shouldDisplayBasedOnFrequencyModel:frequencyModel];
}

- (void)markMessageShown:(TuneBaseMessageFactory *)message {
    TuneMessageDisplayFrequency *frequencyModel = [self getFrequencyModelForMessage:message];
    frequencyModel.eventsSeenSinceShown = 0;
    frequencyModel.lastShownDateTime = [NSDate date];
    frequencyModel.lifetimeShownCount++;
    frequencyModel.numberOfTimesShownThisSession++;
    [self updateFrequencyModel:frequencyModel];
}

- (TuneMessageDisplayFrequency *)getFrequencyModelForMessage:(TuneBaseMessageFactory *)message {
    TuneMessageDisplayFrequency *frequencyModel = _messageDisplayFrequencyDictionary[message.campaign.campaignId];
    if (!frequencyModel) {
        frequencyModel = [[TuneMessageDisplayFrequency alloc] initWithCampaignID:message.campaign.campaignId eventMD5:[message getTriggerEvent]];
    }
    return frequencyModel;
}

- (void)markEventTriggeredForMessage:(TuneBaseMessageFactory *)message {
    TuneMessageDisplayFrequency *frequencyModel = [self getFrequencyModelForMessage:message];
    frequencyModel.eventsSeenSinceShown++;
    [self updateFrequencyModel:frequencyModel];
}

- (void)updateFrequencyModel:(TuneMessageDisplayFrequency *)frequencyModel {
    _messageDisplayFrequencyDictionary[frequencyModel.campaignID] = frequencyModel;
    [self storeMessageDisplayFrequencyDictionary];
}

#pragma mark - Storage of Display Frequency Dictionary

- (void)restoreMessageDisplayFrequencyDictionary {
    NSObject *storedMessageDisplayFrequencyDictionaryArchive = [TuneUserDefaultsUtils userDefaultValueforKey:MessageDisplayFrequencyDictionaryKey];
    
    if (storedMessageDisplayFrequencyDictionaryArchive == nil || [storedMessageDisplayFrequencyDictionaryArchive isKindOfClass:[NSDictionary class]]) {
        _messageDisplayFrequencyDictionary =  [[NSMutableDictionary alloc] init];
    } else {
        _messageDisplayFrequencyDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)storedMessageDisplayFrequencyDictionaryArchive];
        
        if (!_messageDisplayFrequencyDictionary) {
            _messageDisplayFrequencyDictionary = [[NSMutableDictionary alloc] init];
        }
    }
}

- (void)storeMessageDisplayFrequencyDictionary {
    NSData *messageDisplayFrequencyDictionaryArchived = [NSKeyedArchiver archivedDataWithRootObject:_messageDisplayFrequencyDictionary];
    if ([messageDisplayFrequencyDictionaryArchived length] > 5) {
        [TuneUserDefaultsUtils setUserDefaultValue:messageDisplayFrequencyDictionaryArchived forKey:MessageDisplayFrequencyDictionaryKey];
    }
}

#pragma mark - Testing Helpers

- (void)clearMessageDisplayFrequencyDictionary {
    [TuneUserDefaultsUtils clearUserDefaultValue:MessageDisplayFrequencyDictionaryKey];
}

@end
