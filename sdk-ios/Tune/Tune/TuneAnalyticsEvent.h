//
//  TuneAnalyticsEvent.h
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/30/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneEvent;
@class TuneAnalyticsSubmitter;

@interface TuneAnalyticsEvent : NSObject

// Unique identifier for this specific instance of this event.
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, retain) TuneAnalyticsSubmitter *submitter;
@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *control;
@property (nonatomic, copy) NSString *controlEvent;
@property (nonatomic, copy) NSDate *timestamp;

// Seconds since session started.
@property (nonatomic, copy) NSNumber *sessionTime;

@property (nonatomic, copy) NSString *schemaVersion;


// Array of TuneAnalyticsVariable
@property (nonatomic, copy) NSArray *tags;
// Array of TuneEventItems
@property (nonatomic, copy) NSArray *items;

// Basic method to create a 'Custom' event.
- (id)initCustomEventWithAction:(NSString *)action;

- (id)initWithEventType:(NSString *)eventType
                 action:(NSString *)action
               category:(NSString *)category
                control:(NSString *)control
           controlEvent:(NSString *)controlEvent
                   tags:(NSArray *)tags
                  items:(NSArray *)items;

- (id)initWithTuneEvent:(TuneEvent *)event;

- (id)initWithTuneEvent:(NSString *)eventType
                 action:(NSString *)action
               category:(NSString *)category
                control:(NSString *)control
           controlEvent:(NSString *)controlEvent
                  event:(TuneEvent *)event;

- (id)initAsTracerEvent;

- (NSString *)getFiveline;

- (NSString *)getEventMd5;

- (NSString *) eventId;

- (NSDictionary *)toDictionary;

@end
