//
//  TuneStringUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/27/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneStringUtils.h"
#import "TuneDateUtils.h"
#import "TuneDeviceDetails.h"

static NSMutableCharacterSet *tune_urlEncodingAllowedCharacterSet;
static NSString *tune_ignoredCharacters = @"!*'\"();:@&=+$,/?%#[] \n";

@implementation TuneStringUtils

+ (void)initialize {
    tune_urlEncodingAllowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [tune_urlEncodingAllowedCharacterSet removeCharactersInString:tune_ignoredCharacters];
}

+ (NSString *)scrubNameForMongo:(NSString *)name {
    NSString *trimmedExperimentName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *noPeriods = [trimmedExperimentName stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *noDollars = [noPeriods stringByReplacingOccurrencesOfString:@"$" withString:@"_"];
    
    return noDollars;
}

+ (BOOL)isBlank:(NSString *)string {
    return string == nil ||
           [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0;
}

+ (NSString *)urlEncodeString:(NSString *)unEncodedString {
    if (unEncodedString == nil) return @"";

    NSString *encodedString = nil;
    
    if ([TuneDeviceDetails appIsRunningIniOS7OrAfter]) {
        encodedString = [unEncodedString stringByAddingPercentEncodingWithAllowedCharacters:tune_urlEncodingAllowedCharacterSet];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Ref: http://stackoverflow.com/questions/8086584/objective-c-url-encoding
        encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                              (__bridge CFStringRef)unEncodedString,
                                                                                              NULL,
                                                                                              (CFStringRef)tune_ignoredCharacters,
                                                                                              kCFStringEncodingUTF8));
#pragma clang diagnostic pop
    }
    
    return encodedString;
}

+ (NSString *)removePercentEncoding:(NSString *)string {
    if (string == nil) return nil;
    
    NSString *output = nil;
    if ([TuneDeviceDetails appIsRunningIniOS7OrAfter]) {
        output = [string stringByRemovingPercentEncoding];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        output = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    }
    
    return output;
}

+ (NSString *)addPercentEncoding:(NSString *)string {
    if (string == nil) return nil;
    
    NSString *output = nil;
    if ([TuneDeviceDetails appIsRunningIniOS7OrAfter]) {
        output = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        output = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    }
    
    return output;
}

+ (NSString *)humanizeString:(NSString *)string {
    if (!string) { return @""; }
    
    // We only want what's before the ::
    NSArray *stringParts = [string componentsSeparatedByString:@"::"];
    string = stringParts[0];
    
    // De-CamelCase the default and remove the 'Controller' from the end.
    NSRegularExpression *regexpCaps = [NSRegularExpression regularExpressionWithPattern:@"([[A-Z][0-9]]*)([A-Z])([a-z])" options:0 error:NULL];
    string = [regexpCaps stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$2$3"];
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"([[a-z][0-9]])([A-Z])" options:0 error:NULL];
    string = [regexp stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$1 $2"];
    string = [string stringByReplacingOccurrencesOfString:@" Controller" withString:@""];
    return string;
}

+ (NSString *)fromCamelCaseToUnderscore:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.caseSensitive = YES;
    
    NSString *builder = [NSString string];
    NSString *buffer = nil;
    NSUInteger lastScanLocation = 0;
    
    while (![scanner isAtEnd]) {
        if ([scanner scanCharactersFromSet:[[NSCharacterSet uppercaseLetterCharacterSet] invertedSet] intoString:&buffer]) {
            builder = [builder stringByAppendingString:buffer];
            
            if ([scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&buffer]) {
                
                builder = [builder stringByAppendingString:@"_"];
                builder = [builder stringByAppendingString:[buffer lowercaseString]];
            }
        }
        
        // If the scanner location has not moved, there's a problem somewhere.
        if (lastScanLocation == scanner.scanLocation) return string;
        lastScanLocation = scanner.scanLocation;
    }
    
    return builder;
}

+ (NSString *)stripSpecialCharacters:(NSString *)string {
    // Strings all non-alphanumeric characters (save the dash and underscore) from a given string
    if (string == nil) return nil;
    
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"_-abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01123456789"] invertedSet];
    NSString *resultString = [[string componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
    
    return resultString;
}

+ (NSString *)stringFromHexString:(NSString *)hexString {
    // The hex codes should all be two characters.
    if (([hexString length] % 2) != 0)
        return nil;
    
    NSMutableString *string = [NSMutableString string];
    for (NSInteger i = 0; i < [hexString length]; i += 2) {
        NSString *hex = [hexString substringWithRange:NSMakeRange(i, 2)];
        unsigned hexComponent;
        [[NSScanner scannerWithString: hex] scanHexInt: &hexComponent];
        [string appendFormat:@"%c", (char)hexComponent];
    }
    
    return [NSString stringWithString:string];
}

@end
