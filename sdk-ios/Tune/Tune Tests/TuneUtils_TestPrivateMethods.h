//
//  TuneUtils_TestPrivateMethods.h
//  Tune
//
//  Created by Harshal Ogale on 7/31/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "../Tune/Common/TuneUtils.h"

@interface TuneUtils ()

+ (NSData *)tuneCustomBase64Decode:(NSString *)encodedString;
+ (NSString *)tuneCustomBase64Encode:(NSData *)data;

@end
