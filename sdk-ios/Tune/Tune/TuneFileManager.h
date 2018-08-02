//
//  TuneFileManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TuneModule.h"

@interface TuneFileManager : NSObject

+ (NSDictionary *)loadAnalyticsFromDisk;
+ (BOOL)saveAnalyticsEventToDisk:(NSString *)eventJSON withId:(NSString *)eventId;
+ (BOOL)saveAnalyticsToDisk:(NSDictionary *)analytics;
+ (BOOL)deleteAnalyticsEventsFromDisk:(NSArray *)eventsToDelete;
+ (BOOL)deleteAnalyticsFromDisk;

@end
