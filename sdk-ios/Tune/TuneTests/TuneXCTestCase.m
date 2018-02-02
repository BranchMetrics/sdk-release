//
//  TuneXCTestCase.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 5/11/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneXCTestCase.h"
#import "TuneAnalyticsManager+Testing.h"
#import "TunePlaylistManager+Testing.h"

@implementation TuneXCTestCase

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
}

- (void)setUpWithMocks:(NSArray *)classesToMock {
    [super setUp];
    
    BOOL shouldMockPM = [classesToMock containsObject:[TunePlaylistManager class]];
    BOOL shouldMockAM = [classesToMock containsObject:[TuneAnalyticsManager class]];
    
    RESET_EVERYTHING_OPTIONAL_MOCKING(shouldMockPM, shouldMockAM);
}

- (void)tearDown {
    REMOVE_MOCKS();
    
    [super tearDown];
}

@end
