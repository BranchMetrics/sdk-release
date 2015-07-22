//
//  TuneAdPlacementManager.h
//  Tune
//
//  Created by Harshal Ogale on 5/31/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TuneAd.h"
#import "../TuneAdMetadata.h"

/*!
 Manages download and pre-fetch of ads for the given ad-type, placement, metadata and supported orientations.
*/
@interface TuneAdPlacementManager : NSObject

/*!
 Downloads an ad from the Tune ad server.
 @param placement placement string for which the ad is required
 @param metadata ad metadata associated with the placement
 @param completionHandler block of code to execute when the method ends
 */
- (void)adForAdType:(TuneAdType)adType
          placement:(NSString *)placement
           metadata:(TuneAdMetadata *)metadata
       orientations:(TuneAdOrientation)orientations
  completionHandler:(void (^)(TuneAd *ad, NSError *error))completionHandler;

/*!
 Method to update the ad metadata associated with the placement.
 @param placement placement string for which the ad is required
 @param metadata ad metadata to be associated with the placement
 */
- (void)setMetadata:(TuneAdMetadata *)metadata forPlacement:(NSString *)placement;

@end
