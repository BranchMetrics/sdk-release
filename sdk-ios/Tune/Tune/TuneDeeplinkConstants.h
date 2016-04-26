//
//  TuneDeeplinkConstants.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneDeeplinkConstants : NSObject

extern NSString *const TuneDeeplinkDeepActionPrefixKey;
extern NSString *const TuneDeeplinkDeepActionNameKey;
extern NSString *const TuneDeeplinkDeepActionDataKey;

extern NSString *const TuneDeeplinkArtisanCampaignIDKey;
extern NSString *const TuneDeeplinkSharedUserIDKey;
extern NSString *const TuneDeeplinkSharedUserIDInHexKey;
extern NSString *const TuneDeeplinkTimeToReportAnalyticsKey;
extern NSString *const TuneDeeplinkVariationIDKey;

extern NSString *const TuneDeeplinkCategoryKey;

// Source
extern NSString *const TuneDeeplinkSourceKey;
extern NSString *const TuneDeeplinkSourceWeb;
extern NSString *const TuneDeeplinkSourceEmail;
extern NSString *const TuneDeeplinkSourceSMS;
extern NSString *const TuneDeeplinkSourceApp;
extern NSString *const TuneDeeplinkSourceAd;
extern NSString *const TuneDeeplinkTodayExtension;
extern NSString *const TuneDeeplinkSourceUnknown;

@end
