//
//  MATEvent.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 3/10/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AvailabilityMacros.h>

@class MATEventItem;

/*!
 MobileAppTracking pre-defined event string "achievement_unlocked"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ACHIEVEMENT_UNLOCKED DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "add_to_cart"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ADD_TO_CART DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "add_to_wishlist"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ADD_TO_WISHLIST DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "added_payment_info"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_ADDED_PAYMENT_INFO DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "checkout_initiated"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_CHECKOUT_INITIATED DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "content_view"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_CONTENT_VIEW DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "invite"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_INVITE DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "level_achieved"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_LEVEL_ACHIEVED DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "login"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_LOGIN DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "purchase"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_PURCHASE DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "rated"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_RATED DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "registration"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_REGISTRATION DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "reservation"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_RESERVATION DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "search"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SEARCH DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "session". Corresponds to MobileAppTracker measureSession method.
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SESSION DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "share"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SHARE DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "spent_credits"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_SPENT_CREDITS DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");

/*!
 MobileAppTracking pre-defined event string "tutorial_complete"
 */
FOUNDATION_EXPORT NSString *const MAT_EVENT_TUTORIAL_COMPLETE DEPRECATED_MSG_ATTRIBUTE("Please use corresponding constant from class TuneEvent");


/*!
 An event to be measured using MobileAppTracker. Allows various properties to be set for each individual instance.
 */
DEPRECATED_MSG_ATTRIBUTE("Please use class TuneEvent instead") @interface MATEvent : NSObject

/*!
 Name of the event
 */
@property (nonatomic, copy, readonly) NSString *eventName DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Event ID of the event as defined on the MobileAppTracking dashboard
 */
@property (nonatomic, assign, readonly) NSInteger eventId DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 An array of MATEventItem items
 */
@property (nonatomic, copy) NSArray *eventItems DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Revenue associated with the event
 */
@property (nonatomic, assign) CGFloat revenue DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Currency code associated with the event
 */
@property (nonatomic, copy) NSString *currencyCode DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Reference ID associated with the event
 */
@property (nonatomic, copy) NSString *refId DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 App Store in-app-purchase transaction receipt data
 */
@property (nonatomic, copy) NSData *receipt DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Content type associated with the event (e.g., @"shoes")
 */
@property (nonatomic, copy) NSString *contentType DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Content ID associated with the event (International Article Number
 (EAN) when applicable, or other product or content identifier)
 */
@property (nonatomic, copy) NSString *contentId DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Search string associated with the event
 */
@property (nonatomic, copy) NSString *searchString DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Transaction state of App Store in-app-purchase
 */
@property (nonatomic, assign) NSInteger transactionState DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Rating associated with the event (e.g., a user rating an item)
 */
@property (nonatomic, assign) CGFloat rating DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Level associated with the event (e.g., for a game)
 */
@property (nonatomic, assign) NSInteger level DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Quantity associated with the event (e.g., number of items)
 */
@property (nonatomic, assign) NSUInteger quantity DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 First date associated with the event (e.g., user's check-in time)
 */
@property (nonatomic, strong) NSDate *date1 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Second date associated with the next action (e.g., user's check-out time)
 */
@property (nonatomic, strong) NSDate *date2 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 First custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute1 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Second custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute2 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Third custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute3 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Fourth custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute4 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");

/*!
 Fifth custom string attribute for the event
 */
@property (nonatomic, copy) NSString *attribute5 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEvent");


/*!
 Create a new event with the specified event name.
 
 @param eventName Name of the event
 */
+ (instancetype)eventWithName:(NSString *)eventName DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TuneEvent");;

/*!
 Create a new event with the specified event id that corresponds to an event defined on the MobileAppTracking dashboard.
 
 @param eventId Event ID of the event as defined on the MobileAppTracking dashboard
 */
+ (instancetype)eventWithId:(NSInteger)eventId DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TuneEvent");;

@end
