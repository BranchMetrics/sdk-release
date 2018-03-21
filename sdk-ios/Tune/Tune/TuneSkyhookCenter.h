//
//  TuneSkyhookCenter.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookPayload.h"
#import "TuneSkyhookObserver.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"

@interface TuneSkyhookCenter : NSObject

/* Returns the default skyhook center */
+ (TuneSkyhookCenter *)defaultCenter;

/* Adds an observer for a given hook. Observers are called in priority order, and if the priority is the same, it's called in a first-in, first-out fashion.
 *
 * @property hookObserver The object observing the hook.
 * @property hookSelector The selector to call on the observer.
 * @property hookName The name of the hook to observe.
 * @property hookSender The object to observe. If specified, only hooks posted with that object specified will call the observer. If set to nil, any hook matching the hookName will be sent
 * @property priority The priority of the observer. Observers are called in ascending order, and there can only be one observer per priority.
 *
 * @warning The specified selector will be run on the same thread from which the hook is posted.
 *
 */
- (void)addObserver:(id)hookObserver selector:(SEL)hookSelector name:(NSString *)hookName object:(id)hookSender priority:(int)priority;
/*
 * Defaults to priority TuneSkyhookPriorityIrrelevant
 */
- (void)addObserver:(id)hookObserver selector:(SEL)hookSelector name:(NSString *)hookName object:(id)hookSender;

/* Removes an observer
 *
 * @property hookObserver The object observing the hook.
 * @property hookName The name of the hook to observer.
 * @property hookSender The object being observed. Can be set to `nil` to apply to observers on all hooks.
 */
- (void)removeObserver:(id)hookObserver name:(NSString *)hookName object:(id)hookSender;

/* Removes an observer from all hooks
 */
- (void)removeObserver:(id)hookObserver;

/* Posts a hook to observers. Observers will be called in priority order, and this method will not return until all observers have responded.
 *
 * This does the same as calling -[center postSkyhook:object:] with a nil object.
 *
 * @property hookName The hook to post.
 */
- (void)postSkyhook:(NSString *)hookName;

/* Posts a hook to observers. Observers will be called in priority order, and this method will not return until all observers have responded.
 *
 * @property hookName The hook to post.
 * @property hookSender The object posting the hook. Optional.
 */
- (void)postSkyhook:(NSString *)hookName object:(id)hookSender;

/* Posts a hook to observers. Observers will be called in priority order, and this method will not return until all observers have responded. All observers are run on the calling thread.
 *
 * @property hookName The hook to post.
 * @property hookSender The object posting the hook. Optional.
 * @property userInfo An NSDictionary of any data to send along with the skyhook
 */
- (void)postSkyhook:(NSString *)hookName object:(id)hookSender userInfo:(NSDictionary *)userInfo;

/* Posts a hook to observers. Observers will be called in priority order, and this method will not return until all observers have responded. All observers are run on the calling thread.
 *
 * If the observer returns an object, the returnedObjectBlock is called with the object that is returned.
 *
 * @property hookName The hook to post.
 * @property hookSender The object posting the hook. Optional.
 * @property userInfo An NSDictionary of any data to send along with the skyhook
 * @property returnedObjectBlock A block to be called with any objects returned from the observer
 */
- (void)postSkyhook:(NSString *)hookName object:(id)hookSender userInfo:(NSDictionary *)userInfo returnedObjectBlock:(void (^)(id returnObject))returnedObjectBlock;

// Queued variants of those above.
- (void)postQueuedSkyhook:(NSString *)hookName;
- (void)postQueuedSkyhook:(NSString *)hookName object:(id)hookSender;
- (void)postQueuedSkyhook:(NSString *)hookName object:(id)hookSender userInfo:(NSDictionary *)userInfo;

/* Returns YES if the passed in hook name has any observers, otherwise returns NO
 *
 * @property hookName The name of the hook
 */
- (BOOL)hasObserverForHook:(NSString *)hookName;

/* Returns a string containing everything responding to a given notification.
 *
 * @property hookName The hook you're requesting. Pass nil to return all hooks.
 */
- (NSString *)debugHook:(NSString *)hookName;

/*
 * Sets the Queue as suspended so events don't fire when we foreground and clears out any remaining operations.
 */
- (void)stopAndClearSkyhookQueue;

/*
 * Starts the Skyhook operations queue
 */
- (void)startSkyhookQueue;

/*
 * Calls `waitUntilAllOperationsAreFinished` on _skyhookQueue.
 *
 * "Blocks the current thread until all of the receiver’s queued and executing operations finish executing."
 */
- (void)waitTilQueueFinishes;

@end
