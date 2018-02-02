//
//  TuneAnalyticsVariableTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "TuneUserProfile.h"
#import "TuneAnalyticsVariable.h"
#import "TuneLocation.h"
#import "TuneXCTestCase.h"

@interface TuneAnalyticsVariableTests : TuneXCTestCase

@end

@implementation TuneAnalyticsVariableTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (BOOL)isValidVersionString:(NSString *)version {
    BOOL isValid = [TuneAnalyticsVariable validateVersion:version];
    XCTAssertTrue(isValid, @"Version should be valid.");
}

- (BOOL)isNotValidVersionString:(NSString *)version {
    BOOL isValid = [TuneAnalyticsVariable validateVersion:version];
    XCTAssertFalse(isValid, @"Version should not be valid.");
}

- (void)testValidateTuneLocation {
    TuneLocation *loc;
    
    XCTAssertTrue([TuneAnalyticsVariable validateTuneLocation:loc]);
    
    loc = [[TuneLocation alloc] init];
    
    XCTAssertFalse([TuneAnalyticsVariable validateTuneLocation:loc]);
    
    loc.longitude = @(10);
    loc.latitude = nil;
    
    XCTAssertFalse([TuneAnalyticsVariable validateTuneLocation:loc]);
    
    loc.longitude = nil;
    loc.latitude = @(10);
    
    XCTAssertFalse([TuneAnalyticsVariable validateTuneLocation:loc]);
    
    loc.longitude = @(10);
    loc.latitude = @(10);
    
    XCTAssertTrue([TuneAnalyticsVariable validateTuneLocation:loc]);
}

- (void)testConvertTuneLocation {
    TuneLocation *loc = [[TuneLocation alloc] init];
    loc.longitude = @(10);
    loc.latitude = @(11);
    
    XCTAssertTrue([[TuneAnalyticsVariable convertTuneLocationToString:loc] isEqualToString:@"10.000000000,11.000000000"]);
    
    loc.altitude = @(12);
    
    XCTAssertTrue([[TuneAnalyticsVariable convertTuneLocationToString:loc] isEqualToString:@"10.000000000,11.000000000"]);
    
    loc.longitude = @(10.12345);
    loc.latitude = @(11.3221);
    
    XCTAssertTrue([[TuneAnalyticsVariable convertTuneLocationToString:loc] isEqualToString:@"10.123450000,11.322100000"]);
    
    loc.longitude = @(10.5678900001);
    loc.latitude = @(11.9887000001);
    
    XCTAssertTrue([[TuneAnalyticsVariable convertTuneLocationToString:loc] isEqualToString:@"10.567890000,11.988700000"]);
}

- (void)testValidateVersion {
    [self isValidVersionString:@"2.4.8"];
    [self isValidVersionString:@"2.4.8-SNAPSHOT"];
    [self isValidVersionString:@"2.4.8-1234"];
    [self isValidVersionString:@"2.4"];
    [self isValidVersionString:@"2.4-Weee"];
    [self isValidVersionString:@"2.4-8"];
    [self isValidVersionString:@"2"];
    [self isValidVersionString:@"2-too"];
    [self isValidVersionString:@"2-2"];
    [self isValidVersionString:@"2-"];
    [self isValidVersionString:@"2.4-"];
    [self isValidVersionString:@"2.4.8-"];
    [self isValidVersionString:@"29999.4"];
    [self isValidVersionString:nil];
    [self isValidVersionString:@"2-4-6-8"];
    [self isValidVersionString:@"0.9"];
    [self isValidVersionString:@"0.0"];
    
    [self isNotValidVersionString:@"2b2b2b2b"];
    [self isNotValidVersionString:@"1.2.3.4.5.6.7..8.9.0.10"];
    [self isNotValidVersionString:@"2FAKEFAKEFAKE"];
    [self isNotValidVersionString:@"FAKEFAKEFAKE"];
    [self isNotValidVersionString:@"8_3"];
    [self isNotValidVersionString:@"6/8/15"];
    [self isNotValidVersionString:@"6\\8\\15"];
    [self isNotValidVersionString:@"   2.4.8   "];
    [self isNotValidVersionString:@"   "];
    [self isNotValidVersionString:@"{twotee}"];
    [self isNotValidVersionString:@"99%"];
}

- (void)testValidateVersionUsingApacheMavenExamples {
    // these values are numerically comparable
    [self isValidVersionString:@"1"];
    [self isValidVersionString:@"1.2"];
    [self isValidVersionString:@"1.2.3"];
    [self isValidVersionString:@"1.2.3-1"];
    [self isValidVersionString:@"1.2.3-alpha-1"];
    [self isValidVersionString:@"1.2-alpha-1"];
    [self isValidVersionString:@"1.2-alpha-1-20050205.060708-1"];
    [self isValidVersionString:@"2.0-1"];
    [self isValidVersionString:@"2.0-01"];
    
    // Artisan chooses not to accept these values
    [self isNotValidVersionString:@"1.1.2.beta1"];
    [self isNotValidVersionString:@"1.7.3.b"];
    
    // these values are NOT numerically comparable
    [self isValidVersionString:@"1.2.3-200705301630"];
    [self isNotValidVersionString:@"RELEASE"];
    [self isNotValidVersionString:@"02"];
    [self isNotValidVersionString:@"0.09"];
    [self isNotValidVersionString:@"0.2.09"];
    [self isNotValidVersionString:@"1.0.1b"];
    [self isNotValidVersionString:@"1.0M2"];
    [self isNotValidVersionString:@"1.0RC2"];
    [self isNotValidVersionString:@"1.7.3.0"];
    [self isNotValidVersionString:@"1.7.3.0-1"];
    [self isNotValidVersionString:@"PATCH-1193602"];
    [self isNotValidVersionString:@"5.0.0alpha-2006020117"];
    [self isNotValidVersionString:@"1.0.0.-SNAPSHOT"];
    [self isNotValidVersionString:@"1..0-SNAPSHOT"];
    [self isNotValidVersionString:@"1.0.-SNAPSHOT"];
    [self isNotValidVersionString:@".1.0-SNAPSHOT"];
    [self isNotValidVersionString:@"1.2.3.200705301630"];
}

- (void)testCleanName {
    XCTAssertTrue([TuneAnalyticsVariable cleanVariableName:nil] == nil);
    XCTAssertTrue([[TuneAnalyticsVariable cleanVariableName:@"foobar"] isEqualToString:@"foobar"]);
    XCTAssertTrue([[TuneAnalyticsVariable cleanVariableName:@"foo_bar-bing"] isEqualToString:@"foo_bar-bing"]);
    XCTAssertTrue([[TuneAnalyticsVariable cleanVariableName:@"^foobar$"] isEqualToString:@"foobar"]);
    XCTAssertTrue([[TuneAnalyticsVariable cleanVariableName:@"foobar=0->9"] isEqualToString:@"foobar0-9"]);
}

- (void)testValidateName {
    XCTAssertFalse([TuneAnalyticsVariable validateName:nil]);
    XCTAssertFalse([TuneAnalyticsVariable validateName:@""]);
    XCTAssertFalse([TuneAnalyticsVariable validateName:@"&()*%%^&^"]);
    
    XCTAssertTrue([TuneAnalyticsVariable validateName:@"foobar"]);
    XCTAssertTrue([TuneAnalyticsVariable validateName:@"foob#%#@ar"]);
    XCTAssertTrue([TuneAnalyticsVariable validateName:@"foo_bar-bing"]);
}

- (void)testToDictionary {
    NSDictionary *var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testString" value:@"foo" type:TuneAnalyticsVariableStringType] toDictionary];
    NSDictionary *expected = @{ @"name" : @"testString", @"value" : @"foo", @"type" : @"string"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testNumber" value:@(100) type:TuneAnalyticsVariableNumberType] toDictionary];
    expected = @{ @"name" : @"testNumber", @"value" : @"100", @"type" : @"float"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testNumber" value:@(100.87) type:TuneAnalyticsVariableNumberType] toDictionary];
    expected = @{ @"name" : @"testNumber", @"value" : @"100.87", @"type" : @"float"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testVersion" value:@"0.110.9" type:TuneAnalyticsVariableVersionType] toDictionary];
    expected = @{ @"name" : @"testVersion", @"value" : @"0.110.9", @"type" : @"version"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testBoolean" value:@(TRUE) type:TuneAnalyticsVariableBooleanType] toDictionary];
    expected = @{ @"name" : @"testBoolean", @"value" : @"1", @"type" : @"boolean"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testBoolean" value:@(FALSE) type:TuneAnalyticsVariableBooleanType] toDictionary];
    expected = @{ @"name" : @"testBoolean", @"value" : @"0", @"type" : @"boolean"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    TuneLocation *loc = [[TuneLocation alloc] init];
    loc.longitude = @(10);
    loc.latitude = @(11);
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testLocation" value:loc type:TuneAnalyticsVariableCoordinateType] toDictionary];
    expected = @{ @"name" : @"testLocation", @"value" : @"10.000000000,11.000000000", @"type" : @"geolocation"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testDate" value:[NSDate dateWithTimeIntervalSince1970:0] type:TuneAnalyticsVariableDateTimeType] toDictionary];
    expected = @{ @"name" : @"testDate", @"value" : @"1970-01-01T00:00:00Z", @"type" : @"datetime"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
}

- (void)testToDictionaryWithNils {
    NSDictionary *var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testString" value:nil type:TuneAnalyticsVariableStringType] toDictionary];
    NSDictionary *expected = @{ @"name" : @"testString", @"value" : [NSNull null], @"type" : @"string"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:nil value:@"foo" type:TuneAnalyticsVariableStringType] toDictionary];
    expected = @{ @"name" : [NSNull null], @"value" : @"foo", @"type" : @"string"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableNumberType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"float"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableBooleanType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"boolean"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableCoordinateType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"geolocation"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableDateTimeType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"datetime"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableVersionType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"version"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
}

- (void)testToDictionaryWithNSNulls {
    NSDictionary *var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testString" value:[NSNull null] type:TuneAnalyticsVariableStringType] toDictionary];
    NSDictionary *expected = @{ @"name" : @"testString", @"value" : [NSNull null], @"type" : @"string"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:[NSNull null] type:TuneAnalyticsVariableNumberType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"float"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:[NSNull null] type:TuneAnalyticsVariableBooleanType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"boolean"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:[NSNull null] type:TuneAnalyticsVariableCoordinateType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"geolocation"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:[NSNull null] type:TuneAnalyticsVariableDateTimeType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"datetime"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:[NSNull null] type:TuneAnalyticsVariableVersionType] toDictionary];
    expected = @{ @"name" : @"test", @"value" : [NSNull null], @"type" : @"version"};
    XCTAssertTrue([var isEqualToDictionary:expected]);
}


- (void)testToStringWithNils {
    NSString *var = [[TuneAnalyticsVariable analyticsVariableWithName:@"testString" value:nil type:TuneAnalyticsVariableStringType] convertValueToString];
    XCTAssertNil(var);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableNumberType] convertValueToString];
    XCTAssertNil(var);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableBooleanType] convertValueToString];
    XCTAssertNil(var);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableCoordinateType] convertValueToString];
    XCTAssertNil(var);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableDateTimeType] convertValueToString];
    XCTAssertNil(var);
    
    var = [[TuneAnalyticsVariable analyticsVariableWithName:@"test" value:nil type:TuneAnalyticsVariableVersionType] convertValueToString];
    XCTAssertNil(var);
}

- (void)testHashType {
    TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"2063c1608d6e0baf80249c42e2be5804" type:TuneAnalyticsVariableStringType hashType:TuneAnalyticsVariableHashMD5Type shouldAutoHash:NO];
    NSDictionary *converted = [var toDictionary];
    NSDictionary *expected = @{ @"name" : @"foobar", @"value" : @"2063c1608d6e0baf80249c42e2be5804", @"type" : @"string", @"hash": @"md5"};
    XCTAssertTrue([converted isEqualToDictionary:expected]);
    XCTAssertTrue([var toArrayOfDicts].count == 1);
    XCTAssertTrue([converted isEqualToDictionary:[var toArrayOfDicts][0]]);
    
    var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"f32b67c7e26342af42efabc674d441dca0a281c5" type:TuneAnalyticsVariableStringType hashType:TuneAnalyticsVariableHashSHA1Type shouldAutoHash:NO];
    converted = [var toDictionary];
    expected = @{ @"name" : @"foobar", @"value" : @"f32b67c7e26342af42efabc674d441dca0a281c5", @"type" : @"string", @"hash": @"sha1"};
    XCTAssertTrue([converted isEqualToDictionary:expected]);
    XCTAssertTrue([var toArrayOfDicts].count == 1);
    XCTAssertTrue([converted isEqualToDictionary:[var toArrayOfDicts][0]]);
    
    var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"cd42404d52ad55ccfa9aca4adc828aa5800ad9d385a0671fbcbf724118320619" type:TuneAnalyticsVariableStringType hashType:TuneAnalyticsVariableHashSHA256Type shouldAutoHash:NO];
    converted = [var toDictionary];
    expected = @{ @"name" : @"foobar", @"value" : @"cd42404d52ad55ccfa9aca4adc828aa5800ad9d385a0671fbcbf724118320619", @"type" : @"string", @"hash": @"sha256"};
    XCTAssertTrue([converted isEqualToDictionary:expected]);
    XCTAssertTrue([var toArrayOfDicts].count == 1);
    XCTAssertTrue([converted isEqualToDictionary:[var toArrayOfDicts][0]]);
    
    var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"value" type:TuneAnalyticsVariableStringType hashType:TuneAnalyticsVariableHashNone shouldAutoHash:NO];
    converted = [var toDictionary];
    expected = @{ @"name" : @"foobar", @"value" : @"value", @"type" : @"string"};
    XCTAssertTrue([converted isEqualToDictionary:expected]);
    XCTAssertTrue([var toArrayOfDicts].count == 1);
    XCTAssertTrue([converted isEqualToDictionary:[var toArrayOfDicts][0]]);
}

- (void)testAutoHash {
    TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"value" type:TuneAnalyticsVariableStringType hashType:TuneAnalyticsVariableHashNone shouldAutoHash:YES];
    NSArray *converted = [var toArrayOfDicts];
    NSArray *expected = @[ @{ @"name" : @"foobar", @"value" : @"2063c1608d6e0baf80249c42e2be5804", @"type" : @"string", @"hash": @"md5"},
                           @{ @"name" : @"foobar", @"value" : @"f32b67c7e26342af42efabc674d441dca0a281c5", @"type" : @"string", @"hash": @"sha1"},
                           @{ @"name" : @"foobar", @"value" : @"cd42404d52ad55ccfa9aca4adc828aa5800ad9d385a0671fbcbf724118320619", @"type" : @"string", @"hash": @"sha256"}
                         ];
    XCTAssertTrue(converted.count == 3);
    XCTAssertTrue([converted[0] isEqualToDictionary:expected[0]]);
    XCTAssertTrue([converted[1] isEqualToDictionary:expected[1]]);
    XCTAssertTrue([converted[2] isEqualToDictionary:expected[2]]);
}

@end
