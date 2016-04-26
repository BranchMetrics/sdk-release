//
//  TuneInAppFactoryUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"
#import "TuneMessageAction.h"

@interface TuneInAppUtils : NSObject

#pragma mark - Random Helpers

+ (float)screenScale;

+ (BOOL)propertyIsNotEmpty:(id)property;

+ (NSNumber *)getNumberValue:(NSObject *)property;

+ (TuneMessageLocationType)getLocationTypeByString:(NSString *)messageLocationTypeString;

#pragma mark - Reading Values From Dictionary

+ (TuneMessageBackgroundMaskType)getMessageBackgroundMaskTypeFromDictionary:(NSDictionary *)dictionary;

+ (NSNumber *)getMessageDurationFromDictionary:(NSDictionary *)dictionary;

+ (TuneMessageTransition)getTransitionFromDictionary:(NSDictionary *)dictionary;

#pragma mark - Actions

+ (TuneMessageAction *)getActionFromDictionary:(NSDictionary *)dictionary;

+ (TuneMessageAction *)getDeviceAppropriateActionFromDictionary:(NSDictionary *)dictionary;

+ (TuneMessageAction *)getTuneMessageActionFromDictionary:(NSDictionary *)dictionary;

#pragma mark - Images

+ (NSString *)getScreenAppropriateValueFromDictionary:(NSDictionary *)dictionary;

+ (UIImage *)getBackgroundImageFromDictionary:(NSDictionary *)dictionary;

+ (UIImage *)getScreenAppropriateImageFromDictionary:(NSDictionary *)imageDictionary;

#pragma mark - Text + Alignment

+ (id)getTitleFromDictionary:(NSDictionary *)dictionary;

+ (NSString *)getTextFromDictionary:(NSDictionary *)dictionary;

+ (NSString *)getAlignmentStringFromDictionary:(NSDictionary *)dictionary;

+ (NSTextAlignment)getTextAlignmentFromDictionary:(NSDictionary *)dictionary;

+ (NSTextAlignment)getNSTextAlignmentFromDictionary:(NSDictionary *)dictionary;

#pragma mark - Colors

+ (TuneMessageCloseButtonColor)getMessageCloseButtonColorFromDictionary:(NSDictionary *)dictionary withDefaultColor:(TuneMessageCloseButtonColor)defaultColor;

+ (UIColor *)getButtonColorFromDictionary:(NSDictionary *)dictionary;

+ (UIColor *)getTextColorFromDictionary:(NSDictionary *)dictionary;

+ (UIColor *)buildUIColorFromProperty:(NSString *)colorString;

+ (UIColor *)colorWithString:(NSString *)hexString;

+ (UIColor *)colorWithString:(NSString *)hexString withDefault:(NSString *)defaultHexString;

+ (UIColor *)colorWithString:(NSString *)hexString withDefault:(NSString *)defaultHexString orJustReturnNilOnError:(BOOL)justReturnNilOnError;

+ (CGFloat)colorComponentFrom:(NSString *) string start:(NSUInteger) start length:(NSUInteger) length;

#pragma mark - Fonts

+ (UIFont *)getFontFromDictionary:(NSDictionary *)dictionary withDefault:(UIFont *)defaultFont;

+ (CGFloat)getFontSizeFromDictionary:(NSDictionary *)dictionary withDefaultSize:(CGFloat)defaultSize;

+ (UIFont *)buildFontFromDictionary:(NSDictionary *)dictionary andDefaultFont:(UIFont *)defaultFont;

+ (UIFont *)isBoldFont:(UIFont *)font;

#pragma mark - Downloading Assets

+ (void)downloadImages:(NSMutableDictionary *)images withDispatchGroup:(dispatch_group_t)group;

@end
