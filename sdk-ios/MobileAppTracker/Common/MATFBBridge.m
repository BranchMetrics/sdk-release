//
//  MATFBBridge.m
//  MobileAppTracker
//
//  Created by John Bender on 10/8/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "MATFBBridge.h"
#import "MATKeyStrings.h"

// Ref: <FACEBOOK_IOS_FRAMEWORK>/Headers/FBAppEvents.h

// General purpose
NSString *const MAT_FBAppEventNameActivatedApp            = @"fb_mobile_activate_app";
NSString *const MAT_FBAppEventNameCompletedRegistration   = @"fb_mobile_complete_registration";
NSString *const MAT_FBAppEventNameViewedContent           = @"fb_mobile_content_view";
NSString *const MAT_FBAppEventNameSearched                = @"fb_mobile_search";
NSString *const MAT_FBAppEventNameRated                   = @"fb_mobile_rate";
NSString *const MAT_FBAppEventNameCompletedTutorial       = @"fb_mobile_tutorial_completion";

// Ecommerce related
NSString *const MAT_FBAppEventNameAddedToCart             = @"fb_mobile_add_to_cart";
NSString *const MAT_FBAppEventNameAddedToWishlist         = @"fb_mobile_add_to_wishlist";
NSString *const MAT_FBAppEventNameInitiatedCheckout       = @"fb_mobile_initiated_checkout";
NSString *const MAT_FBAppEventNameAddedPaymentInfo        = @"fb_mobile_add_payment_info";
NSString *const MAT_FBAppEventNamePurchased               = @"fb_mobile_purchase";

// Gaming related
NSString *const MAT_FBAppEventNameAchievedLevel           = @"fb_mobile_level_achieved";
NSString *const MAT_FBAppEventNameUnlockedAchievement     = @"fb_mobile_achievement_unlocked";
NSString *const MAT_FBAppEventNameSpentCredits            = @"fb_mobile_spent_credits";

//
// Public event parameter names
//

NSString *const MAT_FBAppEventParameterNameCurrency             = @"fb_currency";
NSString *const MAT_FBAppEventParameterNameRegistrationMethod   = @"fb_registration_method";
NSString *const MAT_FBAppEventParameterNameContentType          = @"fb_content_type";
NSString *const MAT_FBAppEventParameterNameContentID            = @"fb_content_id";
NSString *const MAT_FBAppEventParameterNameSearchString         = @"fb_search_string";
NSString *const MAT_FBAppEventParameterNameSuccess              = @"fb_success";
NSString *const MAT_FBAppEventParameterNameMaxRatingValue       = @"fb_max_rating_value";
NSString *const MAT_FBAppEventParameterNamePaymentInfoAvailable = @"fb_payment_info_available";
NSString *const MAT_FBAppEventParameterNameNumItems             = @"fb_num_items";
NSString *const MAT_FBAppEventParameterNameLevel                = @"fb_level";
NSString *const MAT_FBAppEventParameterNameDescription          = @"fb_description";

NSString *const MAT_TUNE_REFERRAL_SOURCE                        = @"tune_referral_source";
NSString *const MAT_TUNE_SOURCE_SDK                             = @"tune_source_sdk";


@implementation MATFBBridge

+ (void)sendCurrentEvent:(MATSettings*)parameters limitEventAndDataUsage:(BOOL)limit
{
    Class FBSettings = NSClassFromString( @"FBSettings" );
    SEL selLimitMethod = @selector(setLimitEventUsage:);
    
    if([FBSettings class] && [FBSettings respondsToSelector:selLimitMethod])
    {
        // use NSInvocation since performSelector only allows params with type 'id'
        NSMethodSignature* signature = [FBSettings methodSignatureForSelector:selLimitMethod];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:FBSettings];
        [invocation setSelector:selLimitMethod ];
        [invocation setArgument:&limit atIndex:2];
        [invocation invoke];
    }
    
    Class FBAppEvents = NSClassFromString( @"FBAppEvents" );
    if( ![FBAppEvents class] ) {
        DLog( @"MATFBBridge no FBAppEvents class" );
        
        return;
    }
    
    // add event parameter dictionary based on current args;
    // map between MAT params and FB params:
    // https://developers.facebook.com/docs/ios/app-events
    
    SEL selMethod;
    
    NSString *fbEventName = parameters.actionName;
    double valueToSum = parameters.revenue.doubleValue;
    
    NSString *eventNameLower = [parameters.actionName lowercaseString];
    
    if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_SESSION].location) {
        selMethod = @selector(activateApp);
        fbEventName = MAT_FBAppEventNameActivatedApp;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_REGISTRATION].location) {
        fbEventName = MAT_FBAppEventNameCompletedRegistration;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_CONTENT_VIEW].location) {
        fbEventName = MAT_FBAppEventNameViewedContent;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_SEARCH].location) {
        fbEventName = MAT_FBAppEventNameSearched;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_RATED].location) {
        fbEventName = MAT_FBAppEventNameRated;
        valueToSum = parameters.eventRating.doubleValue;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_TUTORIAL_COMPLETE].location) {
        fbEventName = MAT_FBAppEventNameCompletedTutorial;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_ADD_TO_CART].location) {
        fbEventName = MAT_FBAppEventNameAddedToCart;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_ADD_TO_WISHLIST].location) {
        fbEventName = MAT_FBAppEventNameAddedToWishlist;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_CHECKOUT_INITIATED].location) {
        fbEventName = MAT_FBAppEventNameInitiatedCheckout;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_ADDED_PAYMENT_INFO].location) {
        fbEventName = MAT_FBAppEventNameAddedPaymentInfo;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_PURCHASE].location) {
        selMethod = @selector(logPurchase:currency:parameters:);
        fbEventName = MAT_FBAppEventNamePurchased;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_LEVEL_ACHIEVED].location) {
        fbEventName = MAT_FBAppEventNameAchievedLevel;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_ACHIEVEMENT_UNLOCKED].location) {
        fbEventName = MAT_FBAppEventNameUnlockedAchievement;
    } else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_SPENT_CREDITS].location) {
        fbEventName = MAT_FBAppEventNameSpentCredits;
        valueToSum = parameters.eventQuantity.doubleValue;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if(parameters.currencyCode)
        dict[MAT_FBAppEventParameterNameCurrency] = parameters.currencyCode;
    if(parameters.eventContentId)
        dict[MAT_FBAppEventParameterNameContentID] = parameters.eventContentId;
    if(parameters.eventContentType)
        dict[MAT_FBAppEventParameterNameContentType] = parameters.eventContentType;
    if(parameters.eventSearchString)
        dict[MAT_FBAppEventParameterNameSearchString] = parameters.eventSearchString;
    if(parameters.eventQuantity)
        dict[MAT_FBAppEventParameterNameNumItems] = parameters.eventQuantity;
    if(parameters.eventLevel)
        dict[MAT_FBAppEventParameterNameLevel] = parameters.eventLevel;
    if(parameters.referralSource)
        dict[MAT_TUNE_REFERRAL_SOURCE] = parameters.referralSource;
    
    dict[MAT_TUNE_SOURCE_SDK] = @"TUNE-MAT";
    
    
    if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_SESSION].location && [FBAppEvents respondsToSelector:selMethod])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [FBAppEvents performSelector:selMethod];
#pragma clang diagnostic pop
    }
    else if (NSNotFound != [eventNameLower rangeOfString:MAT_EVENT_PURCHASE].location && [FBAppEvents respondsToSelector:selMethod])
    {
        double purchaseAmount = parameters.revenue.doubleValue;
        NSString *curr = parameters.currencyCode;
        
        // use NSInvocation since performSelector only allows 2 params and the params must have type 'id'
        NSMethodSignature* signature = [FBAppEvents methodSignatureForSelector:selMethod];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:FBAppEvents];
        [invocation setSelector:selMethod ];
        [invocation setArgument:&purchaseAmount atIndex:2];
        [invocation setArgument:&curr atIndex:3];
        [invocation setArgument:&dict atIndex:4];
        [invocation invoke];
    }
    else
    {
        selMethod = @selector(logEvent:);
        if( ![FBAppEvents respondsToSelector:selMethod] ) {
            DLog( @"MATFBBridge no event method in fbsdk" );
            return;
        }
        
        DLog(@"MATFBBridge logging event %@", parameters.actionName);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [FBAppEvents performSelector:selMethod withObject:parameters.actionName withObject:dict];
#pragma clang diagnostic pop
    }
}

@end
