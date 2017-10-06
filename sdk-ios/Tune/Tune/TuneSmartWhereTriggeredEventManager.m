//
//  TuneSmartWhereTriggeredEventManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 7/5/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import "TuneSmartWhereTriggeredEventManager.h"

@implementation TuneSmartWhereTriggeredEventManager

-(void)bringUp{
    [self registerSkyhooks];
}

-(void)bringDown{
    [self unregisterSkyhooks];
}

- (void)registerSkyhooks{
    if ([TuneSmartWhereHelper isSmartWhereAvailable]){
        [self unregisterSkyhooks];
       [[TuneSkyhookCenter defaultCenter] addObserver:self
                                              selector:@selector(handleTriggeredEvent:)
                                                  name:TuneCustomEventOccurred
                                                object:nil];
    }
    
}

- (void)handleTriggeredEvent:(TuneSkyhookPayload*)payload {
    if ([TuneSmartWhereHelper isSmartWhereAvailable]){
        TuneSmartWhereHelper *tuneSmartWhereHelper = [TuneSmartWhereHelper getInstance];
        [tuneSmartWhereHelper setAttributeValuesFromPayload:payload];
        [tuneSmartWhereHelper processMappedEvent:payload];
    }
}

- (void)unregisterSkyhooks{
        [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

@end
