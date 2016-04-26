//
//  TuneTakeOverMessageFactory.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseMessageFactory.h"

@interface TuneTakeOverMessageFactory : TuneBaseMessageFactory

+ (TuneTakeOverMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary;

@end
