//
//  TuneModule.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneModule.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"

@implementation TuneModule

#pragma mark - Initialization
- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [self init];
    if (self) {
        _tuneManager = tuneManager;
    }
    return self;
}

+ (id)moduleWithTuneManager:(TuneManager *)tuneManager {
    return [[[self class] alloc] initWithTuneManager:tuneManager];
}

 - (void)dealloc {
     [[TuneSkyhookCenter defaultCenter] removeObserver:self];
 }

#pragma mark - Enable/Disable

- (void)bringUp {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)bringDown {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

#pragma mark - Skyhook

- (void)registerSkyhooks {
    // override in subclass
}

- (void)unregisterSkyhooks {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

#pragma mark - Identification
- (NSString *)name {
    return NSStringFromClass([self class]);
}


@end
