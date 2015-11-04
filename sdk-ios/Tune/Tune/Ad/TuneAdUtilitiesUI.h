//
//  TuneAdUtilitiesUI.h
//  Tune
//
//  Created by Harshal Ogale on 5/16/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

BOOL isPad();
BOOL isRetina();
#if TARGET_OS_IOS
BOOL isPortraitOr(UIDeviceOrientation orientation);
#endif
BOOL isPortrait();

void tellParentToDismissModalVC(UIViewController* viewController);

UIViewController* firstAvailableUIViewController(UIView *aView);

id traverseResponderChainForUIViewController(UIView *aView);

#if TARGET_OS_IOS
UIInterfaceOrientationMask supportedOrientations();
#endif
