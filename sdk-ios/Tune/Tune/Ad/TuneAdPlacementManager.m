//
//  TuneAdPlacementManager.m
//  Tune
//
//  Created by Harshal Ogale on 5/31/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneAdPlacementManager.h"

#import "TuneAdDownloadHelper.h"
#import "../TuneAdMetadata.h"
#import "TuneAdPlacement.h"

static const NSTimeInterval TUNE_AD_DURATION_DISABLE_CACHING_FOR_LOW_MEMORY = 60.; // 1 minute

@interface TuneAdPlacementManager ()
{
    /*!
     Mutable dictionary that contains one entry for each placement for which an ad request is pending.
     */
    NSMutableDictionary *pendingPrefetch;
    
    /*!
     Mutable array of TuneAd objects.
     */
    NSMutableDictionary *adPlacements;
    
    /*!
     Indicates if ad caching is enabled.
     */
    BOOL cachingAllowed;
    
    /*!
     Timer used to reset ad caching behavior after a low memory condition is encountered.
     */
    NSTimer *lowMemoryTimer;
}

@end


@implementation TuneAdPlacementManager

- (void)setMetadata:(TuneAdMetadata *)metadata forPlacement:(NSString *)placement
{
    TuneAdPlacement *pl = [self adPlacementForPlacement:placement];
    pl.metadata = metadata;
}

- (void)adForAdType:(TuneAdType)adType
          placement:(NSString *)placement
           metadata:(TuneAdMetadata *)metadata
       orientations:(TuneAdOrientation)orientations
     requestHandler:(void (^)(NSString *url, NSString *data))requestHandler
  completionHandler:(void (^)(TuneAd *ad, NSError *error))completionHandler
{
    DLog(@"TAPM: adForAdType: current cache = %@", adPlacements.keyEnumerator.allObjects);
    
    // extract the cached ad for this placement
    TuneAdPlacement *adPlacement = [self adPlacementForPlacement:placement];
    
    DLog(@"TAPM: existing ad placement for: %@ = %@", placement, adPlacement);
    
    // if a cached ad is present
    if(adPlacement)
    {
        DLog(@"TAPM: return cached ad for placement = %@", placement);
        
        // remove the cached ad for this placement
        [self removeAdPlacementForPlacement:placement];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            DLog(@"TAPM: pass1: pre-fetch");
            
            // initiate ad pre-fetch
            [self prefetchAdForAdType:adType placement:placement metadata:metadata orientations:orientations requestHandler:requestHandler];
        });
        
        if(completionHandler)
        {
            // return the currently cached ad
            completionHandler(adPlacement.ad, nil);
        }
    }
    else
    {
        DLog(@"TAPM: no cached ad for placement = %@, start new download", placement);
        
        void(^dhRequestHandler)(NSString *, NSString *) = ^(NSString *url, NSString *data) {
            DLog(@"TAPM: download helper requestHandler1");
            if(requestHandler)
            {
                requestHandler(url, data);
            }
        };
        
        void(^dhCompletionHandler)(TuneAd*, NSError*) = ^(TuneAd* adNew, NSError* error) {
            DLog(@"TAPM: download helper completionHandler1: %p", completionHandler);
            if(adNew)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    DLog(@"TAPM: pass2: pre-fetch");
                    
                    // initiate ad pre-fetch
                    [self prefetchAdForAdType:adType placement:placement metadata:metadata orientations:orientations requestHandler:requestHandler];
                });
            }
            
            if(completionHandler)
            {
                // send the downloaded ad to the completion handler
                completionHandler(adNew, error);
            }
        };
        
        // initiate an ad download for this new placement
        // and call the appropriate handler when download is complete
        [TuneAdDownloadHelper downloadAdForAdType:adType
                                        placement:placement
                                         metadata:metadata
                                     orientations:orientations
                                   requestHandler:dhRequestHandler
                                completionHandler:dhCompletionHandler];
    }
}

- (void)prefetchAdForAdType:(TuneAdType)adType
                  placement:(NSString *)placement
                   metadata:(TuneAdMetadata *)metadata
               orientations:(TuneAdOrientation)orientations
             requestHandler:(void (^)(NSString *url, NSString *data))requestHandler
{
    @synchronized(pendingPrefetch)
    {
        DLog(@"TAPM: pre-fetch: caching allowed = %d, current cache = %@", cachingAllowed, adPlacements);
        
        // pre-fetch an ad if the cache is empty
        TuneAdPlacement *cachedAdPlacement = adPlacements[placement];
        if(cachingAllowed && !cachedAdPlacement && !pendingPrefetch[placement])
        {
            DLog(@"TAPM: pre-fetch: ad for placement = %@", placement);
            
            static NSString *strPrefetchPending = @"pre-fetch pending";
            
            @synchronized(pendingPrefetch)
            {
                pendingPrefetch[placement] = strPrefetchPending;
            }
            
            // handle request-fired callback from download helper
            void(^dhRequestHandler)(NSString *, NSString *) = ^(NSString *url, NSString *data) {
                DLog(@"TAPM: download helper requestHandler2");
                if(requestHandler)
                {
                    requestHandler(url, data);
                }
            };
            
            // handle request-completed callback from download helper
            void(^dhCompletionHandler)(TuneAd*, NSError*) = ^(TuneAd* adNew, NSError* error) {
                DLog(@"TAPM: download helper completionHandler2: adNew = %p", adNew);
                if(adNew)
                {
                    // cache the downloaded ad
                    [self cacheAd:adNew forPlacement:placement metadata:metadata];
                }
                
                @synchronized(pendingPrefetch)
                {
                    if(placement)
                    {
                        [pendingPrefetch removeObjectForKey:placement];
                    }
                }
            };
            
            // pre-fetch and cache an ad but do not call the caller's completion handler
            [TuneAdDownloadHelper downloadAdForAdType:adType
                                            placement:placement
                                             metadata:metadata
                                         orientations:orientations
                                       requestHandler:dhRequestHandler
                                    completionHandler:dhCompletionHandler];
        }
        else
        {
            DLog(@"TAPM: skip pre-fetch for placement = %@, caching allowed = %d, cache ready = %d, request pending = %d", placement, cachingAllowed, nil != cachedAdPlacement, nil != pendingPrefetch[placement]);
            DLog(@"TAPM: pendingPrefetch[placement] = %@", pendingPrefetch);
        }
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        adPlacements = [NSMutableDictionary dictionary];
        pendingPrefetch = [NSMutableDictionary dictionary];
        cachingAllowed = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLowMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)cacheAd:(TuneAd *)ad forPlacement:(NSString *)placement metadata:(TuneAdMetadata *)metadata
{
    // create a new placement
    TuneAdPlacement *pl = [TuneAdPlacement adPlacementWithPlacement:placement metadata:metadata];
    pl.ad = ad;
    
    // create an entry in dictionary for this new placement
    adPlacements[placement] = pl;
    
    DLog(@"TAPM: new cache = %@", adPlacements.keyEnumerator.allObjects);
}

- (TuneAdPlacement *)adPlacementForPlacement:(NSString *)placement
{
    return adPlacements[placement];
}

- (void)removeAdPlacementForPlacement:(NSString *)placement
{
    DLog(@"removeAdPlacementForPlacement: %@", placement);
    
    [adPlacements removeObjectForKey:placement];
}

- (void)handleLowMemoryWarning:(NSNotification *)notification
{
    // the app has received a low memory warning, try to free up some space
    
    DLog(@"TAPM: low memory warning: purge cache and disable caching for %f seconds", TUNE_AD_DURATION_DISABLE_CACHING_FOR_LOW_MEMORY);
    DLog(@"TAPM: low memory warning: before purge: storage: %@", adPlacements);
    // purge the cache to free up memory
    [adPlacements removeAllObjects];
    DLog(@"TAPM: low memory warning: after purge: storage: %@", adPlacements);
    // disable caching for a few minutes to help resolve the low memory condition
    cachingAllowed = NO;
    [lowMemoryTimer invalidate];
    lowMemoryTimer = [NSTimer scheduledTimerWithTimeInterval:TUNE_AD_DURATION_DISABLE_CACHING_FOR_LOW_MEMORY target:self selector:@selector(lowMemoryWarningResetTimerFired) userInfo:nil repeats:NO];
}

- (void)lowMemoryWarningResetTimerFired
{
    cachingAllowed = YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(lowMemoryTimer)
    {
        [lowMemoryTimer invalidate];
        lowMemoryTimer = nil;
    }
}

@end
