//
//  TuneDeeplink.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneCampaign.h"
#import "TuneMessageAction.h"

@interface TuneDeeplink : NSObject {
    NSMutableDictionary *_parameterDictionary;
    BOOL _foundCampaign;
    BOOL _foundAction;
}

@property (strong, nonatomic) TuneMessageAction *action;
@property (strong, nonatomic) TuneCampaign *campaign;
// Event Parameters will contain category
@property (nonatomic, strong) NSMutableDictionary *eventParameters;
@property (nonatomic, copy) NSString *eventType;
@property (strong, nonatomic) NSURL *url;

- (id)initWithNSURL:(NSURL *)url;
+ (void)processDeeplinkURL:(NSURL *)url;

@end
