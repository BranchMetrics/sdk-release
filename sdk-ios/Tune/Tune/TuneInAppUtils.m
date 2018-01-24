//
//  TuneInAppFactoryUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppUtils.h"
#import "TuneFileUtils.h"
#import "TuneFileManager.h"
#import "TuneManager.h"
#import "TuneMessageAction.h"
#import "TuneUtils.h"

@implementation TuneInAppUtils

#pragma mark - Random Helpers

+ (float)screenScale {
    return [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0;
}

+ (BOOL)propertyIsNotEmpty:(id)property {
    BOOL notEmpty = NO;
    
    @try {
        notEmpty = nil != property && (![property isKindOfClass:[NSString class]] || [property length] > 0);
    } @catch (NSException *exception) {
        // empty
    } @finally {
        return notEmpty;
    }
}

+ (NSNumber *)getNumberValue:(NSObject *)property {
    NSNumber *foundNumber = nil;
    
    @try {
        foundNumber = [[NSDecimalNumber alloc] initWithFloat:[(NSString *)property floatValue]];
    } @catch (NSException *exception) {
        // can't convert string
        // empty
    } @finally {
        return foundNumber;
    }
}

+ (TuneMessageLocationType)getLocationTypeByString:(NSString *)messageLocationTypeString {
    TuneMessageLocationType messageLocationType = TuneMessageLocationCentered;
    
    if ([messageLocationTypeString isEqualToString:@"TuneMessageLocationTop"]) {
        messageLocationType = TuneMessageLocationTop;
    } else if ([messageLocationTypeString isEqualToString:@"TuneMessageLocationBottom"]) {
        messageLocationType = TuneMessageLocationBottom;
    } else if ([messageLocationTypeString isEqualToString:@"TuneMessageLocationCentered"]) {
        messageLocationType = TuneMessageLocationCentered;
    } else if ([messageLocationTypeString isEqualToString:@"TuneMessageLocationCustom"]) {
        messageLocationType = TuneMessageLocationCustom;
    }
    
    return messageLocationType;
}

// Wut. (disapproval)
+ (id)getProperty:(NSString *)property fromDictionary:(NSDictionary *)dictionary {
    return dictionary[property];
}

#pragma mark - Reading Values from Dictionary

+ (TuneMessageBackgroundMaskType)getMessageBackgroundMaskTypeFromDictionary:(NSDictionary *)dictionary {
    NSString *backgroundMaskTypeString = dictionary[@"backgroundMaskType"];
    TuneMessageBackgroundMaskType maskType = TuneMessageBackgroundMaskTypeLight;
    if ( (backgroundMaskTypeString) && ([backgroundMaskTypeString length] > 0) ) {
        if ([backgroundMaskTypeString isEqualToString:@"TuneMessageBackgroundMaskTypeLight"]) {
            maskType = TuneMessageBackgroundMaskTypeLight;
        } else if ([backgroundMaskTypeString isEqualToString:@"TuneMessageBackgroundMaskTypeDark"]) {
            maskType = TuneMessageBackgroundMaskTypeDark;
        } else if ([backgroundMaskTypeString isEqualToString:@"TuneMessageBackgroundMaskTypeBlur"]) {
            // NOTE: This isn't supported yet.
        } else if ([backgroundMaskTypeString isEqualToString:@"TuneMessageBackgroundMaskTypeNone"]) {
            maskType = TuneMessageBackgroundMaskTypeNone;
        }
    }
    return maskType;
}

+ (NSNumber *)getMessageDurationFromDictionary:(NSDictionary *)dictionary {
    @try {
        if ([TuneInAppUtils propertyIsNotEmpty:dictionary[@"duration"]]) {
            NSNumber *duration = [TuneInAppUtils getNumberValue:dictionary[@"duration"]];
            return [[NSDecimalNumber alloc] initWithFloat:[duration floatValue]];
        }
    } @catch (NSException *exception) {
        // nothing
    }
    
    return [[NSDecimalNumber alloc] initWithInt:0];
}

+ (TuneMessageTransition)getTransitionFromDictionary:(NSDictionary *)dictionary {
    NSString *transitionString = dictionary[@"transition"];
    TuneMessageTransition transition = TuneMessageTransitionNone;
    
    if ( (transitionString) && ([transitionString length] > 0) ) {
        if ([transitionString isEqualToString:@"TuneMessageTransitionFromTop"]) {
            transition = TuneMessageTransitionFromTop;
        } else if ([transitionString isEqualToString:@"TuneMessageTransitionFromBottom"]) {
            transition = TuneMessageTransitionFromBottom;
        } else if ([transitionString isEqualToString:@"TuneMessageTransitionFromLeft"]) {
            transition = TuneMessageTransitionFromLeft;
        } else if ([transitionString isEqualToString:@"TuneMessageTransitionFromRight"]) {
            transition = TuneMessageTransitionFromRight;
        } else if ([transitionString isEqualToString:@"TuneMessageTransitionFadeIn"]) {
            transition = TuneMessageTransitionFadeIn;
        } else if ([transitionString isEqualToString:@"TuneMessageTransitionNone"]) {
            transition = TuneMessageTransitionNone;
        }
    }
    
    return transition;
}

#pragma mark - Actions

+ (TuneMessageAction *)getActionFromDictionary:(NSDictionary *)dictionary {
    TuneMessageAction *action = nil;
    
    if (dictionary) {
        NSString *url = dictionary[@"url"];
        // TODO: They are still called 'powerHook's in the playlist, when the actually are deep actions.
        //       Not changing this yet since we haven't updated the playlist schema yet.
        NSString *deepActionName = dictionary[@"powerHookName"];
        NSDictionary *deepActionData = dictionary[@"powerHookParams"];
        
        action = [TuneMessageAction new];
        
        if ( ([url length] > 0) && (url) ) {
            // Next action is a url
            action.url = url;
        } else if ( ([deepActionName length] > 0) && (deepActionName)) {
            // Next action is a powerhook
            action.deepActionName = deepActionName;
            action.deepActionData = deepActionData;
        }
    }
    
    return action;
}

+ (TuneMessageAction *)getDeviceAppropriateActionFromDictionary:(NSDictionary *)dictionary {
    TuneMessageAction *action = nil;
    
    if (dictionary) {
        NSString *deviceAppropriateActionKey;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            deviceAppropriateActionKey = @"phone";
        } else {
            deviceAppropriateActionKey = @"tablet";
        }
        action = [TuneInAppUtils getActionFromDictionary:dictionary[deviceAppropriateActionKey]];
    }
    
    return action;
}

+ (TuneMessageAction *)getTuneMessageActionFromDictionary:(NSDictionary *)dictionary {
    return [TuneInAppUtils getDeviceAppropriateActionFromDictionary:dictionary[@"actions"]];
}

#pragma mark - Colors

// NOTE: use this ONLY in cases where you are manually setting the hex string or it's ok to get nil back
+ (UIColor *)colorWithString:(NSString *)hexString {
    return [TuneInAppUtils colorWithString:hexString withDefault:@"" orJustReturnNilOnError:YES];
}

// NOTE: use this when you're parsing the hexString from JSON and specify the default to fallback to if there's an error.
+ (UIColor *)colorWithString:(NSString *)hexString withDefault:(NSString *)defaultHexString {
    return [TuneInAppUtils colorWithString:hexString withDefault:defaultHexString orJustReturnNilOnError:NO];
}

+ (UIColor *)colorWithString:(NSString *)hexString withDefault:(NSString *)defaultHexString orJustReturnNilOnError:(BOOL)justReturnNilOnError {
    CGFloat alpha, red, blue, green;
    @try {
        NSString *colorString;
        if (hexString) {
            colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
        } else {
            if (justReturnNilOnError) {
                return nil;
            } else {
                colorString = [[defaultHexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
            }
        }
        
        switch ([colorString length]) {
            case 3: // #RGB
                alpha = 1.0f;
                red   = [TuneInAppUtils colorComponentFrom:colorString start:0 length:1];
                green = [TuneInAppUtils colorComponentFrom:colorString start:1 length:1];
                blue  = [TuneInAppUtils colorComponentFrom:colorString start:2 length:1];
                break;
            case 4: // #ARGB
                alpha = [TuneInAppUtils colorComponentFrom:colorString start:0 length:1];
                red   = [TuneInAppUtils colorComponentFrom:colorString start:1 length:1];
                green = [TuneInAppUtils colorComponentFrom:colorString start:2 length:1];
                blue  = [TuneInAppUtils colorComponentFrom:colorString start:3 length:1];
                break;
            case 6: // #RRGGBB
                alpha = 1.0f;
                red   = [TuneInAppUtils colorComponentFrom:colorString start:0 length:2];
                green = [TuneInAppUtils colorComponentFrom:colorString start:2 length:2];
                blue  = [TuneInAppUtils colorComponentFrom:colorString start:4 length:2];
                break;
            case 8: // #AARRGGBB
                alpha = [TuneInAppUtils colorComponentFrom:colorString start:0 length:2];
                red   = [TuneInAppUtils colorComponentFrom:colorString start:2 length:2];
                green = [TuneInAppUtils colorComponentFrom:colorString start:4 length:2];
                blue  = [TuneInAppUtils colorComponentFrom:colorString start:6 length:2];
                break;
            default:
                [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
                break;
        }
    } @catch (NSException *exception) {
        if (justReturnNilOnError) {
            return nil;
        } else {
            // Nothing to do here
        }
    }
    
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

@end
