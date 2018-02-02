//
//  SmartWhereForDelegateTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 6/28/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import "SmartWhereForDelegateTest.h"

@implementation SmartWhereForDelegateTest
- (nullable id)didReceiveLocalNotification:(UILocalNotification*)notification{
    return nil; // returns nil because this is a stub
}
- (nullable id)willPresentNotification:(UNNotification *)notification{
    return nil; // returns nil because this is a stub
}
- (BOOL)didReceiveNotificationResponse:(UNNotificationResponse *)response{
    return NO;
}

@end

