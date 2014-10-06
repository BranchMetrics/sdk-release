//
//  MATUtils_TestPrivateMethods.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 7/31/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATUtils.h"

@interface MATUtils ()

+ (NSData *)MatCustomBase64Decode:(NSString *)encodedString;
+ (NSString *)MatCustomBase64Encode:(NSData *)data;

@end
