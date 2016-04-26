//
//  UIViewController+NameTag.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/21/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIViewController (NameTag)

/**
 * This Category provides the NameTag property on UIViewController. This property allows you to add a more specific, useful name to the analytics that are auto collected around this view controller.
 *
 * Example: PopFeedViewController
 *
 * - (id)initWithCoder:(NSCoder *)aDecoder {
 *     self = [super initWithCoder:aDecoder];
 *
 *     if (self) {
 *         self.nameTag = @"Popular News Feed";
 *     }
 *     return self;
 * }
 */
@property (nonatomic, strong) NSString *nameTag;

@end
