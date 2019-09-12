//
//  TuneUserAgentCollector.h
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// Copied and modified from Branch SDK
@interface TuneUserAgentCollector : NSObject

+ (TuneUserAgentCollector *)shared;

@property (nonatomic, copy, readwrite) NSString *userAgent;

- (void)loadUserAgentWithCompletion:(nullable void (^)(NSString * _Nullable userAgent))completion;

@end

NS_ASSUME_NONNULL_END
