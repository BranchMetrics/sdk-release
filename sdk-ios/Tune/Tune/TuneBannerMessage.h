//
//  TuneBannerMessage.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessage.h"

@interface TuneBannerMessage : TuneInAppMessage

@property(nonatomic, assign, readwrite) TuneMessageLocationType messageLocationType;
@property(nonatomic, strong, readwrite) NSNumber *duration;

+ (TuneBannerMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary;

@end
