//
//  TuneXCTestCase.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 5/11/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneXCTestCase.h"

@implementation TuneXCTestCase

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
}

- (void)setUpWithMocks:(NSArray *)classesToMock {
    [super setUp];
    RESET_EVERYTHING_OPTIONAL_MOCKING();
}

- (void)tearDown {
    REMOVE_MOCKS();
    
    [super tearDown];
}

@end
