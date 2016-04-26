//
//  UIViewController+TuneAnalytics.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/26/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#if !TARGET_OS_WATCH

#import <Foundation/Foundation.h>

@interface UIViewController (TuneAnalytics)

- (NSString *)tuneScreenName;

@end

#endif
