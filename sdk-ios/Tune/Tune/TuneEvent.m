//
//  TuneEvent.m
//  Tune
//
//  Created by Harshal Ogale on 3/10/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "Common/TuneEvent_internal.h"
#import "Common/TuneKeyStrings.h"

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

@interface TuneEvent ()

@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSString *actionName;

@property (nonatomic, copy) NSNumber *altitude;
@property (nonatomic, strong) NSDictionary *cworksClick;            // key, value pair
@property (nonatomic, strong) NSDictionary *cworksImpression;       // key, value pair
@property (nonatomic, copy) NSString *iBeaconRegionId;              // KEY_GEOFENCE_NAME
@property (nonatomic, copy) NSNumber *latitude;
@property (nonatomic, copy) NSNumber *locationHorizontalAccuracy;
@property (nonatomic, copy) NSDate *locationTimestamp;
@property (nonatomic, copy) NSNumber *locationVerticalAccuracy;
@property (nonatomic, copy) NSNumber *longitude;
@property (nonatomic, assign) BOOL postConversion;                  // KEY_POST_CONVERSION

@end

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
    }
    return self;
}

- (instancetype)initWithEventName:(NSString *)eventName
{
    self = [self init];
    if (self) {
        _eventName = [eventName copy];
        _actionName = [[[self class] actionNameForEvent:self] copy];
    }
    return self;
}

- (instancetype)initWithEventId:(NSInteger)eventId
{
    self = [self init];
    if (self) {
        _eventId = eventId;
        _actionName = [[[self class] actionNameForEvent:self] copy];
    }
    return self;
}

- (void)setPostConversion:(BOOL)postConversion
{
    _postConversion = postConversion;
    _actionName = [[[self class] actionNameForEvent:self] copy];
}

+ (NSString *)actionNameForEvent:(TuneEvent *)event
{
    NSString *actionName = event.eventName;
    
    if (event.eventName)
    {
        NSString *eventNameLower = [event.eventName lowercaseString];
        
        if(event.postConversion && [eventNameLower isEqualToString:TUNE_EVENT_INSTALL] ) {
            // don't modify action name
        }
        else if([eventNameLower isEqualToString:TUNE_EVENT_GEOFENCE] ) {
            // don't modify action name
        }
        else if([eventNameLower isEqualToString:TUNE_EVENT_INSTALL] ||
                [eventNameLower isEqualToString:TUNE_EVENT_UPDATE] ||
                [eventNameLower isEqualToString:TUNE_EVENT_OPEN] ||
                [eventNameLower isEqualToString:TUNE_EVENT_SESSION] ) {
            actionName = TUNE_EVENT_SESSION;
        }
        else
        {
            actionName = TUNE_EVENT_CONVERSION;
        }
    }
    else
    {
        actionName = TUNE_EVENT_CONVERSION;
    }
    
    return actionName;
}

@end
