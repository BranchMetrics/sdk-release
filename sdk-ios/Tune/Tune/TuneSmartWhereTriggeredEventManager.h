//
//  TuneSmartWhereTriggeredEventManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 7/5/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import "TuneModule.h"
#import "TuneSmartWhereHelper.h"
#import "TuneSkyhookCenter.h"

@interface TuneSmartWhereTriggeredEventManager : TuneModule

- (void)handleTriggeredEvent:(TuneSkyhookPayload*)payload;

@end
