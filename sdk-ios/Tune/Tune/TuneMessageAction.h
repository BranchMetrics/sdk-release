//
//  TuneMessageAction.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

@interface TuneMessageAction : NSObject

@property (nonatomic, copy) NSString *deepActionName;
@property (nonatomic, copy) NSDictionary *deepActionData;
@property (nonatomic, copy) NSString *url;

- (void)performAction;

@end
