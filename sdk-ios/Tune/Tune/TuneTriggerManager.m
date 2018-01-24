//
//  TuneTriggerManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

@import UIKit;

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
#import "TunePushUtils.h"
#import "TuneKeyStrings.h"
#import "TuneDeeplink.h"
#import "TuneEvent+Internal.h"
#import "TuneStringUtils.h"
#import "TuneNetworkUtils.h"
#import "TuneNotification.h"
#import "UIViewController+TuneAnalytics.h"

static NSString *MessageDisplayFrequencyDictionaryKey = @"tune-message-display-frequency";

@implementation TuneTriggerManager

#pragma mark - Initialization

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    if (self) {
        [self initTriggers];
        [self restoreMessageDisplayFrequencyDictionary];
        
        self.triggerEventsSeenPriorToPlaylistDownload = [[NSMutableSet alloc] init];
        self.firstPlaylistDownloaded = NO;
    }
    return self;
}

-(void)bringUp {
    [self registerSkyhooks];
    [self handleSessionStarted:nil];
}

-(void)bringDown {
    [self unregisterSkyhooks];
}

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleCustomEvent:)
                                              name:TuneCustomEventOccurred
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
    
    // Listen for screen views
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleViewControllerAppeared:)
                                              name:TuneViewControllerAppeared
                                            object:nil];
    
    // Listen for deeplink opens
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleAppOpenedFromURL:)
                                              name:TuneAppOpenedFromURL
                                            object:nil];
    
    // Listen for push notifications
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handlePushNotificationOpened:)
                                              name:TunePushNotificationOpened
                                            object:nil];
    
    // Listen for registration of device with APN
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleRemoteNotificationRegistrationUpdated:)
                                              name:TuneRegisteredForRemoteNotificationsWithDeviceToken
                                            object:nil];
    
    // Listen for failure to register device with APN
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleRemoteNotificationRegistrationUpdated:)
                                              name:TuneFailedToRegisterForRemoteNotifications
                                            object:nil];
    
    // Listen for app backgrounds
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleAppBackgrounded:)
                                              name:TuneSessionManagerSessionDidEnd
                                            object:nil];
}

- (void)initTriggers {
    self.inAppMessagesByEvents = [[NSMutableDictionary alloc] init];
}

- (void)triggerMessage:(TuneInAppMessage *)inAppMessage fromEvent:(NSString *)event {
    @synchronized(self) {
        NSMutableArray<TuneInAppMessage *> *messages;
        if (self.inAppMessagesByEvents[event]) {
            messages = self.inAppMessagesByEvents[event];
        } else {
            messages = [[NSMutableArray alloc] init];
        }
        [messages addObject:inAppMessage];
        self.inAppMessagesByEvents[event] = messages;
    }
}

#pragma mark - Skyhook Handlers

- (void)handleSessionStarted:(TuneSkyhookPayload *)payload {
    [_messageDisplayFrequencyDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *messageID, TuneMessageDisplayFrequency *frequencyModel, BOOL *stop) {
        frequencyModel.numberOfTimesShownThisSession = 0;
    }];
    [self storeMessageDisplayFrequencyDictionary];
}

- (void)handleCustomEvent:(TuneSkyhookPayload *)payload {
    TuneEvent *tuneEvent = (TuneEvent *)[payload userInfo][TunePayloadCustomEvent];
    
    NSString *eventAction;
    if (tuneEvent.eventIdObject != nil) {
        eventAction = [tuneEvent.eventIdObject stringValue];
    } else {
        eventAction = tuneEvent.eventName;
    }
    TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithTuneEvent:TUNE_EVENT_TYPE_BASE
                                                                       action:eventAction
                                                                     category:TUNE_EVENT_CATEGORY_CUSTOM
                                                                      control:nil
                                                                 controlEvent:nil
                                                                        event:tuneEvent];
    [self eventOccurred:event];
}

- (void)handleFirstPlaylistDownloaded:(TuneSkyhookPayload *)payload {
    TunePlaylist *playlist = [payload userInfo][TunePayloadFirstPlaylistDownloaded];
    [self updateTriggersWithPlaylist:playlist];
    
    self.firstPlaylistDownloaded = YES;

    // Trigger messages for any deeplink opens or push opens that previously occurred in this session
    if ([self.triggerEventsSeenPriorToPlaylistDownload count] > 0) {
        for (TuneAnalyticsEvent *event in self.triggerEventsSeenPriorToPlaylistDownload) {
            NSArray *messagesForEvent = self.inAppMessagesByEvents[[event getEventMd5]];
            if (messagesForEvent) {
                // Check if message has already been displayed this session
                for (TuneInAppMessage *message in messagesForEvent) {
                    TuneMessageDisplayFrequency *frequency = [self getFrequencyModelForMessage:message];

                    // Only show message if it hasn't been shown this session
                    if ([frequency numberOfTimesShownThisSession] == 0) {
                        [self eventOccurred:event];
                    }
                }
            }
        }
    }
    
    // Create First Playlist Downloaded event
    // This message is not tracked, it's only used to trigger events off of
    TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_SESSION
                                                                       action:TUNE_EVENT_ACTION_FIRST_PLAYLIST_DOWNLOADED
                                                                     category:TUNE_EVENT_CATEGORY_APPLICATION
                                                                      control:nil
                                                                 controlEvent:nil
                                                                         tags:nil
                                                                        items:nil];
    
    // Tell the trigger tracker about the first download for this session
    [self eventOccurred:event];
}

- (void)handleCurrentPlaylistUpdated:(TuneSkyhookPayload *)payload {
    TunePlaylist *playlist = [payload userInfo][TunePayloadNewPlaylist];
    [self updateTriggersWithPlaylist:playlist];
    
    // If we're in connected mode, show the message immediately
    if (playlist.fromConnectedMode) {
        TuneInAppMessage *previouslyShownMessage = self.messageToShow;
        
        if (self.inAppMessagesByEvents.count > 0) {
            // There's only one preview message in the connected playlist, display it
            NSString *eventMd5 = self.inAppMessagesByEvents.allKeys.firstObject;
            TuneInAppMessage *previewMessage = self.inAppMessagesByEvents[eventMd5].firstObject;
            
            self.messageToShow = previewMessage;
            
            if (previouslyShownMessage && previouslyShownMessage.visible) {
                [previouslyShownMessage dismiss];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [previewMessage display];
            });
        }
    }
}

- (void)handleViewControllerAppeared:(TuneSkyhookPayload *)payload {
    UIViewController *viewController = payload.object;
    TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PAGEVIEW
                                                                       action:nil
                                                                     category:viewController.tuneScreenName
                                                                      control:nil
                                                                 controlEvent:nil
                                                                         tags:nil
                                                                        items:nil];
    [self eventOccurred:event];
}

- (void)handleAppOpenedFromURL:(TuneSkyhookPayload *)payload {
    TuneDeeplink *deeplink = (TuneDeeplink *)[payload userInfo][TunePayloadDeeplink];
    
    if (deeplink) {
        NSURL *openedURL = deeplink.url;
        
        // Only keep up to the path of the url for the analytics event
        NSString *reducedUrl = [TuneStringUtils reduceUrlToPath:openedURL];
        
        // Create the deeplink opened event.
        TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithEventType:deeplink.eventType
                                                                           action:TUNE_EVENT_ACTION_DEEPLINK_OPENED
                                                                         category:reducedUrl
                                                                          control:nil
                                                                     controlEvent:nil
                                                                             tags:nil
                                                                            items:nil];
        
        if (!self.firstPlaylistDownloaded) {
            [self.triggerEventsSeenPriorToPlaylistDownload addObject:event];
        }
        
        [self eventOccurred:event];
    }
}

- (void)handlePushNotificationOpened:(TuneSkyhookPayload *)payload {
    // Get additional analytics variables from notification
    TuneNotification *tuneNotification = (TuneNotification *)[payload userInfo][TunePayloadNotification];

    // Get Tune Push ID
    NSString *tunePushId = @"";
    if (tuneNotification.tunePushID) {
        tunePushId = tuneNotification.tunePushID;
    }
    
    // Find the action
    NSString *pushAction = TunePushNotificationOpened;
    if (tuneNotification.analyticsReportingAction) {
        pushAction = tuneNotification.analyticsReportingAction;
    }
    
    // Create the push notification opened event.
    TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PUSH_NOTIFICATION
                                                                       action:pushAction
                                                                     category:tunePushId
                                                                      control:nil
                                                                 controlEvent:nil
                                                                         tags:nil
                                                                        items:nil];
    
    if (!self.firstPlaylistDownloaded) {
        [self.triggerEventsSeenPriorToPlaylistDownload addObject:event];
    }
    
    [self eventOccurred:event];
}

- (void)handleRemoteNotificationRegistrationUpdated:(TuneSkyhookPayload *)payload {
    BOOL newStatus = [TunePushUtils isAlertPushNotificationEnabled];
    
    if (nil != [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_PUSH_ENABLED_STATUS]) {
        BOOL oldStatus = [[TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_PUSH_ENABLED_STATUS] boolValue];
        
        if (oldStatus != newStatus) {
            // Create the push notification registration status changed event.
            NSString *eventAction = newStatus ? TunePushEnabled : TunePushDisabled;
            TuneAnalyticsEvent *event = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_BASE
                                                                               action:eventAction
                                                                             category:TUNE_EVENT_CATEGORY_APPLICATION
                                                                              control:nil
                                                                         controlEvent:nil
                                                                                 tags:nil
                                                                                items:nil];
            [self eventOccurred:event];
        }
    }
}

- (void)handleAppBackgrounded:(TuneSkyhookPayload *)payload {
    self.triggerEventsSeenPriorToPlaylistDownload = [[NSMutableSet alloc] init];
}

- (void)updateTriggersWithPlaylist:(TunePlaylist *)playlist {
    // remove all the triggers
    [self initTriggers];
    
    // add the new triggers from the playlist
    [playlist.inAppMessages enumerateKeysAndObjectsUsingBlock:^(NSString *ignored, TuneInAppMessage *inAppMessage, BOOL *stop) {
        NSString *triggerEvent = inAppMessage.triggerEvent;
        
        if ( (triggerEvent) && ([triggerEvent length] > 0) && (inAppMessage != nil) ) {
            [self triggerMessage:inAppMessage fromEvent:triggerEvent];
        }
    }];
}

- (void)eventOccurred:(TuneAnalyticsEvent *)event {
    if ([TuneState isTMADisabled]) { return; }
    
    if(self.tuneManager.configuration.echoFiveline) {
        NSLog(@"TUNE SDK - Event Tracked -- Fiveline: %@ MD5: %@", [event getFiveline], [event getEventMd5]);
    }
    
    if ( (event) && ((self.inAppMessagesByEvents)[[event getEventMd5]]) ) {
        // If network is not reachable, don't show message
        if (![TuneNetworkUtils isNetworkReachable]) {
            NSLog(@"TUNE SDK - Device Offline -- Cannot display messages");
            return;
        }
        
        // Even if we have a message to show, if they are 13 or younger don't show it.
        if ([self.tuneManager.userProfile tooYoungForTargetedAds]) {
            return;
        }
        
        @synchronized(self) {
            // Need to make sure this message is created on the main thread
            TuneInAppMessage *previouslyShownMessage = self.messageToShow;
            
            // Iterate through the list of messages for this trigger and show each one
            for (TuneInAppMessage *messageToShow in self.inAppMessagesByEvents[[event getEventMd5]]) {
                self.messageToShow = messageToShow;
                [self markEventTriggeredForMessage:self.messageToShow];
    
                if ([self shouldShowMessage:self.messageToShow]) {
                    // If message is currently showing, don't remove it or trigger a new one
                    if (self.messageToShow.visible) {
                        continue;
                    }
                    
                    [self markMessageShown:self.messageToShow];
    
                    if (previouslyShownMessage && previouslyShownMessage.visible) {
                        [previouslyShownMessage dismiss];
                    }
                    
                    // Show message on main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.messageToShow display];
                    });
                } else {
                    self.messageToShow = previouslyShownMessage;
                }
            }
        }
    }
}

#pragma mark - Message Display Frequency methods

- (BOOL)shouldShowMessage:(TuneInAppMessage *)message {
    TuneMessageDisplayFrequency *frequencyModel = [self getFrequencyModelForMessage:message];
    return [message shouldDisplayBasedOnFrequencyModel:frequencyModel];
}

- (void)markMessageShown:(TuneInAppMessage *)message {
    TuneMessageDisplayFrequency *frequencyModel = [self getFrequencyModelForMessage:message];
    frequencyModel.eventsSeenSinceShown = 0;
    frequencyModel.lastShownDateTime = [NSDate date];
    frequencyModel.lifetimeShownCount++;
    frequencyModel.numberOfTimesShownThisSession++;
    [self updateFrequencyModel:frequencyModel];
}

- (TuneMessageDisplayFrequency *)getFrequencyModelForMessage:(TuneInAppMessage *)message {
    TuneMessageDisplayFrequency *frequencyModel = _messageDisplayFrequencyDictionary[message.campaign.campaignId];
    if (!frequencyModel) {
        frequencyModel = [[TuneMessageDisplayFrequency alloc] initWithCampaignID:message.campaign.campaignId eventMD5:message.triggerEvent];
    }
    return frequencyModel;
}

- (void)markEventTriggeredForMessage:(TuneInAppMessage *)message {
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
