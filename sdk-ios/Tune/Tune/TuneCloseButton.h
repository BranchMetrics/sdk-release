//
//  TuneCloseButton.h
//  Tune
//
//  Created by John Gu on 12/6/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneBaseInAppMessageView.h"

@class TuneBaseInAppMessageView;

@interface TuneCloseButton : UIImageView

@property TuneBaseInAppMessageView *parentMessageView;

@end
