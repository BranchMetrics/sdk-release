//
//  TuneConnectedModeManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 10/12/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneConnectedModeManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneState.h"
#import "TuneApi.h"
#import "TuneHttpRequest.h"
#import "TunePowerHookManager.h"
#import "TuneDeepActionManager.h"
#import "TunePowerHookValue.h"
#import "TuneDeepAction.h"
#import "TunePlaylistManager.h"
#import "TuneDeviceDetails.h"
#import "TuneBaseMessageFactory.h"
#import "TuneJSONUtils.h"
#import "TuneUtils.h"

NSString *const POWER_HOOKS_KEY            = @"power_hooks";
NSString *const DEEP_ACTIONS_KEY           = @"deep_actions";

NSString *const DEVICE_INFO_KEY            = @"device_info";
NSString *const SUPPORTED_DEVICES_KEY      = @"supported_devices";
NSString *const SUPPORTED_ORIENTATIONS_KEY = @"supported_orientations";

@interface TuneConnectedModeManager ()

@property (assign, nonatomic) BOOL hasConnected;

@end

@implementation TuneConnectedModeManager

#pragma mark - Bring up/down

- (void)bringUp {
    [self registerSkyhooks];
}

- (void)bringDown {
    [self unregisterSkyhooks];
}

#pragma mark - Skyhook Registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleConnection:)
                                              name:TuneSessionManagerSessionDidStart
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleConnection:)
                                              name:TuneStateTMAConnectedModeTurnedOn
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleDisconnection:)
                                              name:TuneSessionManagerSessionDidEnd
                                            object:nil];
}

#pragma Connect/Disconnect

- (void)handleConnection:(TuneSkyhookPayload *)payload {
    if ([TuneState isInConnectedMode] && !_hasConnected) {
        _hasConnected = YES;
        
        [self showConnectedModeAlert];
        [self sendConnectDeviceRequest];
        [self sendSyncRequest];
        [self setupPreviewingInAppMessage];
    }
}

- (void)handleDisconnection:(TuneSkyhookPayload *)payload {
    if ([TuneState isInConnectedMode]) {
        
        [TuneState updateConnectedMode:NO];
        _hasConnected = NO;
        
        // In case we failed to show the preview message don't try to show it later.
        [[TuneSkyhookCenter defaultCenter] removeObserver:self
                                                     name:TunePlaylistManagerCurrentPlaylistChanged
                                                   object:nil];
        
        [[TuneApi getDisconnectDeviceRequest] performAsynchronousRequestWithCompletionBlock:^(TuneHttpResponse *response) {
            if (response.wasSuccessful) {
                InfoLog(@"SDK successfully disconnected with Marketing Automation servers.");
            } else {
                ErrorLog(@"SDK failed to disconnect with Marketing Automation servers. Error: %@", [response.error localizedDescription]);
            }
        }];
    }
}

- (void)sendSyncRequest {
    // Only sync registered power hooks (contains default value, friendly name)
    NSMutableArray *validPowerHooks = [[NSMutableArray alloc] init];
    for (TunePowerHookValue *powerHook in [self.tuneManager.powerHookManager getPowerHooks]) {
        if (powerHook.defaultValue != nil && powerHook.friendlyName != nil) {
            [validPowerHooks addObject:powerHook];
        }
    }
    NSArray *powerHooks =  [validPowerHooks copy];
    NSArray *deepActions = [self.tuneManager.deepActionManager getDeepActions];
    
    NSMutableArray *serializedPowerHooks  = @[].mutableCopy;
#if IDE_XCODE_7_OR_HIGHER
    [powerHooks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
#else
    [powerHooks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
#endif
        [serializedPowerHooks addObject:[(TunePowerHookValue *)obj toDictionary]];
    }];
    
    NSMutableArray *serializedDeepActions = @[].mutableCopy;
#if IDE_XCODE_7_OR_HIGHER
    [deepActions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
#else
    [deepActions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
#endif
        [serializedDeepActions addObject:[(TuneDeepAction *)obj toDictionary]];
    }];
    
    NSMutableDictionary *deviceInfo = @{}.mutableCopy;
    deviceInfo[SUPPORTED_ORIENTATIONS_KEY] = [TuneDeviceDetails getSupportedDeviceOrientationsString]; // Portrait|UpsideDown|LandscapeLeft|LandscapeRight
    deviceInfo[SUPPORTED_DEVICES_KEY] = [TuneDeviceDetails getSupportedDeviceTypesString]; // iPhone|iPad
    
    NSMutableDictionary *combined = @{}.mutableCopy;
    combined[POWER_HOOKS_KEY]  = serializedPowerHooks;
    combined[DEEP_ACTIONS_KEY] = serializedDeepActions;
    combined[DEVICE_INFO_KEY]  = deviceInfo;
    
    TuneHttpRequest *request = [TuneApi getSyncSDKRequest:combined];
    [request performAsynchronousRequestWithCompletionBlock:^(TuneHttpResponse *response) {
        if (response.wasSuccessful) {
            InfoLog(@"SDK successfully synced with Marketing Automation servers.");
        } else {
            ErrorLog(@"SDK failed to sync with Marketing Automation server. Error: %@", [response.error localizedDescription]);
        }
    }];
}

- (void)showConnectedModeAlert {
    __weak typeof(self) weakSelf = self;
    [TuneUtils showAlertWithTitle:@"Success!"
                          message:@"This device is now in connected mode."
                  completionBlock:^{
                      InfoLog(@"Hit okay button, letting in app message be shown.");
                      [weakSelf fetchConnectedPlaylist];
                  }];
}

- (void)sendConnectDeviceRequest {
    [[TuneApi getConnectDeviceRequest] performAsynchronousRequestWithCompletionBlock:^(TuneHttpResponse *response) {
        if (response.wasSuccessful) {
            InfoLog(@"SDK successfully connected with Marketing Automation servers.");
        } else {
            ErrorLog(@"SDK failed to connect with Marketing Automation servers. Error: %@", [response.error localizedDescription]);
        }
    }];
}

- (void)setupPreviewingInAppMessage {
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(triggerConnectedModePreview:)
                                              name:TunePlaylistManagerCurrentPlaylistChanged
                                            object:nil
                                          priority:TuneSkyhookPriorityIrrelevant];
}

- (void)triggerConnectedModePreview:(TuneSkyhookPayload *)payload {
    TunePlaylist *playlist = [payload userInfo][TunePayloadNewPlaylist];
    // If we have a In-App message in our Playlist then we're previewing an In-App Message
    if (playlist.fromConnectedMode) {
        if (playlist.inAppMessages.count == 1) {
            TuneBaseMessageFactory *messageFactory = [[playlist.inAppMessages allValues] firstObject];
            // Wait a short bit of time otherwise the message will dissapear immediately.
            //   This is likely because the message gets attached to the dismissing 'Connected...' popup
            [messageFactory performSelector:@selector(buildAndShowMessage) withObject:nil afterDelay:0.6];
        }
        
        // Remove our observer.
        [[TuneSkyhookCenter defaultCenter] removeObserver:self
                                                     name:TunePlaylistManagerCurrentPlaylistChanged
                                                   object:nil];
    }
}

- (void)fetchConnectedPlaylist {
    // Force the playlist manager to go offline
    [[TuneManager currentManager].playlistManager didEnterBackgroundSkyhook:nil];
    [[TuneApi getConnectedPlaylistRequest] performAsynchronousRequestWithCompletionBlock:^(TuneHttpResponse *response) {
        if (response.wasSuccessful) {
            InfoLog(@"SDK successfully got last playlist (for connected mode) from Marketing Automation servers.");
            TunePlaylist *newPlaylist = [TunePlaylist playlistWithDictionary:response.responseDictionary];
            newPlaylist.fromConnectedMode = YES;
            
            if ([TuneManager currentManager].configuration.echoPlaylists) {
                NSLog(@"Got last connected playlist:\n%@", [TuneJSONUtils createPrettyJSONFromDictionary:response.responseDictionary withSecretTMADepth:nil]);
            }
            // This fires off a process that will result in the playlist being updated.
            [newPlaylist retrieveInAppMessageAssets];
        } else {
            ErrorLog(@"SDK failed to get last playlist (for connected mode) from Marketing Automation servers. Error: %@", [response.error localizedDescription]);
        }
    }];
}

@end
