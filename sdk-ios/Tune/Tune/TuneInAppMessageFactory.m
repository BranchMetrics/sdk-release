//
//  TuneInAppMessageFactory.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageFactory.h"
#import "TuneSlideInMessageFactory.h"
#import "TuneTakeOverMessageFactory.h"
#import "TunePopUpMessageFactory.h"

@implementation TuneInAppMessageFactory

+ (TuneBaseMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    NSDictionary *message = messageDictionary[@"message"];
    
    if (message) {
        NSString *messageTypeString = message[@"messageType"];

        if ([messageTypeString isEqualToString:@"TuneMessageTypeSlideIn"]) {
            return [TuneSlideInMessageFactory buildMessageFromMessageDictionary:messageDictionary];
        } else if ([messageTypeString isEqualToString:@"TuneMessageTypePopUp"]) {
            return [TunePopUpMessageFactory buildMessageFromMessageDictionary:messageDictionary];
        } else if ([messageTypeString isEqualToString:@"TuneMessageTypeTakeOver"]) {
            return [TuneTakeOverMessageFactory buildMessageFromMessageDictionary:messageDictionary];
        }
    }
    
    return nil;
}

@end
