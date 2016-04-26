//
//  TuneModule.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

// Base class for any Tune component classes that need Skyhooks or a reference to the
// TuneManager class.

@class TuneManager;

@interface TuneModule : NSObject

@property (weak, nonatomic) TuneManager *tuneManager;

- (id)initWithTuneManager:(TuneManager *)tuneManager;
+ (id)moduleWithTuneManager:(TuneManager *)tuneManager;

- (void)bringUp;
- (void)bringDown;

- (void)registerSkyhooks;
- (void)unregisterSkyhooks;
- (NSString *)name;

@end
