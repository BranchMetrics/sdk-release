//
//  TunePowerHookManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/27/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePowerHookManager.h"
#import "TuneManager.h"
#import "TuneSkyhookPayload.h"
#import "TuneStringUtils.h"
#import "TunePowerHookValue.h"
#import "TuneArrayUtils.h"
#import "TunePlaylist.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneSkyhookConstants.h"
#import "TuneCallbackBlock.h"
#import "TunePowerHookExperimentDetails+Internal.h"
#import "TuneUtils.h"
#import "TuneState.h"

@implementation TunePowerHookManager

NSDictionary *_phookHash;

NSObject *phookDictLock;

NSArray *_phookChangedBlocks;

NSOperationQueue *powerhooksCallbackQueue;

#pragma mark - Initialization

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        powerhooksCallbackQueue = [NSOperationQueue new];
        phookDictLock = [[NSObject alloc] init];
        [self reset];
    }
    
    return self;
}

- (void)bringUp {
    [self registerSkyhooks];
}

- (void)bringDown {
    [self unregisterSkyhooks];
    [self revertToDefaults:nil];
}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(afterCurrentPlaylistChange:) name:TunePlaylistManagerCurrentPlaylistChanged object:nil priority:TuneSkyhookPriorityIrrelevant];
}

#pragma mark - Managment of Class

/* This is intentionally not exposed as part of the public headers, but it is used for tests and init */
- (void)reset {
    @synchronized(phookDictLock){
        _phookHash = [[NSDictionary alloc] init];
        _phookChangedBlocks = [[NSArray alloc] init];
    }
}

- (void)revertToDefaults:(TuneSkyhookPayload *)payload {
    // reset power hook variables to default values
    NSDictionary *values = [TunePowerHookManager getPowerHooksDictionary];
    for (NSString *hookId in values) {
        [self setValueForHookById:hookId value:[values[hookId] defaultValue]];
    }
}

#pragma mark - Access the PowerHooks

+ (TunePowerHookValue *)getPowerHook:(NSString *)key {
    TunePowerHookValue *result = nil;
    
    @synchronized(phookDictLock) {
        if (key != nil && _phookHash[key] != nil) {
            result = _phookHash[key];
        }
    }
    
    return result;
}

+ (NSDictionary *)getPowerHooksDictionary {
    NSDictionary *result = nil;
    
    @synchronized(phookDictLock) {
        result = _phookHash.copy;
    }
    
    return result;
}

- (NSArray *)getPowerHooks {
    @synchronized(phookDictLock) {
        return _phookHash.allValues.copy;
    }
}

+ (void)setPowerHook:(TunePowerHookValue *)value forKey:(NSString *)key {
    @synchronized(phookDictLock) {
        NSMutableDictionary *updatedPowerHookHash = _phookHash.mutableCopy;
        [updatedPowerHookHash setValue:value forKey:key];
        _phookHash = [NSDictionary dictionaryWithDictionary:updatedPowerHookHash];
    }
}

#pragma mark - Registering Power Hooks


- (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue description:(NSString *)description approvedValues:(NSArray *)approvedValues {
    
    NSString *cleanHook = [TuneStringUtils scrubNameForMongo:hookId];
    
    if ([TuneStringUtils isBlank:cleanHook] || [TuneStringUtils isBlank:friendlyName] || defaultValue == nil) {
        ErrorLog(@"hookId and friendlyName must not be empty and default value cannot be nil. Not registering hookId:%@ friendlyName:%@ with defaultValue:%@", hookId, friendlyName, defaultValue);
        return;
    } else if (approvedValues != nil && approvedValues.count < 1) {
        ErrorLog(@"Attempted to register Tune Power Hook %@ with an empty approvedValues array. The approvedValues array must not be empty as this wouldn't allow any changes on the TMC side.", cleanHook);
        return;
    } else if (approvedValues != nil && ![TuneArrayUtils areAllElementsOfArray:approvedValues ofType:[NSString class]]) {
        ErrorLog(@"Attempted to register Tune Power Hook %@ with an approvedValues array that included a value with type other than NSString. The approvedValues array can only contain elements of type NSString.", cleanHook);
        return;
    }
    
    // If we've got a value during registration then that means we've loaded a power hook from disk.
    // We want to use that value and merge it with the values supplied during registration.
    NSString *currentValue = nil;
    if ([TunePowerHookManager getPowerHook:cleanHook]) {
        currentValue = [TunePowerHookManager getPowerHook:cleanHook].value;
    }
    
    
    NSMutableDictionary *dictionary = @{POWERHOOKVALUE_NAME:cleanHook,
                                        POWERHOOKVALUE_DEFAULT_VALUE:defaultValue,
                                        POWERHOOKVALUE_FRIENDLY_NAME:friendlyName}.mutableCopy;
    
    if (currentValue != nil) {
        [dictionary setObject:currentValue forKey:POWERHOOKVALUE_VALUE];
    } else {
        [dictionary setObject:defaultValue forKey:POWERHOOKVALUE_VALUE];
    }
    
    if (description != nil) {
        [dictionary setObject:description forKey:POWERHOOKVALUE_DESCRIPTION];
    }
        
    if (approvedValues != nil) {
        [dictionary setObject:approvedValues forKey:POWERHOOKVALUE_APPROVED_VALUES];
    }
        
    TunePowerHookValue *powerHookValue = [[TunePowerHookValue alloc] initWithDictionary:[NSDictionary dictionaryWithDictionary:dictionary]];
    [TunePowerHookManager setPowerHook:powerHookValue forKey:cleanHook];
}

- (NSString *)getValueForHookById:(NSString *)hookId {
    NSString *cleanHook = [TuneStringUtils scrubNameForMongo:hookId];
    NSString *value = @"";
    
    TunePowerHookValue *powerHookValue = [TunePowerHookManager getPowerHook:cleanHook];
    
    if(powerHookValue != nil) {
        value = powerHookValue.value;
    }
    
    return value;
}

#pragma mark - Setting Value For Power Hook

- (void)setValueForHookById:(NSString *)hookId value:(NSString *)value {
    NSString *cleanHook = [TuneStringUtils scrubNameForMongo:hookId];
    
    TunePowerHookValue *powerHookValue = [TunePowerHookManager getPowerHook:cleanHook];
    
    if (powerHookValue != nil) {
        TunePowerHookValue *newPowerHookValue = [powerHookValue cloneWithNewValue:value];
        
        [TunePowerHookManager setPowerHook:newPowerHookValue forKey:cleanHook];
    }
}

+ (BOOL)setValueForHookById:(NSString *)hookId withPlaylistDictionary:(NSDictionary *)dictionary {
    if ([TuneState isTMADisabled]) { return NO; }
    
    BOOL notifyOnChange = NO;
    
    TunePowerHookValue *existingPowerHookValue = [TunePowerHookManager getPowerHook:hookId];
    
    NSMutableDictionary *newPhookDict = dictionary.mutableCopy;
    if (existingPowerHookValue != nil) {
        @try {
            [newPhookDict setValue:hookId forKey:POWERHOOKVALUE_NAME];
            [newPhookDict setValue:existingPowerHookValue.defaultValue forKey:POWERHOOKVALUE_DEFAULT_VALUE];
            [newPhookDict setValue:existingPowerHookValue.friendlyName forKey:POWERHOOKVALUE_FRIENDLY_NAME];
            
            if (existingPowerHookValue.phookDescription != nil) {
                [newPhookDict setValue:existingPowerHookValue.phookDescription forKey:POWERHOOKVALUE_DESCRIPTION];
            }
            
            if (existingPowerHookValue.approvedValues != nil) {
                [newPhookDict setValue:existingPowerHookValue.approvedValues forKey:POWERHOOKVALUE_APPROVED_VALUES];
            }
        } @catch (NSException *exception) {
            ErrorLog(@"Failed to serialize new Power Hook Value. Exception: %@", [exception reason]);
        }
        
        // We create a new TunePowerHookValue and replace existing.
        // If we didn't do this and merged existing with new we could be in a weird state
        TunePowerHookValue *newPowerHookValue = [[TunePowerHookValue alloc] initWithDictionary:newPhookDict];
        [TunePowerHookManager setPowerHook:newPowerHookValue forKey:hookId];
        
        // If the values are not equal send a notification out that the variable has changed
        if(![newPowerHookValue.value isEqualToString:existingPowerHookValue.value]) {
            notifyOnChange = YES;
        }
    } else {
        
        // No Power Hook with this hookId has been registered yet. This is either due to the customer
        // removing the Power Hook from their App (fine to regsiter since they won't use) or we're loading
        // this playlist from disk and the AppDelegate call hasn't happened yet.
        TunePowerHookValue *newPowerHookValue = [[TunePowerHookValue alloc] initWithDictionary:newPhookDict];
        [TunePowerHookManager setPowerHook:newPowerHookValue forKey:hookId];
        
        // Being explicit here: We don't want a power hooks changed block to be fired.
        notifyOnChange = NO;
    }
    
    return notifyOnChange;
}

#pragma mark - Updating Power Hooks via Playlist

- (void)updatePowerHooksFromPlaylist:(TunePlaylist *)playlist playlistFromDisk:(BOOL)playlistFromDisk {
    // If TMA is disabled then don't update the powerhooks
    if ([TuneState isTMADisabled]) { return; }
    
    __block BOOL notifyOnPowerHookChanges = NO;
    
    NSDictionary *powerHookSingleValues = playlist.powerHooks;
    [powerHookSingleValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([TunePowerHookManager setValueForHookById:key withPlaylistDictionary:obj]){
            notifyOnPowerHookChanges = YES;
        }
    }];
    
    if(!playlistFromDisk){
      if(notifyOnPowerHookChanges){
          [self executeOnPowerHooksChangedBlocks];
      }
    }
}

- (void)afterCurrentPlaylistChange:(TuneSkyhookPayload *)payload {
    TunePlaylist *activePlaylist = [payload userInfo][TunePayloadNewPlaylist];
    
    NSNumber *playlistFromDiskNumber = ((NSNumber *)[payload userInfo][TunePayloadPlaylistLoadedFromDisk]);
    BOOL playlistFromDisk = (playlistFromDiskNumber != nil) && ([playlistFromDiskNumber boolValue]);
    
    [self updatePowerHooksFromPlaylist:activePlaylist playlistFromDisk:playlistFromDisk];
}

#pragma mark - Power Hooks Changed

- (void)onPowerHooksChanged:(void (^)())block {
    TuneCallbackBlock *blockCallback = [[TuneCallbackBlock alloc] initWithCallbackBlock:block fireOnce:NO];
    
    @synchronized(phookDictLock){
        NSMutableArray *updatedPowerHooksChangedBlocks = _phookChangedBlocks.mutableCopy;
        [updatedPowerHooksChangedBlocks addObject:blockCallback];
        _phookChangedBlocks = [NSArray arrayWithArray:updatedPowerHooksChangedBlocks];
    }
}

- (void)executeOnPowerHooksChangedBlocks {
    NSArray *callbacks;
    
    @synchronized(phookDictLock) {
        callbacks = _phookChangedBlocks.copy;
    }
    
    for (TuneCallbackBlock *callback in callbacks) {
        [powerhooksCallbackQueue addOperationWithBlock:^{
            [callback executeBlock];
        }];
    }
}

#pragma mark - Testing Helpers

+ (NSDictionary *)getSingleValuePowerHooks {
    @synchronized(phookDictLock){
        NSMutableDictionary *allSingleValues = [[NSMutableDictionary alloc] init];
        
        NSDictionary *values = [TunePowerHookManager getPowerHooksDictionary];
        for (NSString *hookId in values) {
            [allSingleValues setValue:@{ POWERHOOKVALUE_FRIENDLY_NAME : [values[hookId] friendlyName],
                                         POWERHOOKVALUE_DEFAULT_VALUE : [values[hookId] defaultValue] } forKey:hookId];
        }
        
        return allSingleValues;
    }
}

@end
