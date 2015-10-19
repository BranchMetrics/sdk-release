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
 Initialize an instance of ad download helper.
 @param adType type of ad
 @param placement name of the ad view placement
 @param metadata metadata to be included in the ad download network request 
 @param orientations device orientations to be supported
 @param requestHandler block to be executed when a download network request is fired, contains url and data
 @param completionHandler block to be executed on completion of the download request, includes a new ad or an error
 @return an initialized instance of ad download helper
 */
- (instancetype)initWithAdType:(TuneAdType)adType
                     placement:(NSString *)placement
                      metadata:(TuneAdMetadata *)metadata
                  orientations:(TuneAdOrientation)orientations
                requestHandler:(void (^)(NSString *url, NSString *data))requestHandler
             completionHandler:(void (^)(TuneAd *ad, NSError *error))completionHandler;

/*!
 Fires a request to fetch a new ad from the ad server. This method should be called only if the network is reachable.
 */
- (void)fetchAd;

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
 @param placement placement string
 @param metadata ad metadata
 @param orientations supported orientations
 @param requestHandler block of code to execute when an ad download request is fired
 @param completionHandler block of code to execute when the download is finishes
 */
+ (void)downloadAdForAdType:(TuneAdType)adType
                  placement:(NSString *)placement
                   metadata:(TuneAdMetadata *)metadata
               orientations:(TuneAdOrientation)orientations
             requestHandler:(void (^)(NSString *url, NSString *data))requestHandler
          completionHandler:(void (^)(TuneAd *ad, NSError *error))completionHandler;

@end


@protocol TuneAdDownloadHelperDelegate <NSObject>

@required

- (void)downloadFinishedWithAd:(TuneAd *)data;
- (void)downloadFailedWithError:(NSError *)error;
- (void)downloadStartedForAdWithUrl:(NSString *)url data:(NSString *)data;

@end
