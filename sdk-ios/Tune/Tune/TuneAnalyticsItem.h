//
//  TuneAnalyticsItem.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/6/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneEventItem+Internal.h"

@interface TuneAnalyticsItem : NSObject

@property (nonatomic, copy) NSString *item;
@property (nonatomic, copy) NSString *unitPrice;
@property (nonatomic, copy) NSString *quantity;
@property (nonatomic, copy) NSString *revenue;

// Array of TuneAnalyticsVariable
@property (nonatomic, copy) NSArray *attributes;

+ (instancetype)analyticsItemFromTuneEventItem:(TuneEventItem *)event;

// Basic method to create a 'Custom' event.
- (id)initWithTuneEventItem:(TuneEventItem *)eventItem;

- (NSDictionary *)toDictionary;

@end
