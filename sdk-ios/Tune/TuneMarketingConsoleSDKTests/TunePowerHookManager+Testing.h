//
//  TunePowerHookManager+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TunePowerHookManager.h"

@interface TunePowerHookManager (Testing)
- (void)reset;
+ (NSDictionary *)getSingleValuePowerHooks;
//- (ARCodeBlock *)_getBlockById:(NSString *)blockId;
//- (NSArray*)_getBlocks;
//- (void)registerBlockWithId:(NSString *)blockId data:(NSDictionary *)data andBlock:(void (^)(NSDictionary *extra_data, id context))block;
//- (void)executeBlockWithId:(NSString *)blockId data:(NSDictionary *)data context:(id)context andBlock:(void (^)(NSDictionary *, id))block;
@end
