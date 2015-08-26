//
//  TuneAdDownloadHelper.h
//  Tune
//
//  Created by Harshal Ogale on 5/13/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TuneAdView.h"

@class TuneBanner;
@class TuneInterstitial;
@class TuneKeyStrings;
@class TuneAd;
@class TuneAdKeyStrings;
@class TuneAdMetadata;
@class TuneAdParams;
@class TuneAdUtils;

@protocol TuneAdDownloadHelperDelegate;

/*!
 Downloads ads from server.
 */
@interface TuneAdDownloadHelper : NSObject

@property (nonatomic, assign) id<TuneAdDownloadHelperDelegate> delegate;

/*!
 A fetch request is currently in progress
 */
@property (nonatomic, assign) BOOL fetchAdInProgress;

/*!
 Initialize download helper for a TuneAdView
 */
//- (instancetype)initWithAdView:(TuneAdView *)tuneAdView;

- (instancetype)initWithAdType:(TuneAdType)ty
                     placement:(NSString *)pl
                      metadata:(TuneAdMetadata *)met
                  orientations:(TuneAdOrientation)ori
                requestHandler:(void (^)(NSString *url, NSString *data))rh
             completionHandler:(void (^)(TuneAd *ad, NSError *error))ch;

/*!
 If network is reachable, then fires a request to fetch a new ad from the ad server.
 @return TRUE if the request was fired, NO otherwise
 */
- (BOOL)fetchAd;

/*!
 Cancel the currently active network request.
 */
- (void)cancel;

/*!
 Reset the state of this download helper.
 */
- (void)reset;

/*!
 Downloads an ad from the Tune ad server.
 @param adType type of ad
 @param orientations supported orientations
 @param placement placement string
 @param metadata ad metadata
 @param requestHandler block of code to execute when an ad download request is fired
 @param completionHandler block of code to execute when the download is finishes
 */
+ (void)downloadAdForAdType:(TuneAdType)adType
               orientations:(TuneAdOrientation)orientations
                  placement:(NSString *)placement
                 adMetadata:(TuneAdMetadata *)metadata
             requestHandler:(void (^)(NSString *url, NSString *data))requestHandler
          completionHandler:(void (^)(TuneAd *ad, NSError *error))completionHandler;

@end


@protocol TuneAdDownloadHelperDelegate <NSObject>

@required

- (void)downloadFinishedWithAd:(TuneAd *)data;
- (void)downloadFailedWithError:(NSError *)error;
- (void)downloadStartedForAdWithUrl:(NSString *)url data:(NSString *)data;

@end
