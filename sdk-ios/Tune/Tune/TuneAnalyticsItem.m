//
//  TuneAnalyticsItem.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/6/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneAnalyticsItem.h"

#import "TuneAnalyticsVariable.h"
#import "TuneUtils.h"
#import "TuneEventKeys.h"
#import "TuneEventItem+Internal.h"

@implementation TuneAnalyticsItem

+ (instancetype)analyticsItemFromTuneEventItem:(TuneEventItem *)event {
    
    return [[[self class] alloc] initWithTuneEventItem:event];
}

- (id)initWithTuneEventItem:(TuneEventItem *)eventItem {
    self = [super init];
    
    if (self) {
        self.item = eventItem.item;
        self.unitPrice = [@(eventItem.unitPrice) stringValue];
        self.quantity = [@(eventItem.quantity) stringValue];
        self.revenue = [@(eventItem.revenue) stringValue];
        
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        
        if([eventItem attribute1] && [NSNull null] != (id)[eventItem attribute1])
        {
            [attributes addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB1 value:eventItem.attribute1 type:TuneAnalyticsVariableStringType]];
        }
        if([eventItem attribute2] && [NSNull null] != (id)[eventItem attribute2])
        {
            [attributes addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB2 value:eventItem.attribute2 type:TuneAnalyticsVariableStringType]];
        }
        if([eventItem attribute3] && [NSNull null] != (id)[eventItem attribute3])
        {
            [attributes addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB3 value:eventItem.attribute3 type:TuneAnalyticsVariableStringType]];
        }
        if([eventItem attribute4] && [NSNull null] != (id)[eventItem attribute4])
        {
            [attributes addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB4 value:eventItem.attribute4 type:TuneAnalyticsVariableStringType]];
        }
        if([eventItem attribute5] && [NSNull null] != (id)[eventItem attribute5])
        {
            [attributes addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB5 value:eventItem.attribute5 type:TuneAnalyticsVariableStringType]];
        }
        
        [attributes addObjectsFromArray:eventItem.tags];
        
        self.attributes = attributes;
    }
    
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableArray *attributesConv = [[NSMutableArray alloc] init];
    
    for (TuneAnalyticsVariable *attribute in self.attributes) {
        [attributesConv addObjectsFromArray:[attribute toArrayOfDicts]];
    }
    
    return @{ @"item"       : [TuneUtils objectOrNull:self.item],
              @"unitPrice"  : [TuneUtils objectOrNull:self.unitPrice],
              @"quantity"   : [TuneUtils objectOrNull:self.quantity],
              @"revenue"    : [TuneUtils objectOrNull:self.revenue],
              @"attributes" : attributesConv};
}

@end
