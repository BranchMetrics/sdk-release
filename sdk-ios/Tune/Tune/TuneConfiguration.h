//
//  TuneConfiguration.h
//  TuneMarketingConsoleSDK
//
//  Copyright (c) 2015 Tune. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface TuneConfiguration : NSObject

+ (TuneConfiguration *)sharedConfiguration;

@property (nonatomic, assign) BOOL collectDeviceLocation;
@property (nonatomic, assign) BOOL checkForJailbreak;

@property (nonatomic, copy) NSNumber *analyticsDispatchPeriod;
@property (nonatomic, copy) NSNumber *analyticsMessageStorageLimit;

@property (nonatomic, copy) NSString *pluginName;

+ (NSString *)frameworkVersion;

@end
