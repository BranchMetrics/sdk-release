//
//  TuneIfa.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/3/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneIfa.h"
#import "TuneUtils.h"

@interface TuneIfa ()

@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, assign) BOOL trackingEnabled;

@end

@implementation TuneIfa

+ (TuneIfa *)ifaInfo
{
    TuneIfa *info = nil;
    
    Class aIdManager = [TuneUtils getClassFromString:@"ASIdentifierManager"];
    
    if(aIdManager)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        id sharedManager = [aIdManager performSelector:@selector(sharedManager)];
        NSUUID *ifaUUID = (NSUUID *)[sharedManager performSelector:@selector(advertisingIdentifier)];
        
        SEL selIsAdvertisingTrackingEnabled = @selector(isAdvertisingTrackingEnabled);
#pragma clang diagnostic pop
        NSMethodSignature* signature = [sharedManager methodSignatureForSelector:selIsAdvertisingTrackingEnabled];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:sharedManager];
        [invocation setSelector:selIsAdvertisingTrackingEnabled];
        [invocation invoke];
        
        BOOL adTrackingEnabled = NO;
        [invocation getReturnValue:&adTrackingEnabled];
        
        info = [TuneIfa new];
        info.ifa = [ifaUUID UUIDString];
        info.trackingEnabled = adTrackingEnabled;
    }
    
    return info;
}

@end
