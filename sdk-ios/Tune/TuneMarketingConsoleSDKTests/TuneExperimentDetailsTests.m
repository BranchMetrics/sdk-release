//
//  TuneExperimentDetailsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 6/6/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneXCTestCase.h"
#import "TuneExperimentDetails+Internal.h"

@interface TuneExperimentDetailsTests : TuneXCTestCase

@end

@implementation TuneExperimentDetailsTests

- (void)testToDictionary {
    NSDictionary *experiment = @{@"current_variation":@{@"id":@"foobar", @"name":@"Variation X"},
                                 @"id":@(789),
                                 @"name":@"Testing a Message",
                                 @"type":@"in_app"
                                 };
    
    TuneExperimentDetails *expDetails = [[TuneExperimentDetails alloc] initWithDictionary:experiment];
    
    NSDictionary *dictOutput = [expDetails toDictionary];
    
    NSDictionary *dictExpected = @{@"current_variation":@{@"id":@"foobar", @"letter":[NSNull null], @"name":@"Variation X"},
                                   @"id":@(789),
                                   @"name":@"Testing a Message",
                                   @"type":@"in_app"
                                   };
    
    XCTAssertEqualObjects(dictExpected, dictOutput);
    
    experiment = @{@"current_variation":@{@"id":@"foobar", @"letter":@"X", @"name":@"Variation X"},
                   @"id":@(789),
                   @"name":@"Testing a Message",
                   @"type":@"in_app"
                   };
    
    expDetails = [[TuneExperimentDetails alloc] initWithDictionary:experiment];
    
    dictOutput = [expDetails toDictionary];
    
    dictExpected = @{@"current_variation":@{@"id":@"foobar", @"letter":@"X", @"name":@"Variation X"},
                     @"id":@(789),
                     @"name":@"Testing a Message",
                     @"type":@"in_app"
                     };
    
    XCTAssertEqualObjects(dictExpected, dictOutput);
}


@end
