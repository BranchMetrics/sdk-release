//
//  TuneAnalyticsConstants.m
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/28/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneAnalyticsConstants.h"

@implementation TuneAnalyticsConstants

#pragma mark - Data Types
NSString *const TUNE_DATA_TYPE_STRING = @"string";
NSString *const TUNE_DATA_TYPE_DATETIME = @"datetime";
NSString *const TUNE_DATA_TYPE_BOOLEAN = @"boolean";
NSString *const TUNE_DATA_TYPE_FLOAT = @"float";
NSString *const TUNE_DATA_TYPE_GEOLOCATION = @"geolocation";
NSString *const TUNE_DATA_TYPE_VERSION = @"version";

#pragma mark - Hash Types
NSString *const TUNE_HASH_TYPE_NONE = @"none";
NSString *const TUNE_HASH_TYPE_MD5 = @"md5";
NSString *const TUNE_HASH_TYPE_SHA1 = @"sha1";
NSString *const TUNE_HASH_TYPE_SHA256 = @"sha256";

@end
