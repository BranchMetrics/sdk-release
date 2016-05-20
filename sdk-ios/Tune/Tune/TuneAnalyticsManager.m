//
//  TuneAnalyticsManager.m
//
//  Created by Daniel Koch on 5/9/12.
//  Copyright (c) 2012 TUNE, Inc. All rights reserved.
//

#import "TuneAnalyticsManager.h"

#import "TuneAnalyticsConstants.h"
#import "TuneAnalyticsEvent.h"
#import "TuneAnalyticsVariable.h"
#import "TuneDeeplink.h"
#import "TuneManager.h"
#import "TuneNotification.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneJSONUtils.h"
#import "TuneAnalyticsDispatchEventsOperation.h"
#import "TuneAnalyticsDispatchToConnectedModeOperation.h"
#import "TuneConfiguration.h"
#import "TuneUserProfile.h"
#import "TuneTriggerManager.h"
#import "UIViewController+TuneAnalytics.h"
#import "TuneState.h"
#import "TuneEvent+Internal.h"

static NSOperationQueue *_operationQueue = nil;

// Class extension to store the private properties.
@interface TuneAnalyticsManager() {
#if !TARGET_OS_WATCH
    UIBackgroundTaskIdentifier endSessionBgTask;
#endif
    NSMutableSet *sessionVariables;
    NSObject *sessionVariablesLock;
}

@property (retain) NSTimer *dispatchScheduler;
@property (nonatomic, assign) BOOL scheduledDispatchOn;

@end

@implementation TuneAnalyticsManager

#pragma mark - Initialization / Deallocation

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        [self setScheduledDispatchOn:NO];
        sessionVariables = [[NSMutableSet alloc] init];
        sessionVariablesLock = [[NSObject alloc] init];
    }
    
    return self;
}

// This seems to help with the testing
- (void)dealloc {
    [self stopScheduledDispatch];
    [_operationQueue cancelAllOperations];
}

- (void)bringUp {
    [self registerSkyhooks];
    [self handleSessionStart:nil];
}

- (void)bringDown {
    [self unregisterSkyhooks];
    [self handleSessionEnd:nil];
}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    // Listen for custom events
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleCustomEvent:)
                                              name:TuneCustomEventOccurred
                                            object:nil];
    
    // Listen for lifecycle events
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleSessionStart:)
                                              name:TuneSessionManagerSessionDidStart
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleSessionEnd:)
                                              name:TuneSessionManagerSessionDidEnd
                                            object:nil];
    
#if !TARGET_OS_WATCH
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleViewControllerAppeared:)
                                              name:TuneViewControllerAppeared
                                            object:nil];
#endif
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleSetSessionTagVariable:)
                                              name:TuneSessionVariableToSet
                                            object:nil];

    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleTuneUserProfileVariablesCleared:)
                                              name:TuneUserProfileVariablesCleared
                                            object:nil];
    
    // Listen for app opened by URL
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleAppOpenedFromURL:)
                                              name:TuneAppOpenedFromURL
                                            object:nil];

    // Listen for push notifications
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handlePushNotificationOpened:)
                                              name:TunePushNotificationOpened
                                            object:nil];
    
    // Listen if we're entering Connected Mode
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleEnterConnectedMode:)
                                              name:TuneStateTMAConnectedModeTurnedOn
                                            object:nil];

    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleInAppMessageShown:)
                                              name:TuneInAppMessageShown
                                            object:nil];

    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleInAppMessageDismissed:)
                                              name:TuneInAppMessageDismissed
                                            object:nil];
}

#pragma mark - Custom Event

- (void)handleCustomEvent:(TuneSkyhookPayload *)payload {
    TuneEvent *event = (TuneEvent *)[payload userInfo][TunePayloadCustomEvent];
    
    NSString *eventAction;
    if (event.eventIdObject != nil) {
        eventAction = [event.eventIdObject stringValue];
    } else {
        eventAction = event.eventName;
    }

    TuneAnalyticsEvent *customEvent = [[TuneAnalyticsEvent alloc] initWithTuneEvent:TUNE_EVENT_TYPE_BASE
                                                                             action:eventAction
                                                                           category:TUNE_EVENT_CATEGORY_CUSTOM
                                                                            control:nil
                                                                       controlEvent:nil
                                                                              event:event];

    [self storeAndTrackAnalyticsEvent:customEvent];
}

#pragma mark - Profile Clearing Events

- (void)handleTuneUserProfileVariablesCleared:(TuneSkyhookPayload *)payload {
    NSSet *clearedVariableNames = (payload.userInfo)[TunePayloadProfileVariablesToClear];
    NSString *clearedVariableString = [[clearedVariableNames allObjects] componentsJoinedByString:@","];
    
    // Create a special 'TRACER' event.
    TuneAnalyticsEvent *clearProfileEvent = [[TuneAnalyticsEvent alloc] initAsTracerEvent];
    clearProfileEvent.action = TUNE_EVENT_ACTION_PROFILE_VARIABLES_CLEARED;
    clearProfileEvent.category = clearedVariableString;
    
    // Store it.
    [self storeAndTrackAnalyticsEvent:clearProfileEvent];
    
    // Force through a tracerless dispatch so this doesn't get blended with a regular TRACER.
    [self dispatchAnalytics: NO];
}

#pragma mark - Lifecycle Events

- (void)handleSessionStart:(TuneSkyhookPayload *)payload {
    // Log the foregrounding event.
    TuneAnalyticsEvent *analyticsEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_SESSION
                                                                                action:TUNE_EVENT_ACTION_FOREGROUNDED
                                                                              category:TUNE_EVENT_CATEGORY_APPLICATION
                                                                               control:nil
                                                                          controlEvent:nil
                                                                                  tags:nil
                                                                                 items:nil];
    
    [self storeAndTrackAnalyticsEvent:analyticsEvent];
    
    // Start the periodic analytics transmissions.
    [self startScheduledDispatch];
    
    // Force through an initial dispatch of leftovers from last session.
    [self dispatchAnalytics];
}

- (void)handleSessionEnd:(TuneSkyhookPayload *)payload {
    
#if !TARGET_OS_WATCH
    // Make sure we get to do everything here before getting backgrounded.
    endSessionBgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
#endif
    // Log the backgrounded event.
    TuneAnalyticsEvent *analyticsEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_SESSION
                                                                                action:TUNE_EVENT_ACTION_BACKGROUNDED
                                                                              category:TUNE_EVENT_CATEGORY_APPLICATION
                                                                               control:nil
                                                                          controlEvent:nil
                                                                                  tags:nil
                                                                                 items:nil];
    
    
    [self storeAndTrackAnalyticsEvent:analyticsEvent];
    
    
    // Stop the periodic analytics transmissions.
    [self stopScheduledDispatch];
    
    // Force through a final dispatch.
    [self dispatchAnalytics];
    
    // Clear our session variables.
    @synchronized(sessionVariablesLock) {
        [sessionVariables removeAllObjects];
    }
}

#if !TARGET_OS_WATCH
- (void)handleViewControllerAppeared:(TuneSkyhookPayload *)payload {
    UIViewController *viewController = payload.object;
    
    TuneAnalyticsEvent *pageviewEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PAGEVIEW
                                                                                action:nil
                                                                              category:viewController.tuneScreenName
                                                                               control:nil
                                                                          controlEvent:nil
                                                                                  tags:nil
                                                                                 items:nil]; 
    [self storeAndTrackAnalyticsEvent:pageviewEvent];
}
#endif

- (void)handleEnterConnectedMode:(TuneSkyhookPayload *)payload {
    [self stopScheduledDispatch];
}

#pragma mark - Session Variables

// NOTE: the purpose of this is to handle queued session variables that were created before the tracker started
- (void)handleSetSessionTagVariable:(TuneSkyhookPayload *)payload {
    NSString *variableName = (NSString *)[payload userInfo][TunePayloadSessionVariableName];
    NSString *variableValue = (NSString *)[payload userInfo][TunePayloadSessionVariableValue];
    NSString *saveType = (NSString *)[payload userInfo][TunePayloadSessionVariableSaveType];
    
    if ([saveType isEqualToString:TunePayloadSessionVariableSaveTypeTag]) {
        [self registerSessionVariable:variableName withValue:variableValue];
    }
}

- (void)registerSessionVariable:(NSString *)name withValue:(NSString *)value {
    TuneAnalyticsVariable *newVariable = [TuneAnalyticsVariable analyticsVariableWithName:name value:value];
    @synchronized(sessionVariablesLock) {
        [sessionVariables addObject:newVariable];
    }
}

- (void)addSessionVariablesToEvent:(TuneAnalyticsEvent *)event {
    // Add our Session Variables to this event along with its existing variables.
    NSMutableSet *finalTags = nil;
    @synchronized(sessionVariablesLock) {
        finalTags = sessionVariables.mutableCopy;
    }
    
    [finalTags addObjectsFromArray:event.tags];
    event.tags = [[NSArray alloc] initWithArray:finalTags.allObjects];
}

#pragma mark - Deeplinks

- (void)handleAppOpenedFromURL:(TuneSkyhookPayload *)payload {
    TuneDeeplink *deeplink = (TuneDeeplink *)[payload userInfo][TunePayloadDeeplink];
    
    if (deeplink) {
        NSURL *openedURL = deeplink.url;
        TuneCampaign *campaign = deeplink.campaign;
        
        // Create a temp mutable set to add variables to
        NSMutableSet *analyticsVars = [[NSMutableSet alloc] init];
        
        if (openedURL) {
            [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:@"URL"
                                                                                value:openedURL.absoluteString]];
            [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:@"host"
                                                                                value:openedURL.host]];
        }
        
        if (campaign) {
            if (campaign.campaignSource && [campaign.campaignSource length] > 0) {
                [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:@"source"
                                                                                    value:campaign.campaignSource]];
            }
            if (campaign.campaignId && [campaign.campaignId length] > 0) {
                [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_IDENTIFIER
                                                                                    value:campaign.campaignId]];
            }
            if (campaign.variationId && [campaign.variationId length] > 0) {
                [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_VARIATION_IDENTIFIER
                                                                                    value:campaign.variationId]];
            }
        }
        
        for (NSString *key in [deeplink.eventParameters allKeys]) {
            NSString *value = (deeplink.eventParameters)[key];
            if (value && [value length] > 0) {
                [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:key
                                                                                    value:value]];
            }
        }
        
        // Create the deeplink opened event.
        TuneAnalyticsEvent *analyticsEvent = [[TuneAnalyticsEvent alloc] initWithEventType:deeplink.eventType
                                                                                    action:TUNE_EVENT_ACTION_DEEPLINK_OPENED
                                                                                  category:nil
                                                                                   control:nil
                                                                              controlEvent:nil
                                                                                      tags:[analyticsVars allObjects]
                                                                                     items:nil];
        // Log the event
        [self storeAndTrackAnalyticsEvent:analyticsEvent];
    }
}

#pragma mark - Push Notifications

- (void)handlePushNotificationOpened:(TuneSkyhookPayload *)payload {
    // Create a temp mutable set to add variables to
    NSMutableSet *analyticsVars = [[NSMutableSet alloc] init];
    
    // Get additional analytics variables from notification
    TuneNotification *tuneNotification = (TuneNotification *)[payload userInfo][TunePayloadNotification];
    
    // Campaign
    if (tuneNotification.campaign) {
        // If we are dealing with a test push then don't send analytics for it.
        if ([tuneNotification.campaign isTest]) {
            return;
        }
        NSDictionary *campaignDictionary = [tuneNotification.campaign toDictionary];
        for (NSString *key in [campaignDictionary allKeys]) {
            [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:key value:[NSString stringWithFormat:@"%@",campaignDictionary[key]]]];
        }
    }
    
     NSDictionary *apsDictionary = tuneNotification.userInfo[@"aps"];
    // userInfo dictionary
    for (NSString *key in [apsDictionary allKeys]) {
        [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:key value:[NSString stringWithFormat:@"%@",apsDictionary[key]]]];
    }
    
    // Get Tune Push ID
    NSString *tunePushId = @"";
    if (tuneNotification.tunePushID) {
        tunePushId = tuneNotification.tunePushID;
        [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_PUSH_NOTIFICATION_ID value:tunePushId]];
    }
    
    // Find the action
    NSString *pushAction = TunePushNotificationOpened;
    
    if (tuneNotification.analyticsReportingAction) {
        pushAction = tuneNotification.analyticsReportingAction;
    }
    
    // Interactive notification identifier
    if (tuneNotification.interactivePushIdentifierSelected) {
        [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_INTERACTIVE_NOTIFICATION_BUTTON_IDENTIFIER_SELECTED value:tuneNotification.interactivePushIdentifierSelected]];
    }
    // Interactive notification category
    if (tuneNotification.interactivePushCategory) {
        [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_INTERACTIVE_NOTIFICATION_CATEGORY value:tuneNotification.interactivePushCategory]];
    }
    
    // Notification type
    if (tuneNotification.notificationType) {
        [analyticsVars addObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_INTERACTIVE_NOTIFICATION_BUTTON_IDENTIFIER_SELECTED value:[TuneNotification tuneNotificationTypeAsString:tuneNotification.notificationType]]];
    }
    
    // Create the push notification opened event.
    TuneAnalyticsEvent *analyticsEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PUSH_NOTIFICATION
                                                                                action:pushAction
                                                                              category:tunePushId
                                                                               control:nil
                                                                          controlEvent:nil
                                                                                  tags:[analyticsVars allObjects]
                                                                                 items:nil];
    
    // Log the event
    [self storeAndTrackAnalyticsEvent:analyticsEvent];
}

#pragma mark - In App Messages

- (void)handleInAppMessageShown:(TuneSkyhookPayload *)payload {
    NSString *messageID = (NSString *)[payload userInfo][TunePayloadInAppMessageID];
    NSString *campaignStepVariable = (NSString *)[payload userInfo][TunePayloadCampaignStep];

    TuneAnalyticsEvent *analyticsEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_IN_APP_MESSAGE
                                                                                action:TUNE_IN_APP_MESSAGE_ACTION_SHOWN
                                                                              category:messageID
                                                                               control:nil
                                                                          controlEvent:nil
                                                                                  tags:@[campaignStepVariable]
                                                                                 items:nil];

    // Log the event
    [self storeAndTrackAnalyticsEvent:analyticsEvent];
}

- (void)handleInAppMessageDismissed:(TuneSkyhookPayload *)payload {
    NSString *messageID = (NSString *)[payload userInfo][TunePayloadInAppMessageID];
    NSString *campaignStepVariable = (NSString *)[payload userInfo][TunePayloadCampaignStep];
    NSString *secondsDisplayedVariable = (NSString *)[payload userInfo][TunePayloadInAppMessageSecondsDisplayed];
    NSString *dismissedAction = (NSString *)[payload userInfo][TunePayloadInAppMessageDismissedAction];


    TuneAnalyticsEvent *analyticsEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_IN_APP_MESSAGE
                                                                                action:dismissedAction
                                                                              category:messageID
                                                                               control:nil
                                                                          controlEvent:nil
                                                                                  tags:@[campaignStepVariable, secondsDisplayedVariable]
                                                                                 items:nil];

    // Log the event
    [self storeAndTrackAnalyticsEvent:analyticsEvent];
}

#pragma mark - Event Storage

- (void)storeAndTrackAnalyticsEvent:(TuneAnalyticsEvent *)event {
    @try {
        // If we're in Connected Mode, this goes immediately to the special endpoint.  This takes priority over being disabled.
        if ([TuneState isInConnectedMode]) {
            [self addSessionVariablesToEvent:event];
            [self dispatchToConnectedEndpoint:event];
        } else {
            // Don't store anything if Disabled
            if ([TuneState isTMADisabled]) { return; }
            
            // Add session variables to event now as they might be gone by the time the operation runs (happens w/ Backgrounded)
            [self addSessionVariablesToEvent:event];
            
            [[self operationQueue] addOperationWithBlock:^{
                
                // Post Skyhook so TriggerManager can track this event for In-App purposes.
                [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneEventTracked object:nil userInfo:@{ TunePayloadTrackedEvent:event }];
                
                NSString *eventJSON = [TuneJSONUtils createJSONStringFromDictionary:[event toDictionary]];
                [TuneFileManager saveAnalyticsEventToDisk:eventJSON withId:[event eventId]];
            }];
        }
    } @catch (NSException *exception) {
        ErrorLog(@"Failed to store analytics event: %@", exception);
    }
}

#pragma mark - Builders

- (TuneAnalyticsEvent *)buildTracerEvent  {
    TuneAnalyticsEvent *tracer = [[TuneAnalyticsEvent alloc] initAsTracerEvent];
    [self addSessionVariablesToEvent:tracer];
    
    return tracer;
}

#pragma mark - Queue Management

- (NSOperationQueue *)operationQueue {
    if (_operationQueue == nil) {
        _operationQueue = [NSOperationQueue new];
        [_operationQueue setMaxConcurrentOperationCount:1];
    }
    
    return _operationQueue;
}

# pragma mark - Transmission management
- (void)startScheduledDispatch {
    // Don't start to send out analytics if Disabled
    if ([TuneState isTMADisabled]) { return; }
    
    if (![self scheduledDispatchOn]) {
        [self setDispatchScheduler: [NSTimer scheduledTimerWithTimeInterval:[self.tuneManager.configuration.analyticsDispatchPeriod doubleValue]
                                                                     target:self
                                                                   selector:@selector(dispatchAnalytics)
                                                                   userInfo:nil
                                                                    repeats:YES]];
    }
    
    [self setScheduledDispatchOn:YES];
}

- (void)stopScheduledDispatch {
    if ([self scheduledDispatchOn]) {
        [[self dispatchScheduler] invalidate];
        [self setScheduledDispatchOn:NO];
    }
}

- (void)dispatchAnalytics {
    [self dispatchAnalytics:YES];
}

- (void)dispatchAnalytics:(BOOL)includeTracer {
    // Don't dispatch analytics if Disabled or we're in Connected mode.
    if ([TuneState isTMADisabled] || [TuneState isInConnectedMode]) { return; }

    TuneAnalyticsDispatchEventsOperation *dispatchOperation = [[TuneAnalyticsDispatchEventsOperation alloc] initWithTuneManager:self.tuneManager];
    
    if (dispatchOperation) {
        dispatchOperation.includeTracer = includeTracer;
        [[self operationQueue] addOperation:dispatchOperation];
    }
}

#if !TARGET_OS_WATCH
- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)taskId {
    [[UIApplication sharedApplication] endBackgroundTask:taskId];
    taskId = UIBackgroundTaskInvalid;
}
#endif

- (void)dispatchToConnectedEndpoint: (TuneAnalyticsEvent *)event {
    if ([TuneState isInConnectedMode]) {
        TuneAnalyticsDispatchToConnectedModeOperation *dispatchOperation = [[TuneAnalyticsDispatchToConnectedModeOperation alloc] initWithTuneManager:self.tuneManager
                                                                                                                                                event:event];
        
        if (dispatchOperation) {
            [[self operationQueue] addOperation:dispatchOperation];
        }
    }
}

#if !TARGET_OS_WATCH
- (void)endBackgroundTask {
    if (endSessionBgTask && endSessionBgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:endSessionBgTask];
        endSessionBgTask = UIBackgroundTaskInvalid;
    }
}
#endif

#pragma mark - Testing

#if TESTING
- (void)waitForOperationsToFinish {
    [[self operationQueue] waitUntilAllOperationsAreFinished];
}
#endif

@end
