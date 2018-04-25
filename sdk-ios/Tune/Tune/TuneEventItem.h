//
//  TuneEventItem.h
//  Tune
//
//  Created by John Bender on 3/10/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class TuneLocation;

/**
 TuneEventItem represents event items for use with Tune events.
 */
@interface TuneEventItem : NSObject


#pragma mark - TuneEventItem Properties

/**
 Name of the event item.
 */
@property(nonatomic, copy) NSString *item;

/**
 Unit price of the event item.
 */
@property(nonatomic, assign) CGFloat unitPrice;

/**
 Quantity of the event item.
 */
@property(nonatomic, assign) NSUInteger quantity;

/**
 Revenue of the event item.
 */
@property(nonatomic, assign) CGFloat revenue;

/**
 An extra parameter that corresponds to attribute_sub1 property of the event item.
 */
@property(nonatomic, copy) NSString *attribute1;

/**
 An extra parameter that corresponds to attribute_sub2 property of the event item.
 */
@property(nonatomic, copy) NSString *attribute2;

/**
 An extra parameter that corresponds to attribute_sub3 property of the event item.
 */
@property(nonatomic, copy) NSString *attribute3;

/**
 An extra parameter that corresponds to attribute_sub4 property of the event item.
 */
@property(nonatomic, copy) NSString *attribute4;

/**
 An extra parameter that corresponds to attribute_sub5 property of the event item.
 */
@property(nonatomic, copy) NSString *attribute5;


#pragma mark - Methods to create TuneEventItem objects

/**
 Method to create an event item. Revenue will be calculated using (quantity * unitPrice).

 @param name name of the event item
 @param unitPrice unit price of the event item
 @param quantity quantity of the event item
 */
+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(CGFloat)unitPrice quantity:(NSUInteger)quantity;

/**
 Method to create an event item.

 @param name name of the event item
 @param unitPrice unit price of the event item
 @param quantity quantity of the event item
 @param revenue revenue of the event item, to be used instead of (quantity * unitPrice)
 */
+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(CGFloat)unitPrice quantity:(NSUInteger)quantity revenue:(CGFloat)revenue;

/**
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
                       attribute5:(NSString *)attribute5;

/**
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
+ (instancetype)eventItemWithName:(NSString *)name unitPrice:(CGFloat)unitPrice quantity:(NSUInteger)quantity revenue:(CGFloat)revenue
                       attribute1:(NSString *)attribute1
                       attribute2:(NSString *)attribute2
                       attribute3:(NSString *)attribute3
                       attribute4:(NSString *)attribute4
                       attribute5:(NSString *)attribute5;

@end
