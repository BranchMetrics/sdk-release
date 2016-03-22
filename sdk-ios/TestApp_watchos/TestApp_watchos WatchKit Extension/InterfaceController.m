//
//  InterfaceController.m
//  TestApp_watchOS WatchKit Extension
//
//  Created by Harshal Ogale on 10/7/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "InterfaceController.h"

@import MobileAppTrackerTestApp_watchOS;

@interface InterfaceController() <TuneDelegate>

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    
    NSLog(@"InterfaceController awakeWithContext");
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)buttonTapped {
    
    [Tune measureEventName:@"event1"];
}

@end
