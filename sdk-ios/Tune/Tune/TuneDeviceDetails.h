//
//  TuneDeviceDetails.h
//  In-App Messaging Test App
//
//  Created by Scott Wasserman on 7/17/14.
//  Copyright (c) 2014 Tune Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

// Consider removing this class entirely, it's lost most of it's methods with IAM removal.
// The remaining methods are fairly trivial.
@interface TuneDeviceDetails : NSObject

#if !TARGET_OS_WATCH
+ (BOOL)appIsRunningIniOS9OrAfter;
+ (BOOL)appIsRunningIniOS10OrAfter;
+ (BOOL)appIsRunningIniOSVersionOrAfter:(CGFloat)version;
#endif

@end
