//
//  TuneEvent+Internal.h
//  Tune
//
//  Created by Harshal Ogale on 5/5/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneEvent.h"

@class TuneLocation;

@interface TuneEvent ()

@property(nonatomic, copy) NSString *eventName;

@property(nonatomic, copy, readonly) NSString *actionName;
@property(nonatomic, strong) NSDictionary *cworksClick;            // key, value pair
@property(nonatomic, strong) NSDictionary *cworksImpression;       // key, value pair
@property(nonatomic, copy) NSString *iBeaconRegionId;              // KEY_GEOFENCE_NAME
@property(nonatomic, strong) TuneLocation *location;
@property(nonatomic, assign) BOOL postConversion;                  // KEY_POST_CONVERSION

// The assoctiated properties in the header, as primitive numbers, can't be set to nil
// For our purposes we need to know if a variable wasn't set -- by checking for nil
@property(nonatomic, copy) NSNumber *eventIdObject;
@property(nonatomic, copy) NSNumber *revenueObject;
@property(nonatomic, copy) NSNumber *transactionStateObject;
@property(nonatomic, copy) NSNumber *ratingObject;
@property(nonatomic, copy) NSNumber *levelObject;
@property(nonatomic, copy) NSNumber *quantityObject;

@property(nonatomic, strong) NSMutableArray *tags;
@property(nonatomic, strong) NSMutableSet *addedTags;
@property(nonatomic, copy) NSSet *notAllowedAttributes;

// These aren't currently enabled, but will be in a later release
- (void)addTag:(NSString *)name withBooleanValue:(NSNumber *)value;
- (void)addTag:(NSString *)name withStringValue:(NSString *)value hashed:(BOOL)shouldHash;
- (void)addTag:(NSString *)name withVersionValue:(NSString *)value;

@end
