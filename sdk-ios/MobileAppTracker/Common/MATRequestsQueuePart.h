//
//  MATRequestsQueuePart.h
//  MobileAppTracker
//
//  Created by Pavel Yurchenko on 7/26/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MATUtils.h"

@interface MATRequestsQueuePart : NSObject <NSXMLParserDelegate>
{
    NSMutableArray * requests_;
    
    NSString * fileName_;
    NSString * filePathName_;
    NSString * parentFolder_;
    
    NSInteger index_;
    BOOL modified_;
    BOOL loaded_;
    BOOL shouldLoadOnRequest_;
    NSUInteger loadedRequestsCount_;
}

@property (nonatomic, copy) NSString * fileName;
@property (nonatomic, copy) NSString * filePathName;
@property (nonatomic, copy) NSString * parentFolder;

@property (readonly) BOOL requestsLimitReached;
@property (readonly) BOOL empty;
@property (nonatomic, assign) NSUInteger queuedRequestsCount;
@property (nonatomic, assign) BOOL shouldLoadOnRequest;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign, getter = isModified) BOOL modified;


+ (id)partWithIndex:(NSInteger)index parentFolder:(NSString *)parentFolder;

- (id)initWithIndex:(NSInteger)index parentFolder:(NSString *)parentFolder;

- (BOOL)push:(NSDictionary*)requestData;
- (BOOL)pushToHead:(NSDictionary*)requestData;
- (NSDictionary*)pop;

- (BOOL)load;
- (void)save;

@end
