//
//  TuneSkyhookPayload.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneSkyhookPayload : NSObject

@property (readonly) NSDictionary *userInfo;
@property (weak, readonly) id object;
@property (readonly) NSString *skyhookName;

/* The observer sets this if there's any data it wants to pass back. */
@property (strong, nonatomic) id returnObject;

- (instancetype)initWithName:(NSString *)skyhookName object:(id)skyhookObject userInfo:(NSDictionary *)userInfo;

@end
