//
//  TuneBaseInAppMessageView.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneCampaign.h"
#import "TuneInAppMessageConstants.h"

#if IDE_XCODE_8_OR_HIGHER
#import <QuartzCore/QuartzCore.h>
@interface TuneBaseInAppMessageView : UIView <CAAnimationDelegate> {
#else
@interface TuneBaseInAppMessageView : UIView {
#endif
    NSString *_messageID;
    NSString *_campaignStepID;
    
    TuneCampaign *_campaign;
    
    // Timestamp of when the message was shown
    NSDate *_messageShownTimestamp;
}

@property (nonatomic) BOOL needToLayoutView;
@property (nonatomic) BOOL needToAddToUIWindow;
@property (nonatomic) TuneMessageDeviceOrientation landscapeLeftType;
@property (nonatomic) TuneMessageDeviceOrientation landscapeRightType;
@property (nonatomic) TuneMessageDeviceOrientation portraitType;
@property (nonatomic) TuneMessageDeviceOrientation portraitUpsideDownType;

- (void)dismissAndWait;
- (void)dismiss;

- (void)setMessageID:(NSString *)messageID;
- (void)setCampaignStepID:(NSString *)campaignStepID;
- (void)setCampaign:(TuneCampaign *)campaign;
- (void)recordMessageShown;
- (void)recordMessageDismissedWithAction:(NSString *)dissmissedAction;

@end
