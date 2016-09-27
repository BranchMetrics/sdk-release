//
//  TuneDeeplinkConstants.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneDeeplinkConstants : NSObject

FOUNDATION_EXPORT NSString *const TuneDeeplinkDeepActionPrefixKey;
FOUNDATION_EXPORT NSString *const TuneDeeplinkDeepActionNameKey;
FOUNDATION_EXPORT NSString *const TuneDeeplinkDeepActionDataKey;

FOUNDATION_EXPORT NSString *const TuneDeeplinkArtisanCampaignIDKey;
FOUNDATION_EXPORT NSString *const TuneDeeplinkTimeToReportAnalyticsKey;
FOUNDATION_EXPORT NSString *const TuneDeeplinkVariationIDKey;

FOUNDATION_EXPORT NSString *const TuneDeeplinkCategoryKey;

// Source
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceKey;
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceWeb;
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceEmail;
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceSMS;
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceApp;
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceAd;
FOUNDATION_EXPORT NSString *const TuneDeeplinkTodayExtension;
FOUNDATION_EXPORT NSString *const TuneDeeplinkSourceUnknown;

@end
