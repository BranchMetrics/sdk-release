//
//  TuneSkyhookConstants.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookConstants.h"

#pragma mark - Analytics Hooks
NSString *const TuneCustomEventOccurred = @"TuneCustomEventOccurred";
NSString *const TuneAppOpenedFromURL = @"TuneAppOpenedFromURL";
NSString *const TuneEventTracked = @"TuneEventTracked"; // Posted on every event via AnalyticsManager#storeAndTrackAnalyticsEvents

#pragma mark - Session Hooks
NSString *const TuneSessionManagerSessionDidStart = @"TuneSessionManagerSessionDidStart";
NSString *const TuneSessionManagerSessionDidEnd = @"TuneSessionManagerSessionDidEnd";
