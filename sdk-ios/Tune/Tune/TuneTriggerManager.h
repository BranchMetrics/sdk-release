//
//  TuneTriggerManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModule.h"
#import "TuneInAppMessage.h"

@interface TuneTriggerManager : TuneModule {
    NSMutableDictionary *_messageDisplayFrequencyDictionary;
}

@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSMutableArray<TuneInAppMessage *> *> *inAppMessagesByEvents;
@property (nonatomic, strong, readwrite) TuneInAppMessage *messageToShow;
@property (nonatomic, assign, readwrite) BOOL firstPlaylistDownloaded;
@property (nonatomic, strong, readwrite) NSMutableSet *triggerEventsSeenPriorToPlaylistDownload;

- (void)triggerMessage:(TuneInAppMessage *)inAppMessage fromEvent:(NSString *)event;

@end
