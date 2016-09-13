//
//  TuneDeepAction.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const DEEPACTION_ID;
FOUNDATION_EXPORT NSString *const DEEPACTION_FRIENDLY_NAME;
FOUNDATION_EXPORT NSString *const DEEPACTION_DESCRIPTION;
FOUNDATION_EXPORT NSString *const DEEPACTION_APPROVED_VALUES;
FOUNDATION_EXPORT NSString *const DEEPACTION_DEFAULT_DATA;

typedef void(^CodeBlock)(NSDictionary *);

@interface TuneDeepAction : NSObject

@property (copy,nonatomic,readonly) NSString *deepActionId;
@property (copy,nonatomic,readonly) NSString *friendlyName;
@property (copy,nonatomic,readonly) NSString *deepActionDescription;
@property (strong,nonatomic,readonly) NSDictionary *approvedValues;
@property (strong,nonatomic,readonly) NSDictionary *defaultData;
@property (copy,nonatomic) CodeBlock action;

- (id)initWithDeepActionId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description action:(void (^)(NSDictionary *extra_data))action defaultData:(NSDictionary *)defaultData approvedValues:(NSDictionary *)approvedValues;

+ (BOOL)validateApprovedValues:(NSDictionary *)approvedValues;

- (NSDictionary *)toDictionary;

@end

