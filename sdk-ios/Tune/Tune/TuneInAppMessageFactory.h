//
//  TuneInAppMessageFactory.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneBaseMessageFactory.h"

@interface TuneInAppMessageFactory : NSObject

+ (TuneBaseMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)dictionary;

@end
