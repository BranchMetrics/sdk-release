//
//  TuneTriggerManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModule.h"
#import "TuneBaseMessageFactory.h"

@interface TuneTriggerManager : TuneModule {
    NSMutableDictionary *_messageDisplayFrequencyDictionary;
}

@property (strong, nonatomic) NSMutableDictionary *messageTriggers;
@property (strong, nonatomic) TuneBaseMessageFactory *messageToShow;

- (void)triggerMessage:(TuneBaseMessageFactory *)inAppMessage fromEvent:(NSString *)event;

@end
