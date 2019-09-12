//
//  TuneLog.h
//  Tune
//
//  Created by Jennifer Owens on 6/27/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TuneLogBlock)(NSString * _Nonnull message);

@interface TuneLog : NSObject

@property (nonatomic, nullable, copy) TuneLogBlock logBlock;
@property (nonatomic, readwrite, assign) BOOL verbose;

+ (nonnull instancetype)shared;

- (void)logError:(nullable NSString *)message;
- (void)logVerbose:(nullable NSString *)message;

@end
