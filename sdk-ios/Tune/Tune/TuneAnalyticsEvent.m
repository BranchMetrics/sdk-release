//
//  TuneAnalyticsEvent.m
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/30/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneAnalyticsEvent.h"

#import "TuneAnalyticsConstants.h"
#import "TuneAnalyticsItem.h"
#import "TuneAnalyticsSubmitter.h"
#import "TuneAnalyticsVariable.h"
#import "TuneEvent+Internal.h"
#import "TuneEventKeys.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TunePreloadData.h"
#import "TuneUserProfile.h"
#import "TuneUtils.h"
#import "TuneSessionManager.h"


@implementation TuneAnalyticsEvent

- (id)initWithBaseInfo {
    self = [super init];
    
    if (self) {
        self.uuid = [TuneUtils getUUID];
        
        self.submitter = [TuneAnalyticsSubmitter new];
        
        self.appId = [[TuneManager currentManager].userProfile hashedAppId];
        
        self.timestamp = [NSDate date];
        self.sessionTime = @([[TuneManager currentManager].sessionManager timeSinceSessionStart]);
        
        self.schemaVersion = TUNE_SCHEMA_VERSION;
    }

    return self;
}

- (id)initCustomEventWithAction:(NSString *)action {
    self = [self initWithBaseInfo];
    
    if (self) {
        self.eventType = TUNE_EVENT_TYPE_BASE;
        self.category = TUNE_EVENT_CATEGORY_CUSTOM;
        self.action = action;
    }
    return self;
}

- (id)initWithEventType:(NSString *)eventType
                 action:(NSString *)action
               category:(NSString *)category
                control:(NSString *)control
           controlEvent:(NSString *)controlEvent
                   tags:(NSArray *)tags
                  items:(NSArray *)items {
    self = [self initWithBaseInfo];
    
    if (self) {
        self.eventType = eventType;
        self.action = action;
        self.category = category;
        self.control = control;
        self.controlEvent = controlEvent;
        self.tags = tags;
        self.items = items;
    }
    return self;
}

- (id)initWithTuneEvent:(TuneEvent *)event {
    return [self initWithTuneEvent: TUNE_EVENT_TYPE_BASE action: event.eventName category:TUNE_EVENT_CATEGORY_CUSTOM control:nil controlEvent:nil event: event];
}

- (id)initWithTuneEvent:(NSString *)eventType
                 action:(NSString *)action
               category:(NSString *)category
                control:(NSString *)control
           controlEvent:(NSString *)controlEvent
                  event:(TuneEvent *)event {
    self = [self initWithBaseInfo];
    
    if (self) {
        self.eventType = eventType;
        self.action = action;
        self.category = category;
        
        NSMutableArray *newTags = [[NSMutableArray alloc] init];
        if (event.eventIdObject != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ID value:event.eventIdObject type:TuneAnalyticsVariableNumberType]];
        }
        if (event.revenueObject != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_REVENUE value:event.revenueObject type:TuneAnalyticsVariableNumberType]];
        }
        if (event.currencyCode != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_CURRENCY_CODE value:event.currencyCode]];
        }
        if (event.refId != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_REFERENCE_ID value:event.refId]];
        }
        if (event.receipt != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_RECEIPT value:[TuneUtils tuneBase64EncodedStringFromData:event.receipt]]];
        }
        if (event.contentType != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_CONTENT_TYPE value:event.contentType]];
        }
        if (event.contentId != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_CONTENT_ID value:event.contentId]];
        }
        if (event.searchString != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_SEARCH_STRING value:event.searchString]];
        }
        if (event.transactionStateObject != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_TRANSACTION_STATE value:event.transactionStateObject type:TuneAnalyticsVariableNumberType]];
        }
        if (event.ratingObject != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_RATING value:event.ratingObject type:TuneAnalyticsVariableNumberType]];
        }
        if (event.levelObject != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_LEVEL value:event.levelObject type:TuneAnalyticsVariableNumberType]];
        }
        if (event.quantityObject != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_QUANTITY value:event.quantityObject type:TuneAnalyticsVariableNumberType]];
        }
            
        if (event.date1 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_DATE1 value:event.date1 type:TuneAnalyticsVariableDateTimeType]];
        }
        if (event.date2 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_DATE2 value:event.date2 type:TuneAnalyticsVariableDateTimeType]];
        }
        
        if (event.attribute1 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB1 value:event.attribute1]];
        }
        if (event.attribute2 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB2 value:event.attribute2]];
        }
        if (event.attribute3 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB3 value:event.attribute3]];
        }
        if (event.attribute4 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB4 value:event.attribute4]];
        }
        if (event.attribute5 != nil) {
            [newTags addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB5 value:event.attribute5]];
        }
    
        [newTags addObjectsFromArray:event.tags];
        
        self.tags = [newTags copy];
        
        NSMutableArray *newItems = [[NSMutableArray alloc] init];
        for (TuneEventItem *eventItem in event.eventItems) {
            // This is a guard against things other than TuneEventItems getting passed through
            if ([eventItem isMemberOfClass:[TuneEventItem class]]) {
                [newItems addObject:[TuneAnalyticsItem analyticsItemFromTuneEventItem:eventItem]];
            }
        }
        
        self.items = [newItems copy];
    }
    
    return self;
}

- (id)initAsTracerEvent {
    self = [self initWithBaseInfo];
    
    if (self) {
        self.eventType = @"TRACER";
    }
    return self;
}

- (NSString *)getFiveline {
    NSMutableString *fiveLine =  [NSMutableString stringWithString:@""];

    if(self.category) {
        [fiveLine appendString:self.category];
    }
    [fiveLine appendString:@"|"];
    if(self.controlEvent) {
        [fiveLine appendString:self.controlEvent];
    }
    [fiveLine appendString:@"|"];
    if(self.control) {
        [fiveLine appendString:self.control];
    }
    [fiveLine appendString:@"|"];
    if(self.action) {
        [fiveLine appendString:self.action];
    }
    [fiveLine appendString:@"|"];
    if(self.eventType) {
        [fiveLine appendString:self.eventType];
    }

    return fiveLine;
}

- (NSString *)getEventMd5 {
    return [TuneUtils hashMd5:[self getFiveline]];
}

- (NSString *)eventId {
    return [NSString stringWithFormat:@"%f-%@", [self.timestamp timeIntervalSince1970], self.uuid];
}

- (NSDictionary *)toDictionary {
    NSMutableArray *tagsConv = [[NSMutableArray alloc] init];
    for (TuneAnalyticsVariable *tag in self.tags) {
        [tagsConv addObjectsFromArray:[tag toArrayOfDicts]];
    }

    NSMutableArray *itemsConv = [[NSMutableArray alloc] init];
    for (TuneAnalyticsItem *item in self.items) {
        [itemsConv addObject:[item toDictionary]];
    }
    
    return @{ @"type"             : [TuneUtils objectOrNull:self.eventType],
              @"submitter"        : [self.submitter toDictionary],
              @"action"           : [TuneUtils objectOrNull:self.action],
              @"category"         : [TuneUtils objectOrNull:self.category],
              @"control"          : [TuneUtils objectOrNull:self.control],
              @"controlEvent"     : [TuneUtils objectOrNull:self.controlEvent],
              @"appId"            : [TuneUtils objectOrNull:self.appId],
              @"timestamp"        : [TuneUtils objectOrNull:@([self.timestamp timeIntervalSince1970])],
              @"sessionTime"      : [TuneUtils objectOrNull:self.sessionTime],
              @"schemaVersion"    : [TuneUtils objectOrNull:self.schemaVersion],
              @"tags"             : tagsConv,
              @"items"            : itemsConv,
              @"profile"          : [TuneUtils objectOrNull:[[TuneManager currentManager].userProfile toArrayOfDictionaries]]};
}

@end
