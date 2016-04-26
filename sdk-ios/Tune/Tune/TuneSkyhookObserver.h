//
//  TuneSkyhookObserver.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneSkyhookPayload;

// Maintains information for a given skyhook observer
@interface TuneSkyhookObserver : NSObject

@property (weak, readonly) id observer;
@property (readonly) SEL selector;
@property (weak, readonly) id sender;
@property (readonly) int priority;

- (id)initWithObserver:(id)observer selector:(SEL)selector sender:(id)sender priority:(int)priority;
- (void)sendPayload:(TuneSkyhookPayload *)payload;
- (BOOL)matchesSender:(id)sender;

/* Returns YES if the observer still exists, otherwise returns NO. If it returns NO, we should
 remove this skyhook observer from the list of observers. */
- (BOOL)isStillValid;
- (NSString *)description;

@end
