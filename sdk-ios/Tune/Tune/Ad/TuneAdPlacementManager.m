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
    NSMutableDictionary *pendingPrefetch;
    
    BOOL cachingAllowed;
}

/*!
 Mutable array of TuneAd objects.
 */
@property (nonatomic, strong) NSMutableDictionary *adPlacements;

- (TuneAdPlacement *)adPlacementForPlacement:(NSString *)placement;
- (void)removeAdPlacementForPlacement:(NSString *)placement;

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
    DLog(@"current cache = %@", self.adPlacements.keyEnumerator.allObjects);
    
    // extract the cached ad for this placement
    TuneAdPlacement *adPlacement = [self adPlacementForPlacement:placement];
    
    DLog(@"TAPM: existing adplacement for: %@ = %@", placement, adPlacement);
    
    // if a cached ad is present
    if(adPlacement)
    {
        DLog(@"return cached ad for placement = %@", placement);
        
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
        DLog(@"no cached ad for placement = %@, start new download", placement);
        
        // initiate an ad download for this new placement
        // and call the appropriate handler when download is complete
        [TuneAdDownloadHelper downloadAdForAdType:adType
                                     orientations:orientations
                                        placement:placement
                                       adMetadata:metadata
                                   requestHandler:^(NSString *url, NSString *data) {
                                       if(requestHandler)
                                       {
                                           requestHandler(url, data);
                                       }
                                   }
                                completionHandler:^(TuneAd *adNew, NSError *error) {
                                   
                                    DLog(@"TAPM: ad download finished");
                                    
                                    if(adNew)
                                    {
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
                                }];
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
        // pre-fetch an ad if the cache is empty
        TuneAdPlacement *cachedAdPlacement = self.adPlacements[placement];
        if(cachingAllowed && !cachedAdPlacement && !pendingPrefetch[placement])
        {
            DLog(@"pre-fetch ad for placement = %@", placement);
            
            static NSString *strPrefetchPending = @"pre-fetch pending";
            pendingPrefetch[placement] = strPrefetchPending;
            
            // initiate an ad pre-fetch for this placement,
            // but do not call the parent completion handlers
            [TuneAdDownloadHelper downloadAdForAdType:adType
                                         orientations:orientations
                                            placement:placement
                                           adMetadata:metadata
                                       requestHandler:^(NSString *url, NSString *data) {
                                           if(requestHandler)
                                           {
                                               requestHandler(url, data);
                                           }
                                       }
                                    completionHandler:^(TuneAd *adNew, NSError *error) {

                                        if(adNew)
                                        {
                                            // cache the downloded ad
                                            [self cacheAd:adNew forPlacement:placement metadata:metadata];
                                        }
                                        
                                        @synchronized(pendingPrefetch)
                                        {
                                            [pendingPrefetch setValue:nil forKey:placement];
                                        }
                                    }];
        }
        else
        {
            DLog(@"skip pre-fetch for placement = %@, caching disabled = %d, cache ready = %d, request pending = %d", placement, !cachingAllowed, nil != cachedAdPlacement, nil != pendingPrefetch[placement]);
        }
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _adPlacements = [NSMutableDictionary dictionary];
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
    TuneAdPlacement *pl = self.adPlacements[placement];
    
    // create a new placement
    pl = [TuneAdPlacement adPlacementWithPlacement:placement metadata:metadata];
    pl.ad = ad;
    
    // create an entry in dictionary for this new placement
    self.adPlacements[placement] = pl;
    
    DLog(@"new cache = %@", self.adPlacements.keyEnumerator.allObjects);
}

- (TuneAdPlacement *)adPlacementForPlacement:(NSString *)placement
{
    return self.adPlacements[placement];
}

- (void)removeAdPlacementForPlacement:(NSString *)placement
{
    DLog(@"removeAdPlacementForPlacement: %@", placement);
    
    [self.adPlacements removeObjectForKey:placement];
}

- (void)handleLowMemoryWarning:(NSNotification *)notification
{
    // the app has received a low memory warning, try to free up some space
    
    DLog(@"low memory warning: purge cache and disable caching for %f seconds", TUNE_AD_DURATION_DISABLE_CACHING_FOR_LOW_MEMORY);
    
    // purge the cache to free up memory
    [self.adPlacements removeAllObjects];
    
    // disable caching for a few minutes to help resolve the low memory condition
    cachingAllowed = NO;
    [NSTimer scheduledTimerWithTimeInterval:TUNE_AD_DURATION_DISABLE_CACHING_FOR_LOW_MEMORY target:self selector:@selector(lowMemoryResponseTimerFired) userInfo:nil repeats:NO];
}

- (void)lowMemoryResponseTimerFired
{
    cachingAllowed = YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
