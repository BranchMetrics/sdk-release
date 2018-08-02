//
//  TuneXCTestCase.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 5/11/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneTestsHelper.h"
#import "TuneConfiguration.h"
#import "TuneManager.h"

@interface TuneXCTestCase : XCTestCase

/**
 Uses mock objects for each of the provided classes.
 @param classesToMock Array of class objects
 */
- (void)setUpWithMocks:(NSArray *)classesToMock;

@end
