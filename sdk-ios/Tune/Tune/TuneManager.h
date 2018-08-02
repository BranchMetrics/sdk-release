//
//  TuneManager.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneConfiguration;
@class TuneFileManager;
@class TuneSessionManager;
@class TuneSkyhookCenter;
@class TuneUserProfile;

// This singleton is responsible for keeping references to all major components
// so various parts of the system can be initialized with the TuneManager and then
// have access to its many counterparts.

@interface TuneManager : NSObject

@property (strong, nonatomic) TuneUserProfile *userProfile;
@property (strong, nonatomic) TuneSessionManager *sessionManager;

+ (TuneManager *)currentManager;
- (void)instantiateModules;

@end
