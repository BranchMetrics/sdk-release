//
//  MATUserAgentCollector.h
//  MobileAppTracker
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MATUserAgentCollector : NSObject

+(void) startCollection;
+(NSString*) userAgent;

@end
