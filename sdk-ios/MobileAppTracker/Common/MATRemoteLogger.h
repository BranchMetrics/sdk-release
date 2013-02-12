//
//  MATRemoteLogger.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/17/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MATRemoteLogger : NSObject
{
    NSString * urlString_;
}
- (id)initWithURL:(NSString*)urlString;

- (void)log:(NSString*)data;

@end
