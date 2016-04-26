//
//  TuneBlankAppDelegate.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneBlankAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) int didRegisterCount;
@property (nonatomic) int didReceiveCount;
@property (nonatomic) int didContinueCount;
@property (nonatomic) int handleActionCount;
@property (nonatomic) int openURLCount;
@property (nonatomic) int deepActionCount;
@property (nonatomic) NSString *deepActionValue;

@end
