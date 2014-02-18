//
//  MATTests.h
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MATKeyStrings.h"

extern NSString* const kTestAdvertiserId;
extern NSString* const kTestConversionKey;
extern NSString* const kTestBundleId;


void waitFor( NSTimeInterval duration );

void emptyRequestQueue();


@interface MATTests : NSObject

@end
