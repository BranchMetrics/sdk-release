//
//  TuneEventItem+Internal.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/3/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneEventItem.h"

@interface TuneEventItem ()

@property(nonatomic, strong) NSMutableArray *tags;
@property(nonatomic, strong) NSMutableSet *addedTags;
@property(nonatomic, copy) NSSet *notAllowedAttributes;

// We do not do anything currently with the tune event items, so don't bother letting users set tags for them 
- (void)addTag:(NSString *)name withStringValue:(NSString *)value;
- (void)addTag:(NSString *)name withDateTimeValue:(NSDate *)value;
- (void)addTag:(NSString *)name withNumberValue:(NSNumber *)value;
- (void)addTag:(NSString *)name withGeolocationValue:(TuneLocation *)value;

// These aren't currently enabled, but will be in a later release
- (void)addTag:(NSString *)name withBooleanValue:(NSNumber *)value;
- (void)addTag:(NSString *)name withStringValue:(NSString *)value hashed:(BOOL)shouldHash;
- (void)addTag:(NSString *)name withVersionValue:(NSString *)value;

@end
