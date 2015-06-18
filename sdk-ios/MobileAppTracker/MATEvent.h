//
//  MATEvent.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 3/10/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "MATEventItem.h"

/*!
 MobileAppTracking pre-defined event string "achievement_unlocked"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ACHIEVEMENT_UNLOCKED;

/*!
 MobileAppTracking pre-defined event string "add_to_cart"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ADD_TO_CART;

/*!
 MobileAppTracking pre-defined event string "add_to_wishlist"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ADD_TO_WISHLIST;

/*!
 MobileAppTracking pre-defined event string "added_payment_info"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ADDED_PAYMENT_INFO;

/*!
 MobileAppTracking pre-defined event string "checkout_initiated"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_CHECKOUT_INITIATED;

/*!
 MobileAppTracking pre-defined event string "content_view"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_CONTENT_VIEW;

/*!
 MobileAppTracking pre-defined event string "invite"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_INVITE;

/*!
 MobileAppTracking pre-defined event string "level_achieved"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_LEVEL_ACHIEVED;

/*!
 MobileAppTracking pre-defined event string "login"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_LOGIN;

/*!
 MobileAppTracking pre-defined event string "purchase"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_PURCHASE;

/*!
 MobileAppTracking pre-defined event string "rated"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_RATED;

/*!
 MobileAppTracking pre-defined event string "registration"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_REGISTRATION;

/*!
 MobileAppTracking pre-defined event string "reservation"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_RESERVATION;

/*!
 MobileAppTracking pre-defined event string "search"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SEARCH;

/*!
 MobileAppTracking pre-defined event string "share"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SHARE;

/*!
 MobileAppTracking pre-defined event string "spent_credits"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SPENT_CREDITS;

/*!
 MobileAppTracking pre-defined event string "tutorial_complete"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_TUTORIAL_COMPLETE;


/*!
 An event to be measured using MobileAppTracker. Allows various properties to be set for each individual instance.
 */
@interface MATEvent : NSObject

/*!
 Name of the event
 */
@property (nonatomic, copy, readonly) NSString *eventName;

/*!
 Event ID of the event as defined on the MobileAppTracking dashboard
 */
@property (nonatomic, assign, readonly) NSInteger eventId;

/*!
 An array of MATEventItem items
 */
@property (nonatomic, copy) NSArray *eventItems;

/*!
 Revenue associated with the event
 */
@property (nonatomic, assign) CGFloat revenue;

/*!
 Currency code associated with the event
 */
@property (nonatomic, copy) NSString *currencyCode;

/*!
 Reference ID associated with the event
 */
@property (nonatomic, copy) NSString *refId;

/*!
 App Store in-app-purchase transaction receipt data
 */
@property (nonatomic, copy) NSData *receipt;

/*!
 Content type associated with the event (e.g., @"shoes")
 */
@property (nonatomic, copy) NSString *contentType;

/*!
 Content ID associated with the event (International Article Number
 (EAN) when applicable, or other product or content identifier)
 */
@property (nonatomic, copy) NSString *contentId;

/*!
 Search string associated with the event
 */
@property (nonatomic, copy) NSString *searchString;

/*!
 Transaction state of App Store in-app-purchase
 */
@property (nonatomic, assign) NSInteger transactionState;

/*!
 Rating associated with the event (e.g., a user rating an item)
 */
@property (nonatomic, assign) CGFloat rating;

/*!
 Level associated with the event (e.g., for a game)
 */
@property (nonatomic, assign) NSInteger level;

/*!
 Quantity associated with the event (e.g., number of items)
 */
@property (nonatomic, assign) NSUInteger quantity;

/*!
 First date associated with the event (e.g., user's check-in time)
 */
@property (nonatomic, strong) NSDate *date1;

/*!
 Second date associated with the next action (e.g., user's check-out time)
 */
@property (nonatomic, strong) NSDate *date2;

/*!
 First custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute1;

/*!
 Second custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute2;

/*!
 Third custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute3;

/*!
 Fourth custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute4;

/*!
 Fifth custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute5;

/*!
 Create a new event with the specified event name.
 
 @param eventName Name of the event
 */
+ (instancetype)eventWithName:(NSString *)eventName;

/*!
 Create a new event with the specified event id that corresponds to an event defined on the MobileAppTracking dashboard.
 
 @param eventId Event ID of the event as defined on the MobileAppTracking dashboard
 */
+ (instancetype)eventWithId:(NSInteger)eventId;

@end