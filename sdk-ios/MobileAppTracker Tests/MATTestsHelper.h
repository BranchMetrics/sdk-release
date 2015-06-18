//
//  MATTests.h
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../MobileAppTracker/Common/MATEventQueue.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"

FOUNDATION_EXPORT NSString* const kTestAdvertiserId;
FOUNDATION_EXPORT NSString* const kTestConversionKey;
FOUNDATION_EXPORT NSString* const kTestBundleId;
FOUNDATION_EXPORT const NSTimeInterval MAT_TEST_NETWORK_REQUEST_DURATION;

void waitFor( NSTimeInterval duration );

void emptyRequestQueue();
void networkOffline();
void networkOnline();

int char2hex(unsigned char c);
