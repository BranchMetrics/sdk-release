//
//  MATRequestsQueue.h
//  MobileAppTracker
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MATRequestsQueuePart.h"
#import "MATUtils.h"
#import "MATKeyStrings.h"

@interface MATRequestsQueue : NSObject <NSXMLParserDelegate>
{
    NSMutableArray * queueParts_;
}

@property (readonly) NSUInteger queuedRequestsCount;

- (void)push:(NSDictionary*)object;
- (void)pushToHead:(NSDictionary*)object;
- (NSDictionary*)pop;

- (void)save;
- (BOOL)load;

/*!
 Last method to be called after which MATRequestsQueue instance is never to be accessed or created. This method deletes the queue storage file from disk.
 */
- (void)closedown;

/*!
 Checks if the legacy queuing file exists.
 */
+ (BOOL)exists;

@end
