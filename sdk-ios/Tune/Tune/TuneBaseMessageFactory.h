//
//  TuneBaseMessageFactory.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneCampaign.h"
#import "TuneMessageDisplayFrequency.h"
#import "TunePointerSet.h"

enum TuneMessageFrequencyScope {
    TuneMessageFrequencyScopeInstall = 1,
    TuneMessageFrequencyScopeSession,
    TuneMessageFrequencyScopeDays,
    TuneMessageFrequencyScopeEvents
};
typedef enum TuneMessageFrequencyScope TuneMessageFrequencyScope;

@interface TuneBaseMessageFactory : NSObject

@property (nonatomic, copy) NSDictionary *messageDictionary;
@property (strong, nonatomic) NSMutableDictionary *images;
@property (nonatomic, copy) NSString *messageID;
@property (nonatomic, copy) NSString *campaignStepID;
@property (strong, nonatomic) TuneCampaign *campaign;

@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@property (nonatomic) int limit;
@property (nonatomic) TuneMessageFrequencyScope scope;
@property (nonatomic) int lifetimeMaximum;

@property (strong, nonatomic) TunePointerSet *visibleViews;

- (NSString *)getMessageID;
- (NSString *)getTriggerEvent;
- (NSDictionary *)toDictionary;

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary;
- (void)buildAndShowMessage;
- (void)dismissMessage;

- (void)addImageURLForProperty:(NSString *)property inMessageDictionary:(NSDictionary *)message;
- (void)acquireImagesWithDispatchGroup:(dispatch_group_t)group; // Go fetch the images
- (BOOL)hasAllAssets; // Have all of the images been downloaded to the device?

- (BOOL)shouldDisplayBasedOnFrequencyModel:(TuneMessageDisplayFrequency *)frequencyModel;

@end
