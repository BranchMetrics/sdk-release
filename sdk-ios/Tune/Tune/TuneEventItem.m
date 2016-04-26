//
//  TuneEventItem.m
//  Tune
//
//  Created by John Bender on 1/10/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneEventItem+Internal.h"

#import "TuneAnalyticsVariable.h"
#import "TuneEventKeys.h"
#import "TuneDateUtils.h"
#import "TuneKeyStrings.h"
#import "TuneLocation.h"

@implementation TuneEventItem

@synthesize item, unitPrice, quantity, revenue, attribute1, attribute2, attribute3, attribute4, attribute5;

+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(CGFloat)unitPrice quantity:(NSUInteger)quantity {
    return [TuneEventItem eventItemWithName:name unitPrice:unitPrice quantity:quantity revenue:(unitPrice * quantity) attribute1:nil attribute2:nil attribute3:nil attribute4:nil attribute5:nil];
}

+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(CGFloat)unitPrice quantity:(NSUInteger)quantity revenue:(CGFloat)revenue {
    return [TuneEventItem eventItemWithName:name unitPrice:unitPrice quantity:quantity revenue:revenue attribute1:nil attribute2:nil attribute3:nil attribute4:nil attribute5:nil];
}

+ (instancetype)eventItemWithName:(NSString *)name
                       attribute1:(NSString *)attribute1
                       attribute2:(NSString *)attribute2
                       attribute3:(NSString *)attribute3
                       attribute4:(NSString *)attribute4
                       attribute5:(NSString *)attribute5 {
    return [TuneEventItem eventItemWithName:name unitPrice:0 quantity:0 revenue:0 attribute1:attribute1 attribute2:attribute2 attribute3:attribute3 attribute4:attribute4 attribute5:attribute5];
}

+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(CGFloat)unitPrice quantity:(NSUInteger)quantity revenue:(CGFloat)revenue
                       attribute1:(NSString *)attribute1
                       attribute2:(NSString *)attribute2
                       attribute3:(NSString *)attribute3
                       attribute4:(NSString *)attribute4
                       attribute5:(NSString *)attribute5 {
    TuneEventItem *eventItem = [[TuneEventItem alloc] init];
    
    eventItem.item = name;
    eventItem.unitPrice = unitPrice;
    eventItem.quantity = quantity;
    eventItem.revenue = revenue;
    
    eventItem.attribute1 = attribute1;
    eventItem.attribute2 = attribute2;
    eventItem.attribute3 = attribute3;
    eventItem.attribute4 = attribute4;
    eventItem.attribute5 = attribute5;
    
    
    return eventItem;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tags = [[NSMutableArray alloc] init];
        _addedTags = [[NSMutableSet alloc] init];
        _notAllowedAttributes = [NSSet setWithObjects:
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB1,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB2,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB3,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB4,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB5,
                                 nil];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // add each property from item to dictionary
    
    if([self item] && [NSNull null] != (id)[self item]) {
        [dict setValue:[self item] forKey:TUNE_KEY_ITEM];
    }
    
    [dict setValue:[@([self unitPrice]) stringValue] forKey:TUNE_KEY_UNIT_PRICE];
    [dict setValue:[@([self quantity]) stringValue] forKey:TUNE_KEY_QUANTITY];
    [dict setValue:[@([self revenue]) stringValue] forKey:TUNE_KEY_REVENUE];
    
    if([self attribute1] && [NSNull null] != (id)[self attribute1]) {
        [dict setValue:[self attribute1] forKey:TUNE_KEY_ATTRIBUTE_SUB1];
    }
    
    if([self attribute2] && [NSNull null] != (id)[self attribute2]) {
        [dict setValue:[self attribute2] forKey:TUNE_KEY_ATTRIBUTE_SUB2];
    }
    
    if([self attribute3] && [NSNull null] != (id)[self attribute3]) {
        [dict setValue:[self attribute3] forKey:TUNE_KEY_ATTRIBUTE_SUB3];
    }
    
    if([self attribute4] && [NSNull null] != (id)[self attribute4]) {
        [dict setValue:[self attribute4] forKey:TUNE_KEY_ATTRIBUTE_SUB4];
    }
    
    if([self attribute5] && [NSNull null] != (id)[self attribute5]) {
        [dict setValue:[self attribute5] forKey:TUNE_KEY_ATTRIBUTE_SUB5];
    }
    
    return dict;
}

//NOTE: This method is used in TuneTracker for submitting to the non-Artisan endpoint
+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items {
    NSMutableArray *arr = [NSMutableArray array];

    for (TuneEventItem *item in items) {
        [arr addObject:[item toDictionary]];
    }
    return arr;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p> %@", [self class], self, [self toDictionary]];
}

- (void)addTag:(NSString *)name withStringValue:(NSString *)value {
    [self addTag:name value:value type:TuneAnalyticsVariableStringType hashed:NO];
}

- (void)addTag:(NSString *)name withStringValue:(NSString *)value hashed:(BOOL)shouldHash {
    [self addTag:name value:value type:TuneAnalyticsVariableStringType hashed:shouldHash];
}

- (void)addTag:(NSString *)name withBooleanValue:(NSNumber *)value {
    [self addTag:name value:value type:TuneAnalyticsVariableBooleanType hashed:NO];
}

- (void)addTag:(NSString *)name withDateTimeValue:(NSDate *)value {
    [self addTag:name value:value type:TuneAnalyticsVariableDateTimeType hashed:NO];
}

- (void)addTag:(NSString *)name withNumberValue:(NSNumber *)value {
    [self addTag:name value:value type:TuneAnalyticsVariableNumberType hashed:NO];
}

- (void)addTag:(NSString *)name withGeolocationValue:(TuneLocation *)value {
    if (![TuneAnalyticsVariable validateTuneLocation:value]) {
        ErrorLog(@"Both the longitude and latitude properties must be set for TuneLocation objects.");
        return;
    }
    
    [self addTag:name value:value type:TuneAnalyticsVariableCoordinateType hashed:NO];
}

- (void)addTag:(NSString *)name withVersionValue:(NSString *)value {
    if (![TuneAnalyticsVariable validateVersion:value]) {
        ErrorLog(@"The given version format is not valid. Got: %@", value);
        return;
    }
    
    [self addTag:name value:value type:TuneAnalyticsVariableVersionType hashed:NO];
}

- (void)addTag:(NSString *)name value:(id)value type:(TuneAnalyticsVariableDataType)type hashed:(BOOL)shouldHash {
    if ([TuneAnalyticsVariable validateName:name]){
        NSString *prettyName = [TuneAnalyticsVariable cleanVariableName:name];
        
        if ([_notAllowedAttributes containsObject:prettyName]) {
            ErrorLog(@"'%@' is a property, please use the appropriate setter instead.", prettyName);
            return;
        }
        
        if ([prettyName hasPrefix:@"TUNE_"]) {
            ErrorLog(@"Tags starting with 'TUNE_' are reserved. Not registering: %@", prettyName);
            return;
        }
        
        if ([_addedTags containsObject:prettyName]) {
            ErrorLog(@"The tag '%@' has already been added to this event item. Can not add duplicate tags.", prettyName);
            return;
        } else {
            [_addedTags addObject:prettyName];
        }

        [self.tags addObject:[TuneAnalyticsVariable analyticsVariableWithName:prettyName value:value type:type shouldAutoHash:shouldHash]];
    }
}

@end
