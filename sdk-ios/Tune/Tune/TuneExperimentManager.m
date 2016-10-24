//
//  TuneExperimentManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneExperimentManager.h"
#import "TuneSkyhookCenter.h"
#import "TunePlaylist.h"
#import "TuneExperimentDetails+Internal.h"
#import "TuneInAppMessageExperimentDetails+Internal.h"
#import "TunePowerHookExperimentDetails+Internal.h"
#import "TunePowerHookValue.h"
#import "TuneState.h"
#import "TuneAnalyticsConstants.h"


@implementation TuneExperimentManager

NSDictionary *_powerHookExperimentDetails;
NSDictionary *_inAppExperimentDetails;
NSObject *dictLock;

#pragma mark - Initialization

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        dictLock = [[NSObject alloc] init];
        [self reset];
    }
    
    return self;
}

- (void)bringUp {
    [self registerSkyhooks];
}

- (void)bringDown {
    [self unregisterSkyhooks];
    [self reset];
}

- (void)reset {
    @synchronized(dictLock) {
        _powerHookExperimentDetails = [[NSDictionary alloc] init];
        _inAppExperimentDetails = [[NSDictionary alloc] init];
    }
}

#pragma mark - Skyhook Registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    // Updating the experiment details should happen before the power hooks so that the current experiments can be checked in the power hook callback
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handlePlaylistChanged:)
                                              name:TunePlaylistManagerCurrentPlaylistChanged
                                            object:nil
                                          priority:TuneSkyhookPrioritySecond];
}

#pragma mark - Skyhook Handlers

- (void)handlePlaylistChanged:(TuneSkyhookPayload *)payload {
    TunePlaylist *activePlaylist = [payload userInfo][TunePayloadNewPlaylist];
    
    NSMutableDictionary *powerHookExperimentDetailsTemp = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *inAppMessageExperimentDetailsTemp = [[NSMutableDictionary alloc] init];
    
    NSDictionary *experimentDetails = activePlaylist.experimentDetails;
    [experimentDetails enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *experimentId = key;
        NSDictionary *experiment = obj;
        
        // Find the appropriate power hook to go with the detail block
        // TODO: we may want to run this check against the active experiments.
        NSString *type = experiment[DetailDictionaryExperimentTypeKey];
        
        if ([type isEqualToString:DetailDictionaryTypePowerHook]) {
            NSDictionary *hooks = activePlaylist.powerHooks;
            for (NSString *hookId in hooks) {
                // Create the PowerHookValue temporarily so we can get some information from it.
                TunePowerHookValue *hookValue = [[TunePowerHookValue alloc] initWithDictionary:hooks[hookId]];
                if ([hookValue.experimentId isEqualToString:experimentId]) {
                    TunePowerHookExperimentDetails *details = [[TunePowerHookExperimentDetails alloc] initWithDetailsDictionary:experiment andPowerHookValue:hookValue];
                    powerHookExperimentDetailsTemp[hookId] = details;
                    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet
                                                            object:nil
                                                          userInfo:@{ TunePayloadSessionVariableName:TUNE_ACTIVE_VARIATION_ID,
                                                                      TunePayloadSessionVariableValue:[details currentVariantId],
                                                                      TunePayloadSessionVariableSaveType:TunePayloadSessionVariableSaveTypeProfile }];
                    break;
                }
            }
        } else if ([type isEqualToString:DetailDictionaryTypeInApp]) {
            TuneInAppMessageExperimentDetails *details = [[TuneInAppMessageExperimentDetails alloc] initWithDetailsDictionary:experiment];
            inAppMessageExperimentDetailsTemp[experiment[DetailDictionaryExperimentNameKey]] = details;
        }
    }];

    @synchronized(dictLock) {
        _powerHookExperimentDetails = [powerHookExperimentDetailsTemp copy];
        _inAppExperimentDetails = [inAppMessageExperimentDetailsTemp copy];
    }
}

# pragma mark - Experiment Details

- (NSDictionary *)getPowerHookVariableExperimentDetails {
    NSDictionary *result = nil;
    @synchronized(dictLock) {
        result = [_powerHookExperimentDetails copy];
    }
    return result;
}

- (NSDictionary *)getInAppMessageExperimentDetails {
    NSDictionary *result = nil;
    @synchronized(dictLock) {
        result = [_inAppExperimentDetails copy];
    }
    return result;
}

@end
