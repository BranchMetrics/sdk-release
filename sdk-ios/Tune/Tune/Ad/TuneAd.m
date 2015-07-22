//
//  TuneAd.m
//  Tune
//
//  Created by Harshal Ogale on 5/14/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import "TuneAd.h"
#import "TuneAdUtilitiesUI.h"
#import "../Common/TuneKeyStrings.h"
#import "TuneAdKeyStrings.h"


#if DEBUG && 0
const CGFloat TUNE_AD_DEFAULT_BANNER_CYCLE_DURATION = 5;
#else
const CGFloat TUNE_AD_DEFAULT_BANNER_CYCLE_DURATION = 30;
#endif

const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPHONE_PORTRAIT   = 50;
const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPHONE_LANDSCAPE  = 32;
const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPAD_PORTRAIT     = 66;
const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPAD_LANDSCAPE    = 66;

@implementation TuneAd

+ (instancetype)adBannerFromDictionary:(NSDictionary *)dict placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations
{
    return [self ad:TuneAdTypeBanner placement:placement metadata:metadata orientations:orientations fromDictionary:dict];
}

+ (instancetype)adInterstitialFromDictionary:(NSDictionary *)dict placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations
{
    return [self ad:TuneAdTypeInterstitial placement:placement metadata:metadata orientations:orientations fromDictionary:dict];
}

+ (instancetype)ad:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations fromDictionary:(NSDictionary *)dict
{
    TuneAd *ad = nil;
    
    NSString *strHtml = [dict objectForKey:TUNE_AD_KEY_HTML];
    
    //NSLog(@"type = %ld, dict = %@", (long)adType, dict);
    
    if(strHtml)
    {
        ad = [TuneAd new];
        
        ad.type = adType;
        
        ad.html = strHtml;
        
        NSNumber *numDuration = [dict objectForKey:TUNE_AD_KEY_DURATION];
        ad.duration = numDuration ? [numDuration floatValue] : TUNE_AD_DEFAULT_BANNER_CYCLE_DURATION;
        
        NSString *strClose = [dict objectForKey:TUNE_AD_KEY_CLOSE];
        ad.usesNativeCloseButton = !strClose || [[strClose lowercaseString] isEqualToString:TUNE_AD_KEY_NATIVE];
        
        ad.color            = [dict objectForKey:TUNE_AD_KEY_COLOR];
        ad.requestId        = [dict objectForKey:TUNE_AD_KEY_REQUEST_ID];
        ad.refs             = [dict objectForKey:TUNE_AD_KEY_REFS];
        
        ad.placement = placement;
        ad.metadata = metadata;
        ad.orientations = orientations;
    }
    
    return ad;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> %@, %d, %f, %@, %d", [self class], self, self.color, (int)self.type, self.duration, self.html, self.usesNativeCloseButton];
}

#pragma mark - Helper Methods

+ (CGFloat)bannerHeightPortrait
{
    return isPad() ? TUNE_AD_DEFAULT_BANNER_HEIGHT_IPAD_PORTRAIT : TUNE_AD_DEFAULT_BANNER_HEIGHT_IPHONE_PORTRAIT;
}

+ (CGFloat)bannerHeightLandscape
{
    return isPad() ? TUNE_AD_DEFAULT_BANNER_HEIGHT_IPAD_LANDSCAPE : TUNE_AD_DEFAULT_BANNER_HEIGHT_IPHONE_LANDSCAPE;
}

@end
