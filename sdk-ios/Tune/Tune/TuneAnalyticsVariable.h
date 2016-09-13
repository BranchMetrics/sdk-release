//
//  TuneAnalyticsVariable.h
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/28/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneLocation;

typedef enum { TuneAnalyticsVariableStringType,
               TuneAnalyticsVariableBooleanType,
               TuneAnalyticsVariableDateTimeType,
               TuneAnalyticsVariableNumberType,
               TuneAnalyticsVariableCoordinateType,
               TuneAnalyticsVariableVersionType } TuneAnalyticsVariableDataType;

typedef enum { TuneAnalyticsVariableHashNone,
               TuneAnalyticsVariableHashMD5Type,
               TuneAnalyticsVariableHashSHA1Type,
               TuneAnalyticsVariableHashSHA256Type } TuneAnalyticsVariableHashType;

@interface TuneAnalyticsVariable : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id value;
@property (nonatomic, readwrite) TuneAnalyticsVariableDataType type;
@property (nonatomic, readwrite) TuneAnalyticsVariableHashType hashType;
@property (nonatomic, readwrite) BOOL shouldAutoHash;
@property (nonatomic, readwrite) BOOL didHaveValueManuallySet;

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value;

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type;

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type
                           shouldAutoHash:(BOOL)shouldAutoHash;

+ (instancetype)analyticsVariableWithName:(NSString *)name
                                    value:(id)value
                                     type:(TuneAnalyticsVariableDataType)type
                                 hashType:(TuneAnalyticsVariableHashType)hashType
                           shouldAutoHash:(BOOL)newshouldAutoHash;


+ (NSString *)convertDateToString:(NSDate *)date;
+ (NSString *)convertNumberToString:(NSNumber *)inputValue;

+ (NSString *)convertTuneLocationToString:(TuneLocation *)location;
+ (BOOL)validateTuneLocation:(TuneLocation *)location;

+ (BOOL)validateVersion:(NSString *)value;

+ (NSString *)cleanVariableName:(NSString *)string;
+ (BOOL) validateName:(NSString *)variableName;

- (NSString *)convertValueToString;
- (NSDictionary *) toDictionary;
- (NSArray *) toArrayOfDicts;

+ (NSString *) dataTypeToString:(TuneAnalyticsVariableDataType)dataType;
+ (TuneAnalyticsVariableDataType) stringToDataType:(NSString *)dataTypeString;

+ (NSString *) hashTypeToString:(TuneAnalyticsVariableHashType)hashType;
+ (TuneAnalyticsVariableHashType) stringToHashType:(NSString *)hashTypeString;

@end
