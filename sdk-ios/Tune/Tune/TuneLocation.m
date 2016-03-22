//
//  TuneLocation.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/3/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "Common/TuneLocation_internal.h"

@implementation TuneLocation

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> %@, %@, %@, %@, %@, %@", [self class], self, self.latitude, self.longitude, self.altitude, self.horizontalAccuracy, self.verticalAccuracy, self.timestamp];
}

@end
