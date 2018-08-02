//
//  TuneConfiguration.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/3/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneConfiguration.h"
#import "Tune.h"

@implementation TuneConfiguration

+ (TuneConfiguration *)sharedConfiguration {
    static TuneConfiguration *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [TuneConfiguration new];
    });
    return config;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDefaultConfiguration];
    }
    return self;
}

+ (NSString *)frameworkVersion {
    return TUNEVERSION;
}

- (void)setDefaultConfiguration {
    self.collectDeviceLocation = YES;
    
    self.analyticsMessageStorageLimit = @(250);
    self.pluginName = nil;
}

@end
