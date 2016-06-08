//
//  TuneMessageDisplayFrequency.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageDisplayFrequency.h"

@implementation TuneMessageDisplayFrequency

- (id)initWithCampaignID:(NSString *)campaignID eventMD5:(NSString *)eventMD5 {
    self = [super init];
    
    if (self) {
        self.campaignID = campaignID;
        self.eventMD5 = eventMD5;
        self.lifetimeShownCount = 0;
        self.eventsSeenSinceShown = 0;
        self.numberOfTimesShownThisSession = 0;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    /*
     @property (nonatomic, copy) NSString *campaignID;
     @property (nonatomic, copy) NSString *eventMD5;
     @property (strong, nonatomic) NSDate *lastShownDateTime;
     @property (nonatomic) NSNumber *lifetimeShownCount;
     @property (nonatomic) NSNumber *eventsSeenSinceShown;
     @property (nonatomic) NSNumber *numberOfTimesShownThisSession;
     */
    
    [encoder encodeObject:self.campaignID forKey:@"campaignID"];
    [encoder encodeObject:self.eventMD5 forKey:@"eventMD5"];
    [encoder encodeObject:self.lastShownDateTime forKey:@"lastShowDateTime"];
    [encoder encodeObject:@(self.lifetimeShownCount) forKey:@"lifetimeShownCount"];
    [encoder encodeObject:@(self.eventsSeenSinceShown) forKey:@"eventsSeenSinceShown"];
    [encoder encodeObject:@(self.numberOfTimesShownThisSession) forKey:@"numberOfTimesShownThisSession"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if( self != nil )
    {
        /*
         @property (nonatomic, copy) NSString *campaignID;
         @property (nonatomic, copy) NSString *eventMD5;
         @property (strong, nonatomic) NSDate *lastShownDateTime;
         @property (nonatomic) NSNumber *lifetimeShownCount;
         @property (nonatomic) NSNumber *eventsSeenSinceShown;
         @property (nonatomic) NSNumber *numberOfTimesShownThisSession;
         */
        
        self.campaignID = [decoder decodeObjectForKey:@"campaignID"];
        self.eventMD5 = [decoder decodeObjectForKey:@"eventMD5"];
        self.lastShownDateTime = [decoder decodeObjectForKey:@"lastShowDateTime"];
        self.lifetimeShownCount = [[decoder decodeObjectForKey:@"lifetimeShownCount"] intValue];
        self.eventsSeenSinceShown = [[decoder decodeObjectForKey:@"eventsSeenSinceShown"] intValue];
        self.numberOfTimesShownThisSession = [[decoder decodeObjectForKey:@"numberOfTimesShownThisSession"] intValue];
    }
    return self;
}

@end
