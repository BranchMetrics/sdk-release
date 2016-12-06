//
//  TuneIadUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 9/30/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#if USE_IAD
#import <iAd/iAd.h>


@interface TuneIadUtils : NSObject

+ (BOOL)shouldCheckIadAttribution;

@end

#endif
