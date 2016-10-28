//
//  TuneDeviceDetails.m
//  In-App Messaging Test App
//
//  Created by Scott Wasserman on 7/17/14.
//  Copyright (c) 2014 Tune Mobile. All rights reserved.
//

#import "TuneDeviceDetails.h"
#import "TuneUtils.h"
#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

@implementation TuneDeviceDetails

+ (TuneDeviceDetails *)sharedDetails
{
	static TuneDeviceDetails *artisanMessageDeviceDetails = nil;
	if (!artisanMessageDeviceDetails) {

        // Init cache
		artisanMessageDeviceDetails = [[TuneDeviceDetails alloc] init];
#if TARGET_OS_IOS
        [artisanMessageDeviceDetails buildSuportedOrientationArray];
#endif
        [artisanMessageDeviceDetails findDeviceAppCanRunOn];
	}
	return artisanMessageDeviceDetails;
}

#pragma mark - Supported Devices

- (void)findDeviceAppCanRunOn {
    NSArray *deviceFamily = [[TuneUtils currentBundle] objectForInfoDictionaryKey:@"UIDeviceFamily"];
    _canRunOniPhone = NO;
    _canRunOniPad = NO;
    for (NSString *deviceFamilyKey in deviceFamily) {
        if ([deviceFamilyKey intValue] == 1) {
            _canRunOniPhone = YES;
        }
        else if ([deviceFamilyKey intValue] == 2) {
            _canRunOniPad = YES;
        }
        else if ([deviceFamilyKey intValue] == 3) {
            _canRunOnTV = YES;
        }
        else if ([deviceFamilyKey intValue] == 4) {
            _canRunOnWatch = YES;
        }
    }
}

- (BOOL)_appCanRunOniPhone {
    return _canRunOniPhone;
}

- (BOOL)_appCanRunOniPad {
    return _canRunOniPad;
}

- (BOOL)_appCanRunOnTV {
    return _canRunOnTV;
}

- (BOOL)_appCanRunOnWatch {
    return _canRunOnWatch;
}

+ (BOOL)appCanRunOniPhone {
    return [[TuneDeviceDetails sharedDetails] _appCanRunOniPhone];
}

+ (BOOL)appCanRunOniPad {
    return [[TuneDeviceDetails sharedDetails] _appCanRunOniPad];
}

+ (BOOL)appCanRunOnTV {
    return [[TuneDeviceDetails sharedDetails] _appCanRunOnTV];
}

+ (BOOL)appCanRunOnWatch {
    return [[TuneDeviceDetails sharedDetails] _appCanRunOnWatch];
}

+ (NSString *)getSupportedDeviceTypesString {
    NSMutableArray *supportedDevices = [[NSMutableArray alloc] init];
    if ([TuneDeviceDetails appCanRunOniPhone]) {
        [supportedDevices addObject:@"iPhone"];
    }
    if ([TuneDeviceDetails appCanRunOniPad]) {
        [supportedDevices addObject:@"iPad"];
    }
    return [supportedDevices componentsJoinedByString: @"|"];
}

#pragma mark - Supported Orientations

#if TARGET_OS_IOS

+ (BOOL)appSupportsLandscape {
    return [[TuneDeviceDetails sharedDetails] _appSupportsLandscape];
}

+ (BOOL)appSupportsPortrait {
    return [[TuneDeviceDetails sharedDetails] _appSupportsPortrait];
}

#else

+ (BOOL)appSupportsLandscape {
    return NO;
}

+ (BOOL)appSupportsPortrait {
    return YES;
}

#endif

#if TARGET_OS_IOS

- (BOOL)_appSupportsLandscape {
    return ([self _orientationIsSupportedByApp:UIInterfaceOrientationLandscapeLeft] ||
            [self _orientationIsSupportedByApp:UIInterfaceOrientationLandscapeRight]);
}

- (BOOL)_appSupportsPortrait {
    return ([self _orientationIsSupportedByApp:UIInterfaceOrientationPortrait] ||
            [self _orientationIsSupportedByApp:UIInterfaceOrientationPortraitUpsideDown]);
}

- (void)buildSuportedOrientationArray {
    _supportedOrientations = [TuneDeviceDetails getSupportedDeviceOrientations];
}

+ (BOOL)orientationIsSupportedByApp:(UIInterfaceOrientation)orientation {
    return [[TuneDeviceDetails sharedDetails] _orientationIsSupportedByApp:orientation];
}

- (BOOL)_orientationIsSupportedByApp:(UIInterfaceOrientation)orientation {
    return [_supportedOrientations containsObject:[TuneDeviceDetails getDeviceOrientationString:orientation]];
}

+ (NSArray *)getSupportedDeviceOrientations {

    NSMutableArray *rawSupportedDeviceOrientations = [[TuneUtils currentBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

    [rawSupportedDeviceOrientations removeObject:@"UIDeviceOrientationFaceUp"];
    [rawSupportedDeviceOrientations removeObject:@"UIDeviceOrientationFaceDown"];

    if ([TuneDeviceDetails runningOnTablet]) {
        return [NSArray arrayWithArray:rawSupportedDeviceOrientations];;
    }
    else {
        // Don't send UIInterfaceOrientationPortraitUpsideDown in this array it won't work properly on the iPhone;
        [rawSupportedDeviceOrientations removeObject:@"UIInterfaceOrientationPortraitUpsideDown"];

        return [NSArray arrayWithArray:rawSupportedDeviceOrientations];
    }
}

#endif

#if TARGET_OS_IOS

+ (NSString *)getSupportedDeviceOrientationsString {
    NSMutableArray *supportedOrientations = [[NSMutableArray alloc] init];

    for (NSString *appleOrientation in [TuneDeviceDetails getSupportedDeviceOrientations]) {
        NSString *artisanOrientation = [TuneDeviceDetails getArtisanDeviceOrientationFromString:appleOrientation];

        if (artisanOrientation != nil) {
            [supportedOrientations addObject:artisanOrientation];
        }
    }

    return [supportedOrientations componentsJoinedByString: @"|"];
}

#else

+ (NSString *)getSupportedDeviceOrientationsString {
    return @"Portrait";
}

#endif

#pragma mark - Device Currently Runninng On

+ (BOOL)runningOnPhone {
#if TARGET_OS_WATCH
    return NO;
#else
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
#endif
}

+ (BOOL)runningOnTablet {
#if TARGET_OS_WATCH
    return NO;
#else
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
#endif
}

+ (BOOL)runningOnTV {
#if TARGET_OS_TV
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomTV;
#else
    return NO;
#endif
}

+ (int)maximumScreenDimension {
#if TARGET_OS_WATCH
    return MAX([[WKInterfaceDevice currentDevice] screenBounds].size.height, [[WKInterfaceDevice currentDevice] screenBounds].size.width);
#else
    return MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
#endif
}

+ (BOOL)runningOn480HeightPhone {
    return ([TuneDeviceDetails maximumScreenDimension] < 568);
}

+ (BOOL)runningOn568HeightPhone {
    return ([TuneDeviceDetails maximumScreenDimension] > 480) && ([TuneDeviceDetails maximumScreenDimension] < 667);
}

+ (BOOL)runningOn667HeightPhone {
    return ([TuneDeviceDetails maximumScreenDimension] > 568) && ([TuneDeviceDetails maximumScreenDimension] < 736);
}

+ (BOOL)runningOn736HeightPhone {
    return ([TuneDeviceDetails maximumScreenDimension] > 667);
}

#pragma mark - Retina Checks

+ (BOOL)isRetina {
#if TARGET_OS_WATCH
    return NO;
#else
    return [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            [UIScreen mainScreen].scale == 2.0;
#endif
}

#pragma mark - Checking iOS Version

#if !TARGET_OS_WATCH
+ (BOOL)appIsRunningIniOS6OrBefore {
    return ([[UIDevice currentDevice].systemVersion floatValue] < 7.0);
}

+ (BOOL)appIsRunningIniOS7 {
    return ( ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) && ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) );
}

+ (BOOL)appIsRunningIniOS7OrAfter {
    return [self appIsRunningIniOSVersionOrAfter:7.0];
}

+ (BOOL)appIsRunningIniOS8OrAfter {
    return [self appIsRunningIniOSVersionOrAfter:8.0];
}

+ (BOOL)appIsRunningIniOS9OrAfter {
    return [self appIsRunningIniOSVersionOrAfter:9.0];
}

+ (BOOL)appIsRunningIniOS10OrAfter {
    return [self appIsRunningIniOSVersionOrAfter:10.0];
}

+ (BOOL)appIsRunningIniOSVersionOrAfter:(CGFloat)version {
    return [[UIDevice currentDevice].systemVersion floatValue] >= version;
}
#endif

#pragma mark - Tune Message Orientations For Current Device

+ (TuneMessageDeviceOrientation)getPortraitForDevice {
    if ([TuneDeviceDetails runningOnPhone]) {
        if ([TuneDeviceDetails runningOn480HeightPhone]) {
            return TuneMessageOrientationPhonePortrait_480;
        } else if ([TuneDeviceDetails runningOn568HeightPhone]) {
            return TuneMessageOrientationPhonePortrait_568;
        } else if ([TuneDeviceDetails runningOn667HeightPhone]) {
            return TuneMessageOrientationPhonePortrait_667;
        } else {
            return TuneMessageOrientationPhonePortrait_736;
        }
    }
    else {
        return TuneMessageOrientationTabletPortrait;
    }
}

+ (TuneMessageDeviceOrientation)getPortraitUpsideDownForDevice {
    if ([TuneDeviceDetails runningOnPhone]) {
        if ([TuneDeviceDetails runningOn480HeightPhone]) {
            return TuneMessageOrientationPhonePortraitUpsideDown_480;
        } else if ([TuneDeviceDetails runningOn568HeightPhone]) {
            return TuneMessageOrientationPhonePortraitUpsideDown_568;
        } else if ([TuneDeviceDetails runningOn667HeightPhone]) {
            return TuneMessageOrientationPhonePortraitUpsideDown_667;
        } else {
            return TuneMessageOrientationPhonePortraitUpsideDown_736;
        }
    }
    else {
        return TuneMessageOrientationTabletPortraitUpsideDown;
    }
}

+ (TuneMessageDeviceOrientation)getLandscapeLeftForDevice {
    if ([TuneDeviceDetails runningOnPhone]) {
        if ([TuneDeviceDetails runningOn480HeightPhone]) {
            return TuneMessageOrientationPhoneLandscapeLeft_480;
        } else if ([TuneDeviceDetails runningOn568HeightPhone]) {
            return TuneMessageOrientationPhoneLandscapeLeft_568;
        } else if ([TuneDeviceDetails runningOn667HeightPhone]) {
            return TuneMessageOrientationPhoneLandscapeLeft_667;
        } else {
            return TuneMessageOrientationPhoneLandscapeLeft_736;
        }
    }
    else {
        return TuneMessageOrientationTabletLandscapeLeft;
    }
}

+ (TuneMessageDeviceOrientation)getLandscapeRightForDevice {
    if ([TuneDeviceDetails runningOnPhone]) {
        if ([TuneDeviceDetails runningOn480HeightPhone]) {
            return TuneMessageOrientationPhoneLandscapeRight_480;
        } else if ([TuneDeviceDetails runningOn568HeightPhone]) {
            return TuneMessageOrientationPhoneLandscapeRight_568;
        } else if ([TuneDeviceDetails runningOn667HeightPhone]) {
            return TuneMessageOrientationPhoneLandscapeRight_667;
        } else {
            return TuneMessageOrientationPhoneLandscapeRight_736;
        }
    }
    else {
        return TuneMessageOrientationTabletLandscapeRight;
    }
}

#pragma mark - Orientation Value Conversions

#if TARGET_OS_IOS

+ (NSString *)getDeviceOrientationString:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return @"UIInterfaceOrientationPortrait";
        case UIInterfaceOrientationPortraitUpsideDown:
            return @"UIInterfaceOrientationPortraitUpsideDown";
        case UIInterfaceOrientationLandscapeLeft:
            return @"UIInterfaceOrientationLandscapeLeft";
        case UIInterfaceOrientationLandscapeRight:
            return @"UIInterfaceOrientationLandscapeRight";
        default:
            return @"Invalid Interface Orientation";
    }
}

+ (UIInterfaceOrientation)getUIInterfaceOrientationFromString:(NSString *)orientationString {
    if ( ([orientationString isEqualToString:@"UIDeviceOrientationPortrait"]) || ([orientationString isEqualToString:@"UIInterfaceOrientationPortrait"]) ) {
        return UIInterfaceOrientationPortrait;
    }
    else if ( ([orientationString isEqualToString:@"UIDeviceOrientationPortraitUpsideDown"]) || ([orientationString isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) ) {
        return UIInterfaceOrientationPortraitUpsideDown;
    }
    else if ( ([orientationString isEqualToString:@"UIDeviceOrientationLandscapeLeft"]) || ([orientationString isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) ) {
        return UIInterfaceOrientationLandscapeRight;
    }
    else if ( ([orientationString isEqualToString:@"UIDeviceOrientationLandscapeRight"]) || ([orientationString isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) ) {
        return UIInterfaceOrientationLandscapeLeft;
    }
    else if ([orientationString isEqualToString:@"UIDeviceOrientationUnknown"]) {
        return UIInterfaceOrientationUnknown;
    }

    return UIInterfaceOrientationUnknown;
}

#endif

+ (NSString *)getArtisanDeviceOrientationFromString:(NSString *)appleOrientationString {
    if ( ([appleOrientationString isEqualToString:@"UIDeviceOrientationPortrait"]) || ([appleOrientationString isEqualToString:@"UIInterfaceOrientationPortrait"]) ) {
        return @"Portrait";
    }
    else if ( ([appleOrientationString isEqualToString:@"UIDeviceOrientationPortraitUpsideDown"]) || ([appleOrientationString isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) ) {
        return @"UpsideDown";
    }
    else if ( ([appleOrientationString isEqualToString:@"UIDeviceOrientationLandscapeRight"]) || ([appleOrientationString isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) ) {
        return @"LandscapeRight";
    }
    else if ( ([appleOrientationString isEqualToString:@"UIDeviceOrientationLandscapeLeft"]) || ([appleOrientationString isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) ) {
        return @"LandscapeLeft";
    }

    return nil;
}
@end
