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

#pragma mark - Text + Alignment

+ (NSDictionary *)getTitleFromDictionary:(NSDictionary *)dictionary {
    return [TuneInAppUtils getProperty:@"title" fromDictionary:dictionary];
}

+ (NSString *)getTextFromDictionary:(NSDictionary *)dictionary {
    id property = [TuneInAppUtils getProperty:@"text" fromDictionary:dictionary];
    return [TuneInAppUtils propertyIsNotEmpty:property] ? property : @"";
}

+ (NSString *)getAlignmentStringFromDictionary:(NSDictionary *)dictionary {
    return [TuneInAppUtils getProperty:@"alignment" fromDictionary:dictionary];
}

+ (NSTextAlignment)getTextAlignmentFromDictionary:(NSDictionary *)dictionary {
    NSTextAlignment alignment = NSTextAlignmentLeft;
    NSString *alignmentString = [TuneInAppUtils getAlignmentStringFromDictionary:dictionary];
    
    if ([TuneInAppUtils propertyIsNotEmpty:alignmentString]) {
        if ([alignmentString isEqualToString:@"left"]) {
            alignment = NSTextAlignmentLeft;
        } else if ([alignmentString isEqualToString:@"center"]) {
            alignment = NSTextAlignmentCenter;
        } else if ([alignmentString isEqualToString:@"right"]) {
            alignment = NSTextAlignmentRight;
        }
    }
    
    return alignment;
}

+ (NSTextAlignment)getNSTextAlignmentFromDictionary:(NSDictionary *)dictionary {
    NSTextAlignment alignment = NSTextAlignmentCenter;
    NSString *textAlignmentString = dictionary[@"alignment"];
    
    if ([TuneInAppUtils propertyIsNotEmpty:textAlignmentString]) {
        if ([textAlignmentString isEqualToString:@"left"]) {
            alignment = NSTextAlignmentLeft;
        } else if ([textAlignmentString isEqualToString:@"right"]) {
            alignment = NSTextAlignmentRight;
        }
    }
    return alignment;
}

#pragma mark - Colors

+ (TuneMessageCloseButtonColor)getMessageCloseButtonColorFromDictionary:(NSDictionary *)dictionary withDefaultColor:(TuneMessageCloseButtonColor)defaultColor {
    NSString *closeButtonColorString = dictionary[@"closeButtonColor"];
    TuneMessageCloseButtonColor color = defaultColor;
    
    if ( (closeButtonColorString) && ([closeButtonColorString length] > 0) ) {
        if ([closeButtonColorString isEqualToString:@"TunePopUpMessageCloseButtonColorRed"]) {
            color = TunePopUpMessageCloseButtonColorRed;
        } else if ([closeButtonColorString isEqualToString:@"TunePopUpMessageCloseButtonColorBlack"]) {
            color = TunePopUpMessageCloseButtonColorBlack;
        } else if ([closeButtonColorString isEqualToString:@"TuneSlideInMessageCloseButtonColorWhite"]) {
            color = TuneSlideInMessageCloseButtonColorWhite;
        } else if ([closeButtonColorString isEqualToString:@"TuneSlideInMessageCloseButtonColorBlack"]) {
            color = TuneSlideInMessageCloseButtonColorBlack;
        }
    }
    
    return color;
}

+ (UIColor *)getButtonColorFromDictionary:(NSDictionary *)dictionary {
    id property = [TuneInAppUtils getProperty:@"buttonColor" fromDictionary:dictionary];
    return [TuneInAppUtils propertyIsNotEmpty:property] ? [TuneInAppUtils colorWithString:property] : nil;
}

+ (UIColor *)getTextColorFromDictionary:(NSDictionary *)dictionary {
    return [TuneInAppUtils colorWithString:[TuneInAppUtils getProperty:@"textColor" fromDictionary:dictionary]];
}

+ (UIColor *)buildUIColorFromProperty:(NSString *)colorString {
    UIColor *backgroundColor = nil;
    if ( (colorString) && ([colorString length] > 0) ) {
        backgroundColor = [TuneInAppUtils colorWithString:colorString];
    }
    return backgroundColor;
}

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

+ (CGFloat)colorComponentFrom:(NSString *) string start:(NSUInteger) start length:(NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

#pragma mark - Fonts

+ (UIFont *)getFontFromDictionary:(NSDictionary *)dictionary withDefault:(UIFont *)defaultFont {
    NSString *fontName = nil;
    UIFont *font = nil;
    
    if ([TuneInAppUtils propertyIsNotEmpty:[TuneInAppUtils getProperty:@"weight" fromDictionary:dictionary]]) {
        NSString *weight = [TuneInAppUtils getProperty:@"weight" fromDictionary:dictionary];
        if ([weight isEqualToString:@"plain"]) {
            fontName = @"HelveticaNeue-Medium";
        } else if ([weight isEqualToString:@"bold"]) {
            fontName = @"HelveticaNeue-Light";
        }
    }
    
    if ([TuneInAppUtils propertyIsNotEmpty:[TuneInAppUtils getProperty:@"fontName" fromDictionary:dictionary]]) {
        fontName = [TuneInAppUtils getProperty:@"fontName" fromDictionary:dictionary];
    } else {
        fontName = defaultFont.fontName;
    }
    
    // Try to build the UIFont
    @try {
        font = [UIFont fontWithName:fontName size:[TuneInAppUtils getFontSizeFromDictionary:dictionary withDefaultSize:defaultFont.pointSize]];
    } @catch (NSException *exception) {
        font = defaultFont;
    }
    
    return font;
}

+ (CGFloat)getFontSizeFromDictionary:(NSDictionary *)dictionary withDefaultSize:(CGFloat)defaultSize {
    id property = [TuneInAppUtils getProperty:@"size" fromDictionary:dictionary];
    return [TuneInAppUtils propertyIsNotEmpty:property] ? [TuneInAppUtils getNumberValue:property].floatValue : defaultSize;
}

// Note: if we can't find the size or weight we'll use the defaultFont
// If both size and weight are missing we'll return nil
+ (UIFont *)buildFontFromDictionary:(NSDictionary *)dictionary andDefaultFont:(UIFont *)defaultFont {
    UIFont *font = defaultFont;
    CGFloat fontSize = font.pointSize;
    
    if ([TuneInAppUtils propertyIsNotEmpty:dictionary[@"size"]]) {
        NSNumber *fontSizeOverride = [TuneInAppUtils getNumberValue:dictionary[@"size"]];
        fontSize = (int)roundf([fontSizeOverride intValue]);
    }
    
    NSString *fontName = dictionary[@"fontName"];
    
    NSString *fontWeightString = dictionary[@"weight"];
    if ([fontWeightString length] == 0) {
        fontWeightString = @"plain";
    }
    
    if ( (fontName) && ([fontName length] > 0) ) {
        @try {
            UIFont *overrideFont = [UIFont fontWithName:fontName size:fontSize];
            if (overrideFont) {
                return overrideFont;
            }
        } @catch (NSException *exception) {
            // Nothing, we'll just use the default font.
        }
    } else if ([fontWeightString isEqualToString:@"bold"]) {
        return [UIFont boldSystemFontOfSize:fontSize];
    } else if ([fontWeightString isEqualToString:@"plain"]) {
        return [UIFont systemFontOfSize:fontSize];
    }
    
    return font;
}

+ (UIFont *)isBoldFont:(UIFont *)font {
    //First get the name of the font (unnecessary, but used for clarity)
    NSString *fontName = font.fontName;
    
    //Then append "-Bold" to it.
    NSString *boldFontName = [fontName stringByAppendingString:@"-Bold"];
    
    //Then see if it returns a valid font
    UIFont *boldFont = [UIFont fontWithName:boldFontName size:font.pointSize];
    
    //If it's valid, return it
    if(boldFont) return boldFont;
    
    //Seems like in some cases, you have to append "-BoldMT"
    boldFontName = [fontName stringByAppendingString:@"-BoldMT"];
    boldFont = [UIFont fontWithName:boldFontName size:font.pointSize];
    
    //Here you can check if it was successful, if it wasn't, then you can throw an exception or something.
    return boldFont;
}

#pragma mark - Image Assets

+ (NSString *)getScreenAppropriateImageKey {
    float scale = [TuneInAppUtils screenScale];
    if (scale == 1.0f) {
        return @"src";
    } else if (scale == 2.0f) {
        return @"src2x";
    } else if (scale == 3.0f) {
        return @"src3x";
    }
    return @"src";
}

+ (UIImage *)getScreenAppropriateImageFromDictionary:(NSDictionary *)imageDictionary {
    NSString *imageName = [TuneInAppUtils buildImageFilenameFromURL:[self getScreenAppropriateValueFromDictionary:imageDictionary]];
    return [TuneFileManager loadImageFromDiskNamed:imageName];
}

+ (NSString *)getScreenAppropriateValueFromDictionary:(NSDictionary *)dictionary {
    NSString *imageKey = [self getScreenAppropriateImageKey];
    return dictionary[imageKey];
}

+ (UIImage *)getBackgroundImageFromDictionary:(NSDictionary *)dictionary {
    UIImage *image;
    if ([TuneInAppUtils propertyIsNotEmpty:dictionary[@"backgroundImage"]]) {
        NSDictionary *imageDictionary = dictionary[@"backgroundImage"];
        @try {
            image = [TuneInAppUtils getScreenAppropriateImageFromDictionary:imageDictionary];
        } @catch (NSException *exception) {
            // empty
        }
    }
    
    return image;
}

+ (NSString *)buildImageFilenameFromURL:(NSString *)url {
    return [NSString stringWithFormat:@"%@.%@", [TuneUtils hashMd5:url], [url pathExtension]];
}

+ (void)downloadImages:(NSMutableDictionary *)images withDispatchGroup:(dispatch_group_t)group {
    for (NSString *imageUrl in images.allKeys) {
        __block NSString *_imageFileName = [TuneInAppUtils buildImageFilenameFromURL:imageUrl];
        __block NSString *_imageURL = imageUrl;
        
        dispatch_group_async(group, [[TuneManager currentManager] concurrentQueue], ^{
            if ([TuneFileManager loadImageFromDiskNamed:_imageFileName]) {
                // we already have the image, no need to download
                [images setValue:@YES forKey:_imageURL];
            } else {
                // this method should be done synchronously and only used inside an asycnhronous call
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_imageURL]];
                if (imageData != nil) {
                    BOOL result = [TuneFileManager saveImageData:imageData toDiskWithName:_imageFileName];
                    [images setValue:@(result) forKey:_imageURL];
                } else {
                    ErrorLog(@"Failed to download image from: %@", _imageURL);
                    [images setValue:@(NO) forKey:_imageURL];
                }
            }
        });
    }
}

@end
