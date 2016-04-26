//
//  TuneEvent.m
//  Tune
//
//  Created by Harshal Ogale on 3/10/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneEvent+Internal.h"

#import "TuneAnalyticsVariable.h"
#import "TuneEventItem+Internal.h"
#import "TuneEventKeys.h"
#import "TuneKeyStrings.h"
#import "TuneLocation+Internal.h"

NSString *const TUNE_EVENT_ACHIEVEMENT_UNLOCKED = @"achievement_unlocked";
NSString *const TUNE_EVENT_ADD_TO_CART          = @"add_to_cart";
NSString *const TUNE_EVENT_ADD_TO_WISHLIST      = @"add_to_wishlist";
NSString *const TUNE_EVENT_ADDED_PAYMENT_INFO   = @"added_payment_info";
NSString *const TUNE_EVENT_CHECKOUT_INITIATED   = @"checkout_initiated";
NSString *const TUNE_EVENT_CONTENT_VIEW         = @"content_view";
NSString *const TUNE_EVENT_INVITE               = @"invite";
NSString *const TUNE_EVENT_LEVEL_ACHIEVED       = @"level_achieved";
NSString *const TUNE_EVENT_LOGIN                = @"login";
NSString *const TUNE_EVENT_PURCHASE             = @"purchase";
NSString *const TUNE_EVENT_RATED                = @"rated";
NSString *const TUNE_EVENT_REGISTRATION         = @"registration";
NSString *const TUNE_EVENT_RESERVATION          = @"reservation";
NSString *const TUNE_EVENT_SEARCH               = @"search";
NSString *const TUNE_EVENT_SESSION              = @"session";
NSString *const TUNE_EVENT_SHARE                = @"share";
NSString *const TUNE_EVENT_SPENT_CREDITS        = @"spent_credits";
NSString *const TUNE_EVENT_TUTORIAL_COMPLETE    = @"tutorial_complete";

static const int TUNE_IGNORE_IOS_PURCHASE_STATUS     = -192837465;

@implementation TuneEvent

+ (instancetype)eventWithName:(NSString *)eventName
{
    return [[TuneEvent alloc] initWithEventName:eventName];
}

+ (instancetype)eventWithId:(NSInteger)eventId
{
    return [[TuneEvent alloc] initWithEventId:eventId];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _transactionState = TUNE_IGNORE_IOS_PURCHASE_STATUS;
        _tags = [[NSMutableArray alloc] init];
        _addedTags = [[NSMutableSet alloc] init];
        
        _notAllowedAttributes = [NSSet setWithObjects:
                                 TUNE_KEY_EVENT_ID,
                                 TUNE_KEY_EVENT_REVENUE,
                                 TUNE_KEY_EVENT_CURRENCY_CODE,
                                 TUNE_KEY_EVENT_REFERENCE_ID,
                                 TUNE_KEY_EVENT_RECEIPT,
                                 TUNE_KEY_EVENT_CONTENT_TYPE,
                                 TUNE_KEY_EVENT_CONTENT_ID,
                                 TUNE_KEY_EVENT_SEARCH_STRING,
                                 TUNE_KEY_EVENT_TRANSACTION_STATE,
                                 TUNE_KEY_EVENT_RATING,
                                 TUNE_KEY_EVENT_LEVEL,
                                 TUNE_KEY_EVENT_QUANTITY,
                                 TUNE_KEY_EVENT_DATE1,
                                 TUNE_KEY_EVENT_DATE2,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB1,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB2,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB3,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB4,
                                 TUNE_KEY_EVENT_ATTRIBUTE_SUB5,
                                 nil];
    }
    return self;
}

- (instancetype)initWithEventName:(NSString *)eventName {
    self = [self init];
    
    if (self) {
        _eventName = [eventName copy];
        _actionName = [[[self class] actionNameForEvent:self] copy];
    }
    return self;
}

- (instancetype)initWithEventId:(NSInteger)eventId {
    self = [self init];
    if (self) {
        [self setEventId:eventId];
        _actionName = [[[self class] actionNameForEvent:self] copy];
    }
    return self;
}

- (void)setPostConversion:(BOOL)postConversion {
    _postConversion = postConversion;
    _actionName = [[[self class] actionNameForEvent:self] copy];
}


///////////////////////////////
/// Overloaded Setters
//////////////////////////////

- (void)setEventId:(NSInteger)eventId {
    _eventId = eventId;
    
    _eventIdObject = @(eventId);
}

- (void)setRevenue:(CGFloat)revenue {
    _revenue = revenue;
    
    _revenueObject = @(revenue);
}

- (void)setTransactionState:(NSInteger)transactionState {
    _transactionState = transactionState;
    
    _transactionStateObject = @(transactionState);
}

- (void)setRating:(CGFloat)rating {
    _rating = rating;
    
    _ratingObject = @(rating);
}

- (void)setLevel:(NSInteger)level {
    _level = level;
    
    _levelObject = @(level);
}

- (void)setQuantity:(NSUInteger)quantity {
    _quantity = quantity;
    
    _quantityObject = @(quantity);
}

/////////////////////////////

+ (NSString *)actionNameForEvent:(TuneEvent *)event {
    NSString *actionName = event.eventName;
    
    if (event.eventName) {
        NSString *eventNameLower = [event.eventName lowercaseString];
        
        if(event.postConversion && [eventNameLower isEqualToString:TUNE_EVENT_INSTALL] ) {
            // don't modify action name
        } else if([eventNameLower isEqualToString:TUNE_EVENT_GEOFENCE] ) {
            // don't modify action name
        } else if([eventNameLower isEqualToString:TUNE_EVENT_INSTALL] ||
                 [eventNameLower isEqualToString:TUNE_EVENT_UPDATE] ||
                 [eventNameLower isEqualToString:TUNE_EVENT_OPEN] ||
                 [eventNameLower isEqualToString:TUNE_EVENT_SESSION] ) {
            actionName = TUNE_EVENT_SESSION;
        } else {
            actionName = TUNE_EVENT_CONVERSION;
        }
    } else {
        actionName = TUNE_EVENT_CONVERSION;
    }
    
    return actionName;
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

- (void)addTag:(NSString *)name value:(id)value type:(TuneAnalyticsVariableDataType)type hashed:(BOOL)shouldAutoHash {
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
            ErrorLog(@"The tag '%@' has already been added to this event. Can not add duplicate tags.", prettyName);
            return;
        } else {
            [_addedTags addObject:prettyName];
        }
        
        [self.tags addObject:[TuneAnalyticsVariable analyticsVariableWithName:prettyName value:value type:type shouldAutoHash:shouldAutoHash]];
    }
}

@end
