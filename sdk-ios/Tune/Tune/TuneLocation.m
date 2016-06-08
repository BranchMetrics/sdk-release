//
//  TuneLocation.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/3/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneLocation+Internal.h"

@implementation TuneLocation

- (id)copyWithZone:(NSZone *)zone {
    TuneLocation *location = [[[self class] allocWithZone:zone] init];
    
    location.longitude = [self.longitude copyWithZone:zone];
    location.latitude = [self.latitude copyWithZone:zone];
    location.altitude = [self.altitude copyWithZone:zone];
    
    location.horizontalAccuracy = [self.horizontalAccuracy copyWithZone:zone];
    location.verticalAccuracy = [self.verticalAccuracy copyWithZone:zone];
    location.timestamp = [self.timestamp copyWithZone:zone];
    
    return location;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.longitude = [aDecoder decodeObjectForKey:@"longitude"];
    self.latitude = [aDecoder decodeObjectForKey:@"latitude"];
    self.altitude = [aDecoder decodeObjectForKey:@"altitude"];
    self.horizontalAccuracy = [aDecoder decodeObjectForKey:@"horizontalAccuracy"];
    self.verticalAccuracy = [aDecoder decodeObjectForKey:@"verticalAccuracy"];
    self.timestamp = [aDecoder decodeObjectForKey:@"timestamp"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.longitude forKey:@"longitude"];
    [aCoder encodeObject:self.latitude forKey:@"latitude"];
    [aCoder encodeObject:self.altitude forKey:@"altitude"];
    [aCoder encodeObject:self.horizontalAccuracy forKey:@"horizontalAccuracy"];
    [aCoder encodeObject:self.verticalAccuracy forKey:@"verticalAccuracy"];
    [aCoder encodeObject:self.timestamp forKey:@"timestamp"];
}

#pragma mark -

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p> %@, %@, %@, %@, %@, %@", [self class], (void *)self, self.latitude, self.longitude, self.altitude, self.horizontalAccuracy, self.verticalAccuracy, self.timestamp];
}

@end
