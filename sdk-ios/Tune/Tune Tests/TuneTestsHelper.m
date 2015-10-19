//
//  TuneTestsHelper.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import "TuneTestsHelper.h"

#import "../Tune/Common/TuneEventQueue.h"
#import "../Tune/Common/TuneKeyStrings.h"
#import "../Tune/Common/TuneUtils.h"

NSString* const kTestAdvertiserId = @"877";
NSString* const kTestConversionKey = @"8c14d6bbe466b65211e781d62e301eec";
NSString* const kTestBundleId = @"com.mobileapptracking.iosunittest";

const NSTimeInterval TUNE_TEST_NETWORK_REQUEST_DURATION = 3.;

void waitFor( NSTimeInterval duration )
{
    // block test thread while app executes
    NSDate *stopDate = [[NSDate date] dateByAddingTimeInterval:duration];
    do [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:stopDate];
    while( [stopDate timeIntervalSinceNow] > 0 );
}

void emptyRequestQueue()
{
    [TuneEventQueue drain];
}

void networkOffline()
{
    [TuneUtils overrideNetworkReachability:[@NO stringValue]];
}

void networkOnline()
{
    [TuneUtils overrideNetworkReachability:[@YES stringValue]];
}

int char2hex(unsigned char c) {
    switch (c) {
        case '0' ... '9':
            return c - '0';
        case 'a' ... 'f':
            return c - 'a' + 10;
        case 'A' ... 'F':
            return c - 'A' + 10;
        default:
            return 0xFF;
    }
}
