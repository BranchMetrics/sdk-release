//
//  TuneInAppFactoryUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@class TuneMessageAction;

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

#pragma mark - Colors

+ (UIColor *)colorWithString:(NSString *)hexString;

+ (UIColor *)colorWithString:(NSString *)hexString withDefault:(NSString *)defaultHexString;

+ (UIColor *)colorWithString:(NSString *)hexString withDefault:(NSString *)defaultHexString orJustReturnNilOnError:(BOOL)justReturnNilOnError;

+ (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length;

@end
