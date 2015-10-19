//
//  TuneAdMetadata.m
//  Tune
//
//  Created by Harshal Ogale on 11/14/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneAdMetadata.h"

@implementation TuneAdMetadata

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // default target gender
        _gender = TuneGenderUnknown;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    TuneAdMetadata *meta = [[TuneAdMetadata allocWithZone: zone] init];
    meta.birthDate = self.birthDate;
    meta.keywords = self.keywords;
    meta.customTargets = self.customTargets;
    meta.gender = self.gender;
    meta.latitude = self.latitude;
    meta.longitude = self.longitude;
    meta.altitude = self.altitude;
    meta.debugMode = self.debugMode;
    
    return meta;
}

@end
