//
//  MATRequestsQueue.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MATRequestsQueue : NSObject <NSXMLParserDelegate>
{
    NSMutableArray * queueParts_;
}

@property (readonly) NSUInteger queuedRequestsCount;

- (void)push:(NSDictionary*)object;
- (NSDictionary*)pop;

- (void)save;
- (BOOL)load;

@end
