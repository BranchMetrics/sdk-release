//
//  TunePopUpMessageFactory.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseMessageFactory.h"

@interface TunePopUpMessageFactory : TuneBaseMessageFactory

+ (TunePopUpMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary;

@end
