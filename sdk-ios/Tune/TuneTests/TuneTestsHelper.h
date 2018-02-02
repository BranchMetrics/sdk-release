//
//  TuneTestsHelper.h
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString* const kTestAdvertiserId;
FOUNDATION_EXPORT NSString* const kTestConversionKey;
FOUNDATION_EXPORT NSString* const kTestBundleId;
FOUNDATION_EXPORT const NSTimeInterval TUNE_TEST_NETWORK_REQUEST_DURATION;

void RESET_EVERYTHING(void);
void RESET_EVERYTHING_OPTIONAL_MOCKING(BOOL shouldMockPlaylistManager, BOOL shouldMockAnalyticsManager);

void REMOVE_MOCKS(void);

void pointMAUrlsToNothing(void);

void clearUserDefaults(void);

void waitFor( NSTimeInterval duration );
void waitFor1( NSTimeInterval duration, BOOL* finished );

void waitForQueuesToFinish(void);

void emptyRequestQueue(void);

int char2hex(unsigned char c);
