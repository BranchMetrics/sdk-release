//
//  TuneAdUtilitiesUI.m
//
/*  Created by Gary Morris on 3/12/10.
 *  Copyright 2010-2011 Gary A. Morris. All rights reserved.
 *
 * This file is part of SDK_Utilities.repo
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this file. If not, see <http://www.gnu.org/licenses/>.
 */

#import "TuneAdUtilitiesUI.h"


//-----------------------------------------------------------------------------
// BOOL isPad()
//-----------------------------------------------------------------------------
BOOL isPad() {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

//-----------------------------------------------------------------------------
// BOOL isRetina();
//-----------------------------------------------------------------------------
BOOL isRetina()         // screen has a scale factor of > 1.5
{
    static CGFloat scale = -1.0f;
    
    if (scale < 0.0f) {
        scale = [UIScreen mainScreen].scale;
    }
    
    return scale > 1.5f;        // retina display has scale of 2.0, others 1.0
}

//-----------------------------------------------------------------------------
// isPortrait -- current orientation
//-----------------------------------------------------------------------------
BOOL isPortraitOr(UIDeviceOrientation orientation) {
    return !UIDeviceOrientationIsLandscape(orientation);
}

BOOL isPortrait() {
    return isPortraitOr([[UIDevice currentDevice] orientation]);
}

//-----------------------------------------------------------------------------
// tellParentToDismissModalVC (was dismissModalViewController)
// exit this view controller, return to parent, handle iOS 5 change
//-----------------------------------------------------------------------------
///#pragma GCC diagnostic ignored "-Wwarning-flag"
void tellParentToDismissModalVC(UIViewController* viewController)
{
    if ([viewController respondsToSelector:@selector(presentingViewController)]) {
        id presenter = [viewController performSelector:@selector(presentingViewController)];
        [presenter dismissViewControllerAnimated:YES completion: ^{ /* cleanup */ }];
        
    } else {
        [[viewController parentViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}

//-----------------------------------------------------------------------------
// findSuperviewOfClass
//-----------------------------------------------------------------------------
UIView* superviewOfClass(Class target, UIView* fromView)
{
    UIView* curView = fromView.superview;
    while (curView != nil && curView != fromView.window) {
        if ([curView isKindOfClass:target]) {
            return curView;
        }
        curView = curView.superview;
    }
    return nil;
}

// Ref: http://stackoverflow.com/questions/1340434/get-to-uiviewcontroller-from-uiview-on-iphone
UIViewController* firstAvailableUIViewController(UIView *aView)
{
    // convenience function for casting and to "mask" the recursive function
    return (UIViewController *)traverseResponderChainForUIViewController(aView);
}

id traverseResponderChainForUIViewController(UIView *aView)
{
    id nextResponder = [aView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        // parent view controller found, no action required
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        // recursive call
        nextResponder = (id)traverseResponderChainForUIViewController((UIView *)nextResponder);
    } else {
        // invalid view hierarchy, not expected
        nextResponder = nil;
    }
    
    return nextResponder;
}

UIInterfaceOrientationMask supportedOrientations()
{
    UIInterfaceOrientationMask allowedOrientation = UIInterfaceOrientationMaskAll;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_0)
    {
        NSString *key = isPad() ? @"UISupportedInterfaceOrientations~ipad" : @"UISupportedInterfaceOrientations";
        
        NSArray *allowedOrientations = (NSArray *)[[NSBundle mainBundle] objectForInfoDictionaryKey:key];
        
        BOOL supportsP = [allowedOrientations containsObject:@"UIInterfaceOrientationPortrait"];
        BOOL supportsPUD = [allowedOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"];
        BOOL supportsLL = [allowedOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"];
        BOOL supportsLR = [allowedOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"];
        
        if(supportsP)
        {
            allowedOrientation = UIInterfaceOrientationMaskPortrait;
        }
        else if(supportsPUD)
        {
            allowedOrientation = UIInterfaceOrientationMaskPortraitUpsideDown;
        }
        else if(supportsLL || supportsLR)
        {
            allowedOrientation = UIInterfaceOrientationMaskLandscape;
        }
    }
    else
    {
        allowedOrientation = (UIInterfaceOrientationMask)[[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:[[[UIApplication sharedApplication] delegate] window]];
    }
    
    return allowedOrientation;
}
