//
//  TuneModalMessage.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessage.h"

@interface TuneModalMessage : TuneInAppMessage

@property (nonatomic, assign, readwrite) TuneModalMessageEdgeStyle edgeStyle;
@property (nonatomic, assign, readwrite) TuneMessageBackgroundMaskType backgroundMaskType;
@property (nonatomic, strong, readwrite) NSNumber *width;
@property (nonatomic, strong, readwrite) NSNumber *height;

+ (TuneModalMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary;

@end
