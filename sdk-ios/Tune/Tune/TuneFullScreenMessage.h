//
//  TuneFullScreenMessage.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessage.h"

@interface TuneFullScreenMessage : TuneInAppMessage

+ (TuneFullScreenMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary;

@end
