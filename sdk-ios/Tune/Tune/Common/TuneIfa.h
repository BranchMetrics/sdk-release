//
//  TuneIfa.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/3/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneIfa : NSObject

@property (nonatomic, copy, readonly) NSString *ifa;
@property (nonatomic, assign, readonly) BOOL trackingEnabled;

/*!
 Collects IFA if ASIdentifierManager class in AdSupport.framework is dynamically accessible.
 @return An instance of TuneIfa
 */
+ (TuneIfa *)ifaInfo;

@end
