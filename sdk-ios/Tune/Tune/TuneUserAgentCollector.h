//
//  TuneUserAgentCollector.h
//  Tune
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TuneUserAgentCollector : NSObject

+ (void)startCollection;
+ (NSString*)userAgent;

@end
