//
//  TuneMessageOrientationState.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageOrientationState.h"
#import "TuneDeviceDetails.h"

@implementation TuneMessageOrientationState

+ (TuneMessageOrientationState *)sharedState {
    static TuneMessageOrientationState *artisanMessageOrientationState = nil;
    if (!artisanMessageOrientationState) {
        // Init cache
        artisanMessageOrientationState = [[TuneMessageOrientationState alloc] init];
#if TARGET_OS_IOS
        [artisanMessageOrientationState buildOrientationsArray];
        [artisanMessageOrientationState initOrientation];
#endif
    }
    return artisanMessageOrientationState;
}
#if TARGET_OS_IOS
+ (void)startTrackingOrientation {

    [[TuneMessageOrientationState sharedState] initOrientation];
}
#endif

+ (CGSize)getCalculatedWindowSizeForCurrentOrientation {
    return [[TuneMessageOrientationState sharedState] _getCalculatedWindowSizeForCurrentOrientation];
}

- (CGSize)_getCalculatedWindowSizeForCurrentOrientation {
    CGFloat currentScreenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat currentScreenHeight = [UIScreen mainScreen].bounds.size.height;

#if TARGET_OS_IOS
    UIDeviceOrientation orientation = [TuneMessageOrientationState getCurrentOrientation];
    
    if ( (orientation == UIDeviceOrientationLandscapeLeft) ||
        (orientation == UIDeviceOrientationLandscapeRight) ) {
        if (currentScreenHeight > currentScreenWidth) {
            // Need to switch these they are incorrect
            return CGSizeMake(currentScreenHeight,currentScreenWidth);
        }
        else {
            // They'are correct
            return CGSizeMake(currentScreenWidth,currentScreenHeight);
        }
    }
    else {
        if (currentScreenWidth > currentScreenHeight) {
            // Need to switch these they are incorrect
            return CGSizeMake(currentScreenHeight,currentScreenWidth);
        }
        else {
            // They'are correct
            return CGSizeMake(currentScreenWidth,currentScreenHeight);
        }
    }
#endif
    return CGSizeMake(currentScreenWidth,currentScreenHeight);
}

#if TARGET_OS_IOS
- (void)initOrientation {
    _lastOrientation = [[UIDevice currentDevice] orientation];
}

- (void)buildOrientationsArray {
    _orientations = @[@(UIDeviceOrientationPortrait),
                      @(UIDeviceOrientationLandscapeRight),
                      @(UIDeviceOrientationPortraitUpsideDown),
                      @(UIDeviceOrientationLandscapeLeft)];
}

+ (UIDeviceOrientation)getCurrentOrientation {
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    
    // If the current orientation is unknown (happens in the simulator)
    // then return the first supported orientation
    if (![TuneDeviceDetails orientationIsSupportedByApp:currentOrientation]) {
        NSArray *supportedOrientations = [TuneDeviceDetails getSupportedDeviceOrientations];
        
        if (supportedOrientations) {
            currentOrientation = [TuneDeviceDetails getUIDeviceOrientationFromString:supportedOrientations[0]];
        }
        
        // Typically if the current orientation is not supported we will return portrait (or whatever is the first supported)
        // but if the app supports landscape and we detect that the screen is in landscape, return the first landscape orientation.
        if (currentOrientation == UIDeviceOrientationPortrait && [TuneDeviceDetails appSupportsLandscape]) {
            CGFloat currentScreenWidth = [UIScreen mainScreen].bounds.size.width;
            CGFloat currentScreenHeight = [UIScreen mainScreen].bounds.size.height;
            
            if (currentScreenWidth > currentScreenHeight) {
                // we are actually in landscape so guess that instead
                if ([TuneDeviceDetails orientationIsSupportedByApp:UIDeviceOrientationLandscapeLeft]) {
                    currentOrientation = UIDeviceOrientationLandscapeLeft;
                } else {
                    // we know the app supports landscape, so by process of elimination it's right
                    currentOrientation = UIDeviceOrientationLandscapeRight;
                }
            }
        }
    }
    
    return currentOrientation;
}

+ (NSNumber *)calculateAngleToRotateView {
    return [[TuneMessageOrientationState sharedState] _calculateAngleToRotateView];
}

+ (NSNumber *)calculateAngleToRotateViewFromPortrait {
    return [[TuneMessageOrientationState sharedState] _calculateAngleToRotateViewFromPortrait];
}

- (NSNumber *)_calculateAngleToRotateViewFromPortrait {
    _lastOrientation = UIDeviceOrientationPortrait;
    return [self _calculateAngleToRotateView];
}

- (NSNumber *)_calculateAngleToRotateView {
    NSNumber *calculatedAngle = nil;
    
    if ([TuneMessageOrientationState currentOrientationIsSupportedByApp]) {
        UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
        if (currentOrientation == _lastOrientation) {
            // do nothing
        }
        else {
            int endingIndex = [self findIndexOfOrientation:currentOrientation];
            float angle = M_PI_2 * endingIndex * -1;
            calculatedAngle = @(angle);
        }
        
        _lastOrientation = currentOrientation;
    }
    else {
        // Ignore, not supported by device
    }
    
    return calculatedAngle;
}

- (int)findIndexOfOrientation:(UIDeviceOrientation)orientation {
    return (int)[_orientations indexOfObject:[NSNumber numberWithInt:orientation]];
}

+ (BOOL)currentOrientationIsSupportedByApp {
    return [[TuneMessageOrientationState sharedState] _currentOrientationIsSupportedByApp];
}

- (BOOL)_currentOrientationIsSupportedByApp {
    return [TuneDeviceDetails orientationIsSupportedByApp:[[UIDevice currentDevice] orientation]];
}

#else

+ (NSNumber *)calculateAngleToRotateViewFromPortrait {
    return 0;
}

#endif

@end
