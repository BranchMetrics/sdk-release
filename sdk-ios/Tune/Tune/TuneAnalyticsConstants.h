//
//  TuneAnalyticsConstants.h
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/28/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneAnalyticsConstants : NSObject

#pragma mark - Data Types
FOUNDATION_EXPORT NSString *const TUNE_DATA_TYPE_STRING;
FOUNDATION_EXPORT NSString *const TUNE_DATA_TYPE_DATETIME;
FOUNDATION_EXPORT NSString *const TUNE_DATA_TYPE_BOOLEAN;
FOUNDATION_EXPORT NSString *const TUNE_DATA_TYPE_FLOAT;
FOUNDATION_EXPORT NSString *const TUNE_DATA_TYPE_GEOLOCATION;
FOUNDATION_EXPORT NSString *const TUNE_DATA_TYPE_VERSION;

#pragma mark - Hash Types
FOUNDATION_EXPORT NSString *const TUNE_HASH_TYPE_NONE;
FOUNDATION_EXPORT NSString *const TUNE_HASH_TYPE_MD5;
FOUNDATION_EXPORT NSString *const TUNE_HASH_TYPE_SHA1;
FOUNDATION_EXPORT NSString *const TUNE_HASH_TYPE_SHA256;

@end
