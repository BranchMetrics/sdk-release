//
//  TuneAnalyticsVariable.m
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/28/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneAnalyticsVariable.h"

#import "TuneConfiguration.h"
#import "TuneManager.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDateUtils.h"
#import "TuneLocation.h"
#import "TunePIIUtils.h"
#import "TuneUtils.h"


@implementation TuneAnalyticsVariable

@synthesize name, value, type, hashType, shouldAutoHash, didHaveValueManuallySet;

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value {
    
    return [self analyticsVariableWithName:name value:value type:TuneAnalyticsVariableStringType];
}

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type {
    
    return [[[self class] alloc] initWithName:name value:value type:type hashType:TuneAnalyticsVariableHashNone shouldAutoHash:NO];
}

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type
                                 hashType:(TuneAnalyticsVariableHashType)hashType {
    
    return [[[self class] alloc] initWithName:name value:value type:type hashType:hashType shouldAutoHash:NO];
}

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type
                                 shouldAutoHash:(BOOL)shouldAutoHash {
    
    return [[[self class] alloc] initWithName:name value:value type:type hashType:TuneAnalyticsVariableHashNone shouldAutoHash:shouldAutoHash];
}

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type
                                 hashType:(TuneAnalyticsVariableHashType)hashType
                               shouldAutoHash:(BOOL)shouldAutoHash {
    
    return [[[self class] alloc] initWithName:name value:value type:type hashType:hashType shouldAutoHash:shouldAutoHash];
}

- (instancetype)initWithName:(NSString *)newName
                       value:(id)newValue
                        type:(TuneAnalyticsVariableDataType)newType
                    hashType:(TuneAnalyticsVariableHashType)newHashType
                  shouldAutoHash:(BOOL)newShouldAutoHash{
    
    self = [self init];
    
    if (self) {
        self.name = newName;
        self.value = newValue;
        self.type = newType;
        self.hashType = newHashType;
        self.shouldAutoHash = newShouldAutoHash;
        self.didHaveValueManuallySet = NO;
    }
    
    return self;
}


+ (NSString *)convertDateToString:(NSDate *)date {
    return [[TuneDateUtils dateFormatterIso8601UTC] stringFromDate:date];
}

+ (NSString *)convertNumberToString:(NSNumber *)inputValue {
    return [inputValue stringValue];
}

+ (NSString *)convertTuneLocationToString:(TuneLocation *)location {
    if (location == nil) {
        return nil;
    }
    
    // We can assume that longitude and latitude exist because validateTuneLocation should be run before this.
    //   These are the only fields on the TuneLocation that we support.
    return [NSString stringWithFormat:@"%0.9f,%0.9f", [location.longitude doubleValue], [location.latitude doubleValue]];
}

+ (BOOL)validateTuneLocation:(TuneLocation *)location {
    return location == nil || (location.longitude != nil && location.latitude != nil);
}

+ (BOOL)validateVersion:(NSString *)value {
    if (value == nil) {
        return YES;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(0|[1-9]\\d*)(\\.(0|[1-9]\\d*)){0,2}(\\-.*)?$" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSRange matchRange = [regex rangeOfFirstMatchInString:value options:NSMatchingReportProgress range:NSMakeRange(0, value.length)];
    
    return matchRange.location != NSNotFound;
}

+ (NSString *)cleanVariableName:(NSString *)string {
    // Strips all non-alphanumeric characters (save the dash and underscore) from a given string
    if (string == nil) return nil;
    
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"_-abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01123456789"] invertedSet];
    NSString *resultString = [[string componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
    
    return resultString;
}

+ (BOOL) validateName:(NSString *)variableName {
    if (variableName != nil && ![variableName isEqualToString:@""]){
        NSString *prettyName = [TuneAnalyticsVariable cleanVariableName:variableName];
        
        if (![variableName isEqualToString:prettyName]) {
            WarnLog(@"The variable name '%@' had special characters in it and was automatically changed to '%@'.", variableName, prettyName);
        }
        
        if ([prettyName isEqualToString:@""]) {
            ErrorLog(@"Can not register/set a variable with name made of characters exclusively not in [a-zA-Z0-9_-].");
            return NO;
        }
        
        return YES;
    } else {
        ErrorLog(@"Attempted to use a variable with name of nil or empty string.");
        return NO;
    }
}

- (NSString *)convertValueToString {
    if (value == nil || [value isEqual:[NSNull null]]) {
        // The following methods should nil-safe, so this is just an extra precaution
        return value;
    }
    NSString *stringValue;
    switch (type) {
        case TuneAnalyticsVariableBooleanType:
            stringValue = [TuneAnalyticsVariable convertNumberToString:value];
            break;
        case TuneAnalyticsVariableDateTimeType:
            stringValue = [TuneAnalyticsVariable convertDateToString:value];
            break;
        case TuneAnalyticsVariableCoordinateType:
            stringValue = [TuneAnalyticsVariable convertTuneLocationToString:value];
            break;
        case TuneAnalyticsVariableNumberType:
            stringValue = [TuneAnalyticsVariable convertNumberToString:value];
            break;
        //This is for String, and Version types
        default:
            stringValue = value;
            break;
    }
    
    return stringValue;
}

- (NSDictionary *)toDictionary {
    // If the hashType is not none then we assume that it has already been hashed with that certain type
    if (hashType != TuneAnalyticsVariableHashNone) {
        return @{ @"name"  : [TuneUtils objectOrNull:name],
                  @"value" : [TuneUtils objectOrNull:[self convertValueToString]],
                  @"type"  : [TuneAnalyticsVariable dataTypeToString:type],
                  @"hash"  : [TuneAnalyticsVariable hashTypeToString:hashType] };
    } else {
        return [self toDictionaryWithHash:TuneAnalyticsVariableHashNone];
    }
}

- (NSDictionary *)toDictionaryWithHash:(TuneAnalyticsVariableHashType)hashWith {
    if (hashWith == TuneAnalyticsVariableHashNone) {
        return @{ @"name"  : [TuneUtils objectOrNull:name],
                  @"value" : [TuneUtils objectOrNull:[self convertValueToString]],
                  @"type"  : [TuneAnalyticsVariable dataTypeToString:type] };
    } else {
        NSString *stringValue = [self convertValueToString];
        switch (hashWith) {
            case TuneAnalyticsVariableHashMD5Type:
                stringValue = [TuneUtils hashMd5:stringValue];
                break;
            case TuneAnalyticsVariableHashSHA1Type:
                stringValue = [TuneUtils hashSha1:stringValue];
                break;
            case TuneAnalyticsVariableHashSHA256Type:
                stringValue = [TuneUtils hashSha256:stringValue];
                break;
            default:
                break;
        }
        return @{ @"name"  : [TuneUtils objectOrNull:name],
                  @"value" : [TuneUtils objectOrNull:stringValue],
                  @"type"  : [TuneAnalyticsVariable dataTypeToString:type],
                  @"hash"  : [TuneAnalyticsVariable hashTypeToString:hashWith] };
    }
}

- (NSArray *)toArrayOfDicts {
    BOOL hasPII = [TunePIIUtils check:[self convertValueToString] hasPIIWithPIIRegexFiltersArray:[[TuneManager currentManager].configuration PIIFiltersAsNSRegularExpressions]];
    if (shouldAutoHash || hasPII) {
        if (hasPII) {
            // TODO: If we have PII here do we really want to alert the sure as to what is being hashed exactly?
            WarnLog(@"Found PII for variable '%@', hashing: %@", self.name, [self convertValueToString]);
        }
        
        return @[ [self toDictionaryWithHash:TuneAnalyticsVariableHashMD5Type],
                  [self toDictionaryWithHash:TuneAnalyticsVariableHashSHA1Type],
                  [self toDictionaryWithHash:TuneAnalyticsVariableHashSHA256Type]
                ];
    } else {
        return @[ [self toDictionary] ];
    }
}

+ (NSString *)dataTypeToString:(TuneAnalyticsVariableDataType)dataType {
    NSString *result = TUNE_DATA_TYPE_STRING;
    
    switch(dataType) {
        case TuneAnalyticsVariableStringType:
            result = TUNE_DATA_TYPE_STRING;
            break;
        case TuneAnalyticsVariableDateTimeType:
            result = TUNE_DATA_TYPE_DATETIME;
            break;
        case TuneAnalyticsVariableNumberType:
            result = TUNE_DATA_TYPE_FLOAT;
            break;
        case TuneAnalyticsVariableCoordinateType:
            result = TUNE_DATA_TYPE_GEOLOCATION;
            break;
        case TuneAnalyticsVariableVersionType:
            result = TUNE_DATA_TYPE_VERSION;
            break;
        case TuneAnalyticsVariableBooleanType:
            result = TUNE_DATA_TYPE_BOOLEAN;
            break;
    }
    
    return result;
}

+ (TuneAnalyticsVariableDataType)stringToDataType:(NSString *)dataTypeString {
    TuneAnalyticsVariableDataType result = TuneAnalyticsVariableStringType;
    
    if ([dataTypeString isEqualToString:TUNE_DATA_TYPE_STRING]) {
        result = TuneAnalyticsVariableStringType;
    } else if ([dataTypeString isEqualToString:TUNE_DATA_TYPE_DATETIME]) {
        result = TuneAnalyticsVariableDateTimeType;
    } else if ([dataTypeString isEqualToString:TUNE_DATA_TYPE_FLOAT]) {
        result = TuneAnalyticsVariableNumberType;
    } else if ([dataTypeString isEqualToString:TUNE_DATA_TYPE_GEOLOCATION]) {
        result = TuneAnalyticsVariableCoordinateType;
    } else if ([dataTypeString isEqualToString:TUNE_DATA_TYPE_VERSION]) {
        result = TuneAnalyticsVariableVersionType;
    } else if ([dataTypeString isEqualToString:TUNE_DATA_TYPE_BOOLEAN]) {
        result = TuneAnalyticsVariableBooleanType;
    }
    
    return result;
}

+ (NSString *)hashTypeToString:(TuneAnalyticsVariableHashType)type {
    NSString *result;
    
    switch (type) {
        case TuneAnalyticsVariableHashNone:
            result = TUNE_HASH_TYPE_NONE;
            break;
        case TuneAnalyticsVariableHashMD5Type:
            result = TUNE_HASH_TYPE_MD5;
            break;
        case TuneAnalyticsVariableHashSHA1Type:
            result = TUNE_HASH_TYPE_SHA1;
            break;
        case TuneAnalyticsVariableHashSHA256Type:
            result = TUNE_HASH_TYPE_SHA256;
            break;
    }
    
    return result;
}

+ (TuneAnalyticsVariableHashType)stringToHashType:(NSString *)type {
   TuneAnalyticsVariableHashType result = TuneAnalyticsVariableHashNone;
    
    if ([type isEqualToString:TUNE_HASH_TYPE_NONE]) {
        result = TuneAnalyticsVariableHashNone;
    } else if ([type isEqualToString:TUNE_HASH_TYPE_MD5]) {
        result = TuneAnalyticsVariableHashMD5Type;
    } else if ([type isEqualToString:TUNE_HASH_TYPE_SHA1]) {
        result = TuneAnalyticsVariableHashSHA1Type;
    } else if ([type isEqualToString:TUNE_HASH_TYPE_SHA256]) {
        result = TuneAnalyticsVariableHashSHA256Type;
    }
    
    return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TuneAnalyticsVariable *analyticsVar = [[[self class] allocWithZone:zone] init];

    analyticsVar.name = [self.name copyWithZone:zone];
    analyticsVar.value = [self.value copyWithZone:zone];
    analyticsVar.type = self.type;
    analyticsVar.hashType = self.hashType;
    analyticsVar.shouldAutoHash = self.shouldAutoHash;
    analyticsVar.didHaveValueManuallySet = self.didHaveValueManuallySet;

    return analyticsVar;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> (%@, %@)", NSStringFromClass(self.class), self, self.name, self.value];
}


- (BOOL)isEqual:(id)otherVariable {
    NSDictionary *otherDict = [otherVariable toDictionary];
    
    return [otherDict isEqualToDictionary:[self toDictionary]];
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + [name hash] + [value hash] + type;
    return result;
}

#pragma mark - NSCoding

//NSCoder complains when these are constants
NSString *_Nonnull NAME_CODING = @"name";
NSString *_Nonnull VALUE_CODING = @"value";
NSString *_Nonnull TYPE_CODING = @"type";
NSString *_Nonnull HASH_TYPE_CODING = @"hashType";
NSString *_Nonnull SHOULD_AUTO_HASH_CODING = @"shouldAutoHash";
NSString *_Nonnull DID_HAVE_VALUE_MANUALLY_SET_CODING = @"didHaveValueManuallySet";

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.name = [aDecoder decodeObjectForKey:NAME_CODING];
    self.value = [aDecoder decodeObjectForKey:VALUE_CODING];
    self.type = [TuneAnalyticsVariable stringToDataType:[aDecoder decodeObjectForKey:TYPE_CODING]];
    self.hashType = [TuneAnalyticsVariable stringToHashType:[aDecoder decodeObjectForKey:HASH_TYPE_CODING]];
    self.shouldAutoHash = [[aDecoder decodeObjectForKey:SHOULD_AUTO_HASH_CODING] boolValue];
    if ([aDecoder containsValueForKey:DID_HAVE_VALUE_MANUALLY_SET_CODING]) {
        self.didHaveValueManuallySet = [[aDecoder decodeObjectForKey:DID_HAVE_VALUE_MANUALLY_SET_CODING] boolValue];
    } else {
        // If we don't have a value set for this then assume that it has already been set.
        self.didHaveValueManuallySet = YES;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:NAME_CODING];
    [aCoder encodeObject:self.value forKey:VALUE_CODING];
    [aCoder encodeObject:[TuneAnalyticsVariable dataTypeToString:self.type] forKey:TYPE_CODING];
    [aCoder encodeObject:[TuneAnalyticsVariable hashTypeToString:self.hashType] forKey:HASH_TYPE_CODING];
    [aCoder encodeObject:@(self.shouldAutoHash) forKey:SHOULD_AUTO_HASH_CODING];
    [aCoder encodeObject:@(self.didHaveValueManuallySet) forKey:DID_HAVE_VALUE_MANUALLY_SET_CODING];
}

@end
