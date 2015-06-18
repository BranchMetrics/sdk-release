//
//  MATStoreKitDelegate.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 4/20/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface MATStoreKitDelegate : NSObject

+ (void)startObserver;
+ (void)stopObserver;

@end
