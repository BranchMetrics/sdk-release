//
//  MATEventItem.m
//  MobileAppTracker
//
//  Created by John Bender on 1/10/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATEventItem.h"
#import "MATKeyStrings.h"

@implementation MATEventItem

@synthesize item, unitPrice, quantity, revenue, attribute1, attribute2, attribute3, attribute4, attribute5;

+ (MATEventItem *)eventItemWithName:(NSString *)name unitPrice:(float)unitPrice quantity:(int)quantity
{
    return [MATEventItem eventItemWithName:name unitPrice:unitPrice quantity:quantity revenue:(unitPrice * quantity) attribute1:nil attribute2:nil attribute3:nil attribute4:nil attribute5:nil];
}

+ (MATEventItem *)eventItemWithName:(NSString *)name unitPrice:(float)unitPrice quantity:(int)quantity revenue:(float)revenue
{
    return [MATEventItem eventItemWithName:name unitPrice:unitPrice quantity:quantity revenue:revenue attribute1:nil attribute2:nil attribute3:nil attribute4:nil attribute5:nil];
}

+ (MATEventItem *)eventItemWithName:(NSString *)name
                         attribute1:(NSString *)attribute1
                         attribute2:(NSString *)attribute2
                         attribute3:(NSString *)attribute3
                         attribute4:(NSString *)attribute4
                         attribute5:(NSString *)attribute5
{
    return [MATEventItem eventItemWithName:name unitPrice:0 quantity:0 revenue:0 attribute1:attribute1 attribute2:attribute2 attribute3:attribute3 attribute4:attribute4 attribute5:attribute5];
}

+ (MATEventItem *)eventItemWithName:(NSString *)name unitPrice:(float)unitPrice quantity:(int)quantity revenue:(float)revenue
                         attribute1:(NSString *)attribute1
                         attribute2:(NSString *)attribute2
                         attribute3:(NSString *)attribute3
                         attribute4:(NSString *)attribute4
                         attribute5:(NSString *)attribute5
{
    MATEventItem *eventItem = [[MATEventItem alloc] init];
    
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

+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items
{
    NSMutableArray *arr = [NSMutableArray array];
    
    for (MATEventItem *item in items)
    {
        [arr addObject:[item dictionary]];
    }
    
    return arr;
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // add each property from item to dictionary
    
    if([self item] && [NSNull null] != (id)[self item])
    {
        [dict setValue:[self item] forKey:KEY_ITEM];
    }
    
    [dict setValue:[NSString stringWithFormat:@"%f", [self unitPrice]] forKey:KEY_UNIT_PRICE];
    [dict setValue:[NSString stringWithFormat:@"%d", [self quantity]] forKey:KEY_QUANTITY];
    [dict setValue:[NSString stringWithFormat:@"%f", [self revenue]] forKey:KEY_REVENUE];
    
    if([self attribute1] && [NSNull null] != (id)[self attribute1])
    {
        [dict setValue:[self attribute1] forKey:KEY_ATTRIBUTE_SUB1];
    }
    
    if([self attribute2] && [NSNull null] != (id)[self attribute2])
    {
        [dict setValue:[self attribute2] forKey:KEY_ATTRIBUTE_SUB2];
    }
    
    if([self attribute3] && [NSNull null] != (id)[self attribute3])
    {
        [dict setValue:[self attribute3] forKey:KEY_ATTRIBUTE_SUB3];
    }
    
    if([self attribute4] && [NSNull null] != (id)[self attribute4])
    {
        [dict setValue:[self attribute4] forKey:KEY_ATTRIBUTE_SUB4];
    }
    
    if([self attribute5] && [NSNull null] != (id)[self attribute5])
    {
        [dict setValue:[self attribute5] forKey:KEY_ATTRIBUTE_SUB5];
    }
    
    return dict;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> %@", [self class], self, [self dictionary]];
}

@end