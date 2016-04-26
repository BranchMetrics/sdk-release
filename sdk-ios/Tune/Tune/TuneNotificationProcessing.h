//
//  TuneNotificationProcessing.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneNotification.h"

@interface TuneNotificationProcessing : NSObject

+ (TuneNotification *)processUserInfoFromNotification:(NSDictionary *)userInfo withIdentifier:(NSString *)identifier;

@end
