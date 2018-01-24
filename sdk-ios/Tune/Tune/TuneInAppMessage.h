//
//  TuneInAppMessage.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TuneCampaign.h"
#import "TuneInAppMessageAction.h"
#import "TuneInAppMessageConstants.h"
#import "TuneMessageDisplayFrequency.h"
#import "TunePointerSet.h"

#if TARGET_OS_IOS
@import WebKit;
#endif

enum TuneMessageFrequencyScope {
    TuneMessageFrequencyScopeInstall = 1,
    TuneMessageFrequencyScopeSession,
    TuneMessageFrequencyScopeDays,
    TuneMessageFrequencyScopeEvents
};
typedef enum TuneMessageFrequencyScope TuneMessageFrequencyScope;

#if TARGET_OS_IOS
@interface TuneInAppMessage : NSObject <WKNavigationDelegate>
#else
@interface TuneInAppMessage : NSObject
#endif

@property (nonatomic, copy, readwrite) NSDictionary *messageDictionary;
@property (nonatomic, copy, readwrite) NSString *messageID;
@property (nonatomic, copy, readwrite) NSString *campaignStepID;
@property (strong, nonatomic, readwrite) TuneCampaign *campaign;
@property (nonatomic, copy, readwrite) NSString *triggerEvent;

@property (strong, nonatomic, readwrite) NSDate *startDate;
@property (strong, nonatomic, readwrite) NSDate *endDate;
@property (nonatomic, readwrite) int limit;
@property (nonatomic, readwrite) TuneMessageFrequencyScope scope;
@property (nonatomic, readwrite) int lifetimeMaximum;

@property (nonatomic, copy, readwrite) NSString *html;
@property (nonatomic, strong, readwrite) NSDictionary<NSString *, TuneInAppMessageAction *> *tuneActions;

#if TARGET_OS_IOS
@property (nonatomic, strong, readwrite) WKWebView *webView;
#endif
@property (nonatomic, readwrite) BOOL webViewLoaded;
@property (nonatomic, readwrite) TuneMessageTransition transitionType;

@property (nonatomic, readwrite) BOOL visible;
@property (strong, nonatomic, readwrite) TunePointerSet *visibleViews;

+ (TuneInAppMessage *)buildMessageFromMessageDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary;
- (void)display;
- (void)dismiss;

- (BOOL)shouldDisplayBasedOnFrequencyModel:(TuneMessageDisplayFrequency *)frequencyModel;

@end
