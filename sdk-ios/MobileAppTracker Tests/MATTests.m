//
//  MATTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import "MATTests.h"
#import "MATRequestsQueue.h"
#import "MATConnectionManager.h"

NSString* const kTestAdvertiserId = @"877";
NSString* const kTestConversionKey = @"8c14d6bbe466b65211e781d62e301eec";
NSString* const kTestBundleId = @"com.mobileapptracking.iosunittest";


void waitFor( NSTimeInterval duration )
{
    // block test thread while app executes
    NSDate *stopDate = [[NSDate date] dateByAddingTimeInterval:duration];
    do [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:stopDate];
    while( [stopDate timeIntervalSinceNow] > 0 );
}


void emptyRequestQueue()
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    MATConnectionManager *cm = [mat performSelector:@selector(connectionManager)];
    MATRequestsQueue *requestsQueue = [cm performSelector:@selector(requestsQueue)];
    while( [requestsQueue pop] ); // clear queue
    [cm performSelector:@selector(stopQueueDump)];
#pragma clang diagnostic pop
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


@implementation MATTests

@end
