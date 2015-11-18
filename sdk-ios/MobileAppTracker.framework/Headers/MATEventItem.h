//
//  MATEventItem.h
//  MobileAppTracker
//
//  Created by John Bender on 3/10/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvailabilityMacros.h>

/*!
 MATEventItem represents event items for use with MAT events.
 */
DEPRECATED_MSG_ATTRIBUTE("Please use class TuneEventItem instead") @interface MATEventItem : NSObject

/** @name MATEventItem Properties */
/*!
 name of the event item
 */
@property (nonatomic, copy) NSString *item DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 unit price of the event item
 */
@property (nonatomic, assign) float unitPrice DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 quantity of the event item
 */
@property (nonatomic, assign) int quantity DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 revenue of the event item
 */
@property (nonatomic, assign) float revenue DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");

/*!
 an extra parameter that corresponds to attribute_sub1 property of the event item
 */
@property (nonatomic, copy) NSString *attribute1 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 an extra parameter that corresponds to attribute_sub2 property of the event item
 */
@property (nonatomic, copy) NSString *attribute2 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 an extra parameter that corresponds to attribute_sub3 property of the event item
 */
@property (nonatomic, copy) NSString *attribute3 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 an extra parameter that corresponds to attribute_sub4 property of the event item
 */
@property (nonatomic, copy) NSString *attribute4 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");
/*!
 an extra parameter that corresponds to attribute_sub5 property of the event item
 */
@property (nonatomic, copy) NSString *attribute5 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding property from class TuneEventItem");


/** @name Methods to create MATEventItem objects.*/

/*!
 Method to create an event item. Revenue will be calculated using (quantity * unitPrice).
 
 @param name name of the event item
 @param unitPrice unit price of the event item
 @param quantity quantity of the event item
 */
+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(float)unitPrice quantity:(int)quantity DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TuneEventItem");

/*!
 Method to create an event item.
 @param name name of the event item
 @param unitPrice unit price of the event item
 @param quantity quantity of the event item
 @param revenue revenue of the event item, to be used instead of (quantity * unitPrice)
 */
+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(float)unitPrice quantity:(int)quantity revenue:(float)revenue DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TuneEventItem");

/*!
 Method to create an event item.
 @param name name of the event item
 @param attribute1 an extra parameter that corresponds to attribute_sub1 property of the event item
 @param attribute2 an extra parameter that corresponds to attribute_sub2 property of the event item
 @param attribute3 an extra parameter that corresponds to attribute_sub3 property of the event item
 @param attribute4 an extra parameter that corresponds to attribute_sub4 property of the event item
 @param attribute5 an extra parameter that corresponds to attribute_sub5 property of the event item
 */
+ (instancetype)eventItemWithName:(NSString *)name
                       attribute1:(NSString *)attribute1
                       attribute2:(NSString *)attribute2
                       attribute3:(NSString *)attribute3
                       attribute4:(NSString *)attribute4
                       attribute5:(NSString *)attribute5 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TuneEventItem");

/*!
 Method to create an event item.
 @param name name of the event item
 @param unitPrice unit price of the event item
 @param quantity quantity of the event item
 @param revenue revenue of the event item, to be used instead of (quantity * unitPrice)
 @param attribute1 an extra parameter that corresponds to attribute_sub1 property of the event item
 @param attribute2 an extra parameter that corresponds to attribute_sub2 property of the event item
 @param attribute3 an extra parameter that corresponds to attribute_sub3 property of the event item
 @param attribute4 an extra parameter that corresponds to attribute_sub4 property of the event item
 @param attribute5 an extra parameter that corresponds to attribute_sub5 property of the event item
 */
+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(float)unitPrice quantity:(int)quantity revenue:(float)revenue
                       attribute1:(NSString *)attribute1
                       attribute2:(NSString *)attribute2
                       attribute3:(NSString *)attribute3
                       attribute4:(NSString *)attribute4
                       attribute5:(NSString *)attribute5 DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TuneEventItem");
@end
