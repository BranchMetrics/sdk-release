//
//  TuneSlideInMessageFactory.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageFactory.h"

@interface TuneSlideInMessageFactory : TuneBaseMessageFactory

+ (TuneSlideInMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary;

@end
