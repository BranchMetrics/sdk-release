//
//  TuneDeeplink.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneDeeplink : NSObject

@property (strong, nonatomic) NSURL *url;

- (id)initWithNSURL:(NSURL *)url;
+ (void)processDeeplinkURL:(NSURL *)url;

@end
