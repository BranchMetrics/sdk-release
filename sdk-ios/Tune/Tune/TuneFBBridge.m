//
//  TuneFBBridge.m
//  Tune
//
//  Created by John Bender on 10/8/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneFBBridge.h"

#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TuneUserProfile.h"
#import "TuneUtils.h"

// Ref: if < FB 4.0 <FACEBOOK_IOS_FRAMEWORK>/Headers/FBAppEvents.h
// Ref: if >= FB 4.0 <FACEBOOK_IOS_FRAMEWORK>/Headers/FBSDKAppEvents.h

// General purpose
NSString *const TUNE_FBAppEventNameActivatedApp            = @"fb_mobile_activate_app";
NSString *const TUNE_FBAppEventNameCompletedRegistration   = @"fb_mobile_complete_registration";
NSString *const TUNE_FBAppEventNameViewedContent           = @"fb_mobile_content_view";
NSString *const TUNE_FBAppEventNameSearched                = @"fb_mobile_search";
NSString *const TUNE_FBAppEventNameRated                   = @"fb_mobile_rate";
NSString *const TUNE_FBAppEventNameCompletedTutorial       = @"fb_mobile_tutorial_completion";

// Ecommerce related
NSString *const TUNE_FBAppEventNameAddedToCart             = @"fb_mobile_add_to_cart";
NSString *const TUNE_FBAppEventNameAddedToWishlist         = @"fb_mobile_add_to_wishlist";
NSString *const TUNE_FBAppEventNameInitiatedCheckout       = @"fb_mobile_initiated_checkout";
NSString *const TUNE_FBAppEventNameAddedPaymentInfo        = @"fb_mobile_add_payment_info";
NSString *const TUNE_FBAppEventNamePurchased               = @"fb_mobile_purchase";

// Gaming related
NSString *const TUNE_FBAppEventNameAchievedLevel           = @"fb_mobile_level_achieved";
NSString *const TUNE_FBAppEventNameUnlockedAchievement     = @"fb_mobile_achievement_unlocked";
NSString *const TUNE_FBAppEventNameSpentCredits            = @"fb_mobile_spent_credits";

//
// Public event parameter names
//

NSString *const TUNE_FBAppEventParameterNameCurrency             = @"fb_currency";
NSString *const TUNE_FBAppEventParameterNameRegistrationMethod   = @"fb_registration_method";
NSString *const TUNE_FBAppEventParameterNameContentType          = @"fb_content_type";
NSString *const TUNE_FBAppEventParameterNameContentID            = @"fb_content_id";
NSString *const TUNE_FBAppEventParameterNameSearchString         = @"fb_search_string";
NSString *const TUNE_FBAppEventParameterNameSuccess              = @"fb_success";
NSString *const TUNE_FBAppEventParameterNameMaxRatingValue       = @"fb_max_rating_value";
NSString *const TUNE_FBAppEventParameterNamePaymentInfoAvailable = @"fb_payment_info_available";
NSString *const TUNE_FBAppEventParameterNameNumItems             = @"fb_num_items";
NSString *const TUNE_FBAppEventParameterNameLevel                = @"fb_level";
NSString *const TUNE_FBAppEventParameterNameDescription          = @"fb_description";

NSString *const TUNE_REFERRAL_SOURCE                        = @"tune_referral_source";
NSString *const TUNE_SOURCE_SDK                             = @"tune_source_sdk";


@implementation TuneFBBridge

+ (void)sendEvent:(TuneEvent *)event limitEventAndDataUsage:(BOOL)limit
{
    Class FBSettings = [TuneUtils getClassFromString:@"FBSettings"] ?: [TuneUtils getClassFromString:@"FBSDKSettings"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selLimitMethod = @selector(setLimitEventAndDataUsage:);
#pragma clang diagnostic pop
    
    if([FBSettings class] && [FBSettings respondsToSelector:selLimitMethod])
    {
        // use NSInvocation since performSelector only allows params with type 'id'
        NSMethodSignature* signature = [FBSettings methodSignatureForSelector:selLimitMethod];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:FBSettings];
        [invocation setSelector:selLimitMethod];
        [invocation setArgument:&limit atIndex:2];
        [invocation invoke];
    }
    
    Class FBAppEvents = [TuneUtils getClassFromString:@"FBAppEvents"] ?: [TuneUtils getClassFromString:@"FBSDKAppEvents"];
    if( ![FBAppEvents class] ) {
        DebugLog( @"TuneFBBridge no FBAppEvents/FBSDKAppEvents class" );
        
        return;
    }
    
    // add event parameter dictionary based on current args;
    // map between Tune params and FB params:
    // https://developers.facebook.com/docs/ios/app-events
    
    SEL selMethod = nil;
    
    NSString *fbEventName = event.eventName;
    NSString *currency = event.currencyCode ?: [[TuneManager currentManager].userProfile currencyCode];
    double valueToSum = [@(event.revenue) doubleValue];
    
    NSString *eventNameLower = [event.eventName lowercaseString];
    
    if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_SESSION].location) {
        fbEventName = TUNE_FBAppEventNameActivatedApp;
        selMethod = NSSelectorFromString([NSString stringWithFormat:@"%@iva%@App", @"act", @"te"]);
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_REGISTRATION].location) {
        fbEventName = TUNE_FBAppEventNameCompletedRegistration;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_CONTENT_VIEW].location) {
        fbEventName = TUNE_FBAppEventNameViewedContent;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_SEARCH].location) {
        fbEventName = TUNE_FBAppEventNameSearched;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_RATED].location) {
        fbEventName = TUNE_FBAppEventNameRated;
        valueToSum = [@(event.rating) doubleValue];
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_TUTORIAL_COMPLETE].location) {
        fbEventName = TUNE_FBAppEventNameCompletedTutorial;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_ADD_TO_CART].location) {
        fbEventName = TUNE_FBAppEventNameAddedToCart;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_ADD_TO_WISHLIST].location) {
        fbEventName = TUNE_FBAppEventNameAddedToWishlist;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_CHECKOUT_INITIATED].location) {
        fbEventName = TUNE_FBAppEventNameInitiatedCheckout;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_ADDED_PAYMENT_INFO].location) {
        fbEventName = TUNE_FBAppEventNameAddedPaymentInfo;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_PURCHASE].location) {
        fbEventName = TUNE_FBAppEventNamePurchased;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        selMethod = @selector(logPurchase:currency:parameters:);
#pragma clang diagnostic pop
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_LEVEL_ACHIEVED].location) {
        fbEventName = TUNE_FBAppEventNameAchievedLevel;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_ACHIEVEMENT_UNLOCKED].location) {
        fbEventName = TUNE_FBAppEventNameUnlockedAchievement;
    } else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_SPENT_CREDITS].location) {
        fbEventName = TUNE_FBAppEventNameSpentCredits;
        valueToSum = [@(event.quantity) doubleValue];
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if(currency)
        dict[TUNE_FBAppEventParameterNameCurrency] = currency;
    if(event.contentId)
        dict[TUNE_FBAppEventParameterNameContentID] = event.contentId;
    if(event.contentType)
        dict[TUNE_FBAppEventParameterNameContentType] = event.contentType;
    if(event.searchString)
        dict[TUNE_FBAppEventParameterNameSearchString] = event.searchString;
    if(0 != event.quantity)
        dict[TUNE_FBAppEventParameterNameNumItems] = @(event.quantity);
    if(0 != event.level)
        dict[TUNE_FBAppEventParameterNameLevel] = @(event.level);
    if([[TuneManager currentManager].userProfile referralSource])
        dict[TUNE_REFERRAL_SOURCE] = [[TuneManager currentManager].userProfile referralSource];
    
    dict[TUNE_SOURCE_SDK] = @"TUNE-MAT";
    
    if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_SESSION].location
        && [FBAppEvents respondsToSelector:selMethod])
    {
        NSMethodSignature* signature = [FBAppEvents methodSignatureForSelector:selMethod];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:FBAppEvents];
        [invocation setSelector:selMethod];
        [invocation invoke];
    }
    else if (NSNotFound != [eventNameLower rangeOfString:TUNE_EVENT_PURCHASE].location
             && [FBAppEvents respondsToSelector:selMethod])
    {
        NSMethodSignature* signature = [FBAppEvents methodSignatureForSelector:selMethod];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:FBAppEvents];
        [invocation setSelector:selMethod];
        [invocation setArgument:&valueToSum atIndex:2];
        [invocation setArgument:&currency atIndex:3];
        [invocation setArgument:&dict atIndex:4];
        [invocation invoke];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        selMethod = @selector(logEvent:valueToSum:parameters:);
#pragma clang diagnostic pop
        if( ![FBAppEvents respondsToSelector:selMethod] ) {
            DebugLog(@"TuneFBBridge no %@ method in fbsdk", NSStringFromSelector(selMethod));
            return;
        }
        
        DebugLog(@"TuneFBBridge logging event %@", fbEventName);
        
        NSMethodSignature* signature = [FBAppEvents methodSignatureForSelector:selMethod];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:FBAppEvents];
        [invocation setSelector:selMethod];
        [invocation setArgument:&fbEventName atIndex:2];
        [invocation setArgument:&valueToSum atIndex:3];
        [invocation setArgument:&dict atIndex:4];
        [invocation invoke];
    }
}

@end
