//
//  TuneDeepActionManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneDeepActionManager.h"
#import "TuneDeepAction.h"
#import "TuneStringUtils.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookPayload.h"

@implementation TuneDeepActionManager

NSDictionary *_deepActions;
NSObject *deepActionDictLock;

#pragma mark - Initialization

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        _deepActions = [[NSDictionary alloc] init];
        deepActionDictLock = [[NSObject alloc] init];
    }
    
    return self;
}

- (void)bringUp {
    [self registerSkyhooks];
}

- (void)bringDown {
    [self unregisterSkyhooks];
}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleDeepActionCalled:) name:TuneDeepActionTriggered object:nil];
}

#pragma mark - Getters/Setters

+ (TuneDeepAction *)getDeepAction:(NSString *)key {
    TuneDeepAction *result = nil;
    
    @synchronized(deepActionDictLock) {
        if (_deepActions[key]!=nil) {
            result = _deepActions[key];
        }
    }
    
    return result;
}

- (NSArray *)getDeepActions {
    @synchronized(deepActionDictLock) {
        return _deepActions.allValues.copy;
    }
}

+ (void)setDeepAction:(TuneDeepAction *)value forKey:(NSString *)key {
    @synchronized(deepActionDictLock) {
        NSMutableDictionary *updatedDeepActions = _deepActions.mutableCopy;
        [updatedDeepActions setValue:value forKey:key];
        _deepActions = [NSDictionary dictionaryWithDictionary:updatedDeepActions];
    }
}

#pragma mark - Registration

- (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description data:(NSDictionary *)data approvedValues:(NSDictionary *)approvedValues andAction:(void (^)(NSDictionary *extra_data)) deepAction {
    
    NSString *cleanDeepActionId = [TuneStringUtils scrubNameForMongo:deepActionId];
    
    if ([TuneDeepActionManager getDeepAction:cleanDeepActionId]) {
        ErrorLog(@"Attempted to register duplicate Deep Action: %@.", cleanDeepActionId);
    } else if ([TuneStringUtils isBlank:cleanDeepActionId] || [TuneStringUtils isBlank:friendlyName]) {
        ErrorLog(@"deepActionId and friendlyName must not be empty. Not registering deepActionId:%@ friendlyName:%@", cleanDeepActionId, friendlyName);
    } else if (data == nil || deepAction == nil) {
        ErrorLog(@"The deepAction and data passed in must not be nil.");
    } else if (approvedValues != nil && ![TuneDeepAction validateApprovedValues:approvedValues]) {
        // Logging the error is handled by 'validateApprovedValues'
    } else {

        TuneDeepAction *action = [[TuneDeepAction alloc] initWithDeepActionId:cleanDeepActionId
                                                                 friendlyName:friendlyName
                                                                  description:description
                                                                       action:deepAction
                                                                  defaultData:data
                                                               approvedValues:approvedValues];
            
        [TuneDeepActionManager setDeepAction:action forKey:cleanDeepActionId];
    }
}

#pragma mark - Execute Deep Actions

- (void)executeDeepActionWithId:(NSString *)deepActionId andData:(NSDictionary *)data {
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(executeDeepActionWithId:andData:)
                       withObject:deepActionId
                       withObject:data];
        });
        
        return;
    }
    // if required, fix deep action id string format
    NSString *cleanDeepActionId = [TuneStringUtils scrubNameForMongo:deepActionId];
    
    TuneDeepAction *deepAction = [TuneDeepActionManager getDeepAction:cleanDeepActionId];
    if (deepAction == nil) {
        ErrorLog(@"Attempted to execute unregistered Deep Action: %@.", cleanDeepActionId);
        return;
    }
    
    NSMutableDictionary *completeData = [[NSMutableDictionary alloc] initWithDictionary:deepAction.defaultData copyItems:YES];
    
    if (data != nil) {
        [completeData addEntriesFromDictionary:data];
    }
    
    deepAction.action(completeData);
}

#pragma mark - Skyhook Observer

- (void)handleDeepActionCalled:(TuneSkyhookPayload *)payload {
    [self executeDeepActionWithId:[payload userInfo][TunePayloadDeepActionId]
                          andData:[payload userInfo][TunePayloadDeepActionData]];
}

@end
