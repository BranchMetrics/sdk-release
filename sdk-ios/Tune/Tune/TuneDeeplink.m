//
//  TuneDeeplink.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneDeeplink.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneUserProfile.h"

@implementation TuneDeeplink


- (id)initWithNSURL:(NSURL *)url {
    self = [super init];
    if(self) {
        self.url = url;
    }
    return self;
}

#pragma mark - Skyhooks

- (void)processAnalytics {
    // report on app open
    [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneAppOpenedFromURL object:nil userInfo:@{TunePayloadDeeplink:self}];
}

#pragma mark - Static processing of deep links

+ (void)processDeeplinkURL:(NSURL *)url {
    TuneDeeplink *deeplink = [[TuneDeeplink alloc] initWithNSURL:url];

    [deeplink processAnalytics];
}

@end
