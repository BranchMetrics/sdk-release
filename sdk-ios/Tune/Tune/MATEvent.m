//
//  MATEvent.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 3/10/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import "Common/MATEvent_internal.h"
#import "MATEventItem.h"
#import "Common/TuneKeyStrings.h"

NSString *const MAT_EVENT_ACHIEVEMENT_UNLOCKED = @"achievement_unlocked";
NSString *const MAT_EVENT_ADD_TO_CART          = @"add_to_cart";
NSString *const MAT_EVENT_ADD_TO_WISHLIST      = @"add_to_wishlist";
NSString *const MAT_EVENT_ADDED_PAYMENT_INFO   = @"added_payment_info";
NSString *const MAT_EVENT_CHECKOUT_INITIATED   = @"checkout_initiated";
NSString *const MAT_EVENT_CONTENT_VIEW         = @"content_view";
NSString *const MAT_EVENT_INVITE               = @"invite";
NSString *const MAT_EVENT_LEVEL_ACHIEVED       = @"level_achieved";
NSString *const MAT_EVENT_LOGIN                = @"login";
NSString *const MAT_EVENT_PURCHASE             = @"purchase";
NSString *const MAT_EVENT_RATED                = @"rated";
NSString *const MAT_EVENT_REGISTRATION         = @"registration";
NSString *const MAT_EVENT_RESERVATION          = @"reservation";
NSString *const MAT_EVENT_SEARCH               = @"search";
NSString *const MAT_EVENT_SESSION              = @"session";
NSString *const MAT_EVENT_SHARE                = @"share";
NSString *const MAT_EVENT_SPENT_CREDITS        = @"spent_credits";
NSString *const MAT_EVENT_TUTORIAL_COMPLETE    = @"tutorial_complete";

static const int MAT_IGNORE_IOS_PURCHASE_STATUS     = -192837465;

@interface MATEvent ()

@property (nonatomic, copy) NSString *eventName;

@end

@implementation MATEvent

+ (instancetype)eventWithName:(NSString *)eventName
{
    return [[MATEvent alloc] initWithEventName:eventName];
}

+ (instancetype)eventWithId:(NSInteger)eventId
{
    return [[MATEvent alloc] initWithEventId:eventId];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _transactionState = MAT_IGNORE_IOS_PURCHASE_STATUS;
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

+ (NSString *)actionNameForEvent:(MATEvent *)event
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
                [eventNameLower isEqualToString:MAT_EVENT_SESSION] ) {
            actionName = MAT_EVENT_SESSION;
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
