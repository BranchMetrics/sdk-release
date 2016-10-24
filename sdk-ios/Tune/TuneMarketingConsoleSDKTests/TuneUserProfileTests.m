//
//  TuneUserProfileTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SimpleObserver.h"
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "TuneUserProfile+Testing.h"
#import "TuneAnalyticsVariable.h"
#import "TuneUtils.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneXCTestCase.h"

@interface TuneUserProfileTests : TuneXCTestCase {
    TuneUserProfile *userProfile;
    SimpleObserver *simpleObserver;
}
@end

@implementation TuneUserProfileTests
- (void)setUp {
    [super setUp];
    
    simpleObserver = [[SimpleObserver alloc] init];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    
    // Wait for everything to be set
    waitForQueuesToFinish();
}

- (void)tearDown {
    emptyRequestQueue();
    
    [super tearDown];
}

/////////////////////////////////////////////////
// Tests from Artisan
/////////////////////////////////////////////////

- (void)testRegisterProfileVariableShouldAddToUserProfile {
    [[TuneManager currentManager].userProfile registerString:@"test" withDefault:@"initial"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"test"];
    
    XCTAssertTrue([var.name isEqualToString:@"test"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"initial"], @"variable value should be set");
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
    
    clearUserDefaults();
}

- (void)testSetVariableValueShouldUpdateValue {
    [[TuneManager currentManager].userProfile registerString:@"test"];
    [[TuneManager currentManager].userProfile setStringValue:@"updated" forVariable:@"test"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"test"];
    
    XCTAssertTrue([var.name isEqualToString:@"test"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"updated"], @"variable value should be set");
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testSetValueToNilIsOkay {
    [[TuneManager currentManager].userProfile registerString:@"test" withDefault:@"not nil"];
    [[TuneManager currentManager].userProfile setStringValue:nil forVariable:@"test"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"test"];
    
    XCTAssertTrue([var.name isEqualToString:@"test"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value should be set");
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testSetVariableValueTwiceShouldUpdateUserVariableAndAnalyticsVariables {
    [[TuneManager currentManager].userProfile registerString:@"test" withDefault:nil];
    [[TuneManager currentManager].userProfile setStringValue:@"updated" forVariable:@"test"];
    [[TuneManager currentManager].userProfile setStringValue:@"latest value" forVariable:@"test"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"test"];

    XCTAssertTrue([var.name isEqualToString:@"test"], @"variable name should be set");
    XCTAssertTrue([var.value isEqualToString:@"latest value"], @"variable value should be updated");
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testCannotChangeVariableTypeOnceRegistered {
    [[TuneManager currentManager].userProfile registerNumber:@"numbervar" withDefault:@2];
    [[TuneManager currentManager].userProfile setStringValue:@"WRONG TYPE" forVariable:@"numbervar"]; // this should just be ignored because it is the wrong type
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"numbervar"];
    
    XCTAssertTrue([var.name isEqualToString:@"numbervar"], @"variable name should be set, instead it is %@", var.name);
    XCTAssertEqualObjects(var.value, @2, @"variable value should be updated");
    XCTAssertTrue(var.type == TuneAnalyticsVariableNumberType, @"variable type should be set");
}

- (void)testSetVersionVariableValueShouldUpdateValue {
    [[TuneManager currentManager].userProfile registerVersion:@"apiVersion"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"apiVersion"];
    
    XCTAssertTrue([var.name isEqualToString:@"apiVersion"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value should be set");
    XCTAssertEqual(var.type, TuneAnalyticsVariableVersionType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile setVersionValue:@"2.4.15" forVariable:@"apiVersion"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"apiVersion"];
    
    XCTAssertTrue([var.name isEqualToString:@"apiVersion"], @"variable name should be set");
    XCTAssertTrue([var.value isEqualToString:@"2.4.15"], @"variable value should be updated");
    XCTAssertEqual(var.type, TuneAnalyticsVariableVersionType, @"variable type should be set");
}

/////////////////////////////////////////////////
// New Tests
/////////////////////////////////////////////////

- (void)testDefaultValueShouldBeNil {
    [[TuneManager currentManager].userProfile registerString:@"testString"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    
    XCTAssertTrue([var.name isEqualToString:@"testString"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerBoolean:@"testBoolean"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testBoolean"];
    
    XCTAssertTrue([var.name isEqualToString:@"testBoolean"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableBooleanType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerDateTime:@"testDateTime"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testDateTime"];
    
    XCTAssertTrue([var.name isEqualToString:@"testDateTime"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableDateTimeType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerNumber:@"testNumber"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testNumber"];
    
    XCTAssertTrue([var.name isEqualToString:@"testNumber"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableNumberType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerGeolocation:@"testLocation"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testLocation"];
    
    XCTAssertTrue([var.name isEqualToString:@"testLocation"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableCoordinateType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerVersion:@"testVersion"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testVersion"];
    
    XCTAssertTrue([var.name isEqualToString:@"testVersion"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableVersionType, @"variable type should be set");
}

- (void)testRegisterWithValue {
    [[TuneManager currentManager].userProfile registerString:@"testString" withDefault:@"foobar"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    
    XCTAssertTrue([var.name isEqualToString:@"testString"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"foobar"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerBoolean:@"testBoolean" withDefault:@(YES)];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testBoolean"];
    
    XCTAssertTrue([var.name isEqualToString:@"testBoolean"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToNumber:@(1)], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableBooleanType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerDateTime:@"testDateTime" withDefault:[NSDate dateWithTimeIntervalSince1970:0]];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testDateTime"];
    
    XCTAssertTrue([var.name isEqualToString:@"testDateTime"], @"variable name should be set, got: %@", var.name);
    XCTAssertEqualObjects(var.value, [NSDate dateWithTimeIntervalSince1970:0], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableDateTimeType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerNumber:@"testNumber" withDefault:@(4.5)];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testNumber"];
    
    XCTAssertTrue([var.name isEqualToString:@"testNumber"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToNumber:@(4.5)], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableNumberType, @"variable type should be set");
    
    TuneLocation *tl = [[TuneLocation alloc] init];
    tl.longitude = @(10.57);
    tl.latitude = @(-3.5);
    [[TuneManager currentManager].userProfile registerGeolocation:@"testLocation" withDefault:tl];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testLocation"];
    
    XCTAssertTrue([var.name isEqualToString:@"testLocation"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([((TuneLocation *)var.value).longitude isEqualToNumber:@(10.57)] && [((TuneLocation *)var.value).latitude isEqualToNumber:@(-3.5)], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableCoordinateType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile registerVersion:@"testVersion" withDefault:@"0.0.9"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testVersion"];
    
    XCTAssertTrue([var.name isEqualToString:@"testVersion"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"0.0.9"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableVersionType, @"variable type should be set");
}

- (void)testRegisterWithWeirdName {
    [[TuneManager currentManager].userProfile registerString:@"&&&foo***()bar" withDefault:@"bingbang"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"foobar"];
    
    XCTAssertTrue([var.name isEqualToString:@"foobar"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"bingbang"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testRegisterWithOnlyWeirdChars {
    [[TuneManager currentManager].userProfile registerString:@"$()*())#$()" withDefault:@"bingbang"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@""];
    TuneAnalyticsVariable *var2 = [[TuneManager currentManager].userProfile getProfileVariable:@"$()*())#$()"];
    
    XCTAssertNil(var, @"There shouldn't be a variable registered.");
    XCTAssertNil(var2, @"There shouldn't be a variable registered.");
}


- (void)testSetWithWeirdName {
    [[TuneManager currentManager].userProfile registerString:@"foobar"];
    [[TuneManager currentManager].userProfile setStringValue:@"updated" forVariable:@")*(#&(*foobar*)(*()"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"foobar"];
    
    XCTAssertTrue([var.name isEqualToString:@"foobar"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"updated"], @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testSetWithOnlyWeirdChars {
    [[TuneManager currentManager].userProfile registerString:@"foobar"];
    [[TuneManager currentManager].userProfile setStringValue:@"updated" forVariable:@")*(#&(**)(*()"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"foobar"];
    
    XCTAssertTrue([var.name isEqualToString:@"foobar"], @"variable name should be set, got: %@", var.name);
    XCTAssertNil(var.value, @"variable value shouldn't be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testRegisterSystemVariable {
    TuneAnalyticsVariable *oldVar = [[TuneManager currentManager].userProfile getProfileVariable:@"ios_ifa"];
    
    [[TuneManager currentManager].userProfile registerString:@"ios_ifa" withDefault:@"bingbang"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"ios_ifa"];
    
    XCTAssertTrue([var.name isEqualToString:@"ios_ifa"], @"variable name should be set, got: %@", var.name);
    XCTAssertFalse([var.value isEqualToString:@"bingbang"], @"variable value should be set, got: %@", var.value);
    XCTAssertTrue([var.value isEqualToString:oldVar.value], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testClearVariable {
    [[TuneManager currentManager].userProfile setAge:@50];
    
    XCTAssertTrue([[[TuneManager currentManager] userProfile].age isEqualToNumber:@50], @"variable should be set");
    
    [[TuneManager currentManager].userProfile clearVariable:@"age"];
    
    XCTAssertNil([[TuneManager currentManager] userProfile].age, @"The TuneAnalyticsVariable should be nil.");
}

- (void)testClearVariableAndSet {
    [[TuneManager currentManager].userProfile registerString:@"testString" withDefault:@"foobar"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    
    XCTAssertTrue([var.name isEqualToString:@"testString"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"foobar"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
    
    [[TuneManager currentManager].userProfile clearVariable:@"testString"];
    
    [[TuneManager currentManager].userProfile setStringValue:@"updated" forVariable:@"testString"];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    
    XCTAssertTrue([var.value isEqualToString:@"updated"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (void)testClearCustomVariables {
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneUserProfileVariablesCleared object:nil];
    
    [[TuneManager currentManager].userProfile registerString:@"testString" withDefault:@"foobar"];
    [[TuneManager currentManager].userProfile registerString:@"testString2" withDefault:@"foobarbaz"];
    [[TuneManager currentManager].userProfile setAge:@50];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    
    XCTAssertTrue([var.name isEqualToString:@"testString"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var.value isEqualToString:@"foobar"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var.type, TuneAnalyticsVariableStringType, @"variable type should be set");
    
    TuneAnalyticsVariable *var2 = [[TuneManager currentManager].userProfile getProfileVariable:@"testString2"];
    
    XCTAssertTrue([var2.name isEqualToString:@"testString2"], @"variable name should be set, got: %@", var.name);
    XCTAssertTrue([var2.value isEqualToString:@"foobarbaz"], @"variable value should be set, got: %@", var.value);
    XCTAssertEqual(var2.type, TuneAnalyticsVariableStringType, @"variable type should be set");
    
    // Remove both a valid custom variable, an unregistered variable, and a non-custom variable.
    [[TuneManager currentManager].userProfile clearCustomVariables: [NSSet setWithObjects:@"testString", @"notValid", @"age", nil]];
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    
    // Valid variable got removed.
    XCTAssertNil(var, @"The TuneAnalyticsVariable should be nil.");
    
    // Other custom variable was untouched.
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"testString2"];
    XCTAssertTrue([var.value isEqualToString:@"foobarbaz"]);
    
    // Non-custom variable was untouched.
    XCTAssertTrue([[TuneManager currentManager].userProfile.age isEqualToNumber:@50]);
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    // Ensure the PowerHook was called.
    NSSet *expectedPayload = [NSSet setWithObjects:@"testString", nil];
    XCTAssertEqual([simpleObserver skyhookPostCount], 1);
    XCTAssertTrue([[simpleObserver lastPayload].userInfo[TunePayloadProfileVariablesToClear] isEqualToSet:expectedPayload]);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneUserProfileVariablesCleared object:nil];
}

- (void)testClearCustomVariablesNoPowerhook {
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneUserProfileVariablesCleared object:nil];
    [[TuneManager currentManager].userProfile setAge:@50];
    
    // Remove both an unregistered variable and a non-custom variable.
    [[TuneManager currentManager].userProfile clearCustomVariables: [NSSet setWithObjects:@"notValid", @"age", nil]];
    
    // Non-custom variable was untouched.
    XCTAssertTrue([[TuneManager currentManager].userProfile.age isEqualToNumber:@50]);
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    // Ensure the PowerHook was not called.
    XCTAssertEqual([simpleObserver skyhookPostCount], 0);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneUserProfileVariablesCleared object:nil];
}

- (void)testClearCustomVariablesInvalidName {
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneUserProfileVariablesCleared object:nil];

    [[TuneManager currentManager].userProfile registerString:@"valid__valid" withDefault:@"foobar"];
    
    // Remove both a registered value with invalid characters and a completely invalid string.
    [[TuneManager currentManager].userProfile clearCustomVariables: [NSSet setWithObjects:@"$$#$&^", @"valid_$#$_valid", nil]];
    
    // Flush Skyhook queue
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    
    // Ensure the invalid string was ignored and the variable with invalid characters was cleaned.
    NSSet *expectedPayload = [NSSet setWithObjects:@"valid__valid", nil];
    XCTAssertEqual([simpleObserver skyhookPostCount], 1);
    XCTAssertTrue([[simpleObserver lastPayload].userInfo[TunePayloadProfileVariablesToClear] isEqualToSet:expectedPayload]);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneUserProfileVariablesCleared object:nil];
}

- (void)testClearCustomProfile {
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneUserProfileVariablesCleared object:nil];
    
    [[TuneManager currentManager].userProfile registerString:@"testString" withDefault:@"foobar"];
    [[TuneManager currentManager].userProfile registerString:@"testString2" withDefault:@"foobar2"];
    
    [[TuneManager currentManager].userProfile clearCustomProfile];
    
    TuneAnalyticsVariable *var1 = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    TuneAnalyticsVariable *var2 = [[TuneManager currentManager].userProfile getProfileVariable:@"testString2"];
    
    XCTAssertNil(var1, @"The TuneAnalyticsVariable should be nil.");
    XCTAssertNil(var2, @"The TuneAnalyticsVariable should be nil.");
    
    // Ensure the invalid string was ignored and the variable with invalid characters was cleaned.
    NSSet *expectedPayload = [NSSet setWithObjects:@"testString", @"testString2", nil];
    [[TuneSkyhookCenter defaultCenter] waitTilQueueFinishes];
    XCTAssertEqual([simpleObserver skyhookPostCount], 1);
    XCTAssertTrue([[simpleObserver lastPayload].userInfo[TunePayloadProfileVariablesToClear] isEqualToSet:expectedPayload]);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneUserProfileVariablesCleared object:nil];
    
    [[TuneManager currentManager].userProfile setStringValue:@"updated" forVariable:@"testString"];
    
    var1 = [[TuneManager currentManager].userProfile getProfileVariable:@"testString"];
    XCTAssertTrue([var1.value isEqualToString:@"updated"], @"variable value should be set, got: %@", var1.value);
    XCTAssertEqual(var1.type, TuneAnalyticsVariableStringType, @"variable type should be set");
}

- (BOOL)checkArrayOfDictionaries:(NSArray *)inputArray key:(NSString *)key expectedValue:(id)value {
    for (NSDictionary *dict in inputArray) {
        if ([[dict objectForKey:@"name"] isEqualToString:key]) {
            NSString *stored = [dict objectForKey:@"value"];
            XCTAssertTrue(stored == value || [stored isEqualToString:value], @"Unexpected value stored for key %@: %@", key, stored);
            
            return YES;
        }
    }
    return NO;
    
}

- (NSArray *)getDictionary:(NSArray *)inputArray key:(NSString *)key {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in inputArray) {
        if ([[dict objectForKey:@"name"] isEqualToString:key]) {
            [result addObject:dict];
        }
    }
    return result.copy;
}

- (void)testToArrayOfDictionaries {
    [[TuneManager currentManager].userProfile registerString:@"in1" withDefault:@"foobar"];
    [[TuneManager currentManager].userProfile registerString:@"in2" withDefault:nil];
    [[TuneManager currentManager].userProfile registerString:@"in3"];
    
    [[TuneManager currentManager].userProfile storeProfileKey:@"profileVar1" value:@"not_empty"];
    [[TuneManager currentManager].userProfile storeProfileKey:@"profileVar2" value:@""];
    [[TuneManager currentManager].userProfile storeProfileKey:@"profileVar3" value:nil];
    [[TuneManager currentManager].userProfile storeProfileKey:@"profileVar4" value:[NSNull null]];
    NSArray *output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    
    //Transform the output into
    
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"in1" expectedValue:@"foobar"]);
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"in2" expectedValue:[NSNull null]]);
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"in3" expectedValue:[NSNull null]]);
    
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"profileVar1" expectedValue:@"not_empty"]);
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"profileVar2" expectedValue:@""]);
    // This variable should not be in the array because the value was nil
    XCTAssertFalse([self checkArrayOfDictionaries:output key:@"profileVar3" expectedValue:nil]);
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"profileVar4" expectedValue:[NSNull null]]);
}

- (void)testDontSendDecomposedLocationStuff {
    TuneLocation *loc = [[TuneLocation alloc] init];
    loc.longitude = @(6.7777);
    loc.latitude = @(9.88998);
    loc.altitude = @(5.1);
    [[TuneManager currentManager].userProfile setLocation:loc];
    
    NSArray *output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    XCTAssertTrue([self checkArrayOfDictionaries:output key:@"geo_coordinate" expectedValue:@"6.777700000,9.889980000"]);
    XCTAssertFalse([self checkArrayOfDictionaries:output key:@"longitude" expectedValue:nil]);
    XCTAssertFalse([self checkArrayOfDictionaries:output key:@"latitude" expectedValue:nil]);
    XCTAssertFalse([self checkArrayOfDictionaries:output key:@"altitude" expectedValue:nil]);
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"longitude"];
    XCTAssertTrue([var.value isEqualToNumber:@(6.7777)]);
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"latitude"];
    XCTAssertTrue([var.value isEqualToNumber:@(9.88998)]);
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"altitude"];
    XCTAssertTrue([var.value isEqualToNumber:@(5.1)]);
}

- (void)testHashedString {
    [[TuneManager currentManager].userProfile registerString:@"c1" withDefault:@"foobar" hashed:YES];
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"c1"];
    
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashNone);
    XCTAssertTrue(var.shouldAutoHash);
}

- (void)testPreHashedVariablesOnlyHashedOnce {
    [[TuneManager currentManager].userProfile setUserName:@"Jim Rogers"];
    
    NSArray *output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    
    XCTAssertTrue([self getDictionary:output key:TUNE_KEY_USER_NAME_MD5].count == 1);
    NSDictionary *var = [self getDictionary:output key:TUNE_KEY_USER_NAME_MD5][0];
    XCTAssertTrue([var[@"hash"] isEqualToString:@"md5"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"4518c3ca8d0dcb253e66a5ab16495ec2"]);
    
    XCTAssertTrue([self getDictionary:output key:TUNE_KEY_USER_NAME_SHA1].count == 1);
    var = [self getDictionary:output key:TUNE_KEY_USER_NAME_SHA1][0];
    XCTAssertTrue([var[@"hash"] isEqualToString:@"sha1"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"15dc14109c5f7d263f2aebf8d0ebfb7ae2d9a118"]);
    
    XCTAssertTrue([self getDictionary:output key:TUNE_KEY_USER_NAME_SHA256].count == 1);
    var = [self getDictionary:output key:TUNE_KEY_USER_NAME_SHA256][0];
    XCTAssertTrue([var[@"hash"] isEqualToString:@"sha256"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"53149a84ca2e85a9c853b7fb017c58c16cdc48fed3759be89b008d73d1b6d834"]);
}

- (void)testPreventAddingCustomProfileVariablesStartingWithTune {
    [[TuneManager currentManager].userProfile registerString:@"TUNE_whatever" withDefault:@"foobar"];
    [[TuneManager currentManager].userProfile registerString:@"Tune_whatever" withDefault:@"foobar"];
    
    TuneAnalyticsVariable *var = [[TuneManager currentManager].userProfile getProfileVariable:@"TUNE_whatever"];
    XCTAssertNil(var);
    
    var = [[TuneManager currentManager].userProfile getProfileVariable:@"Tune_whatever"];
    XCTAssertTrue([var.name isEqualToString:@"Tune_whatever"]);
    XCTAssertTrue([var.value isEqualToString:@"foobar"]);
}
    
- (void)testVariationIdsAreAddedCorrectly {
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableValue:@"variation1", TunePayloadSessionVariableName: @"TUNE_ACTIVE_VARIATION_ID", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeProfile}];
    
    NSArray *output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    NSDictionary *var = [self getDictionary:output key:@"TUNE_ACTIVE_VARIATION_ID"][0];
    XCTAssertTrue([var[@"type"] isEqualToString:@"string"]);
    XCTAssertTrue([var[@"value"] isEqualToString:@"variation1"]);
    
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableValue:@"variation2", TunePayloadSessionVariableName: @"TUNE_ACTIVE_VARIATION_ID", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeProfile}];
    
    output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    XCTAssertTrue([self getDictionary:output key:@"TUNE_ACTIVE_VARIATION_ID"].count == 2);

    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableValue:@"variation2", TunePayloadSessionVariableName: @"TUNE_ACTIVE_VARIATION_ID", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeProfile}];
    
    output = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    XCTAssertTrue([self getDictionary:output key:@"TUNE_ACTIVE_VARIATION_ID"].count == 2);
}

- (void)testPublicGettersNoDefault {
    [Tune registerCustomProfileString:@"customString"];
    XCTAssertNil([Tune getCustomProfileString:@"customString"]);
    
    [Tune registerCustomProfileNumber:@"customNumber"];
    XCTAssertNil([Tune getCustomProfileNumber:@"customNumber"]);
    
    [Tune registerCustomProfileDateTime:@"customDateTime"];
    XCTAssertNil([Tune getCustomProfileString:@"customDateTime"]);
    
    [Tune registerCustomProfileGeolocation:@"customLocation"];
    XCTAssertNil([Tune getCustomProfileString:@"customLocation"]);
}

- (void)testPublicGettersWithDefault {
    [Tune registerCustomProfileString:@"customString" withDefault:@"default"];
    XCTAssertTrue([@"default" isEqualToString:[Tune getCustomProfileString:@"customString"]]);
    
    [Tune registerCustomProfileNumber:@"customNumber" withDefault:@(99)];
    XCTAssertTrue([@(99) isEqualToNumber:[Tune getCustomProfileNumber:@"customNumber"]]);
    
    NSDate *date = [NSDate date];
    [Tune registerCustomProfileDateTime:@"customDateTime" withDefault:date];
    XCTAssertTrue([date isEqualToDate:[Tune getCustomProfileDateTime:@"customDateTime"]]);
    
    TuneLocation *loc = [TuneLocation new];
    loc.longitude = @(14.11);
    loc.latitude = @(15.33);
    [Tune registerCustomProfileGeolocation:@"customLocation" withDefault:loc];
    TuneLocation *result = [Tune getCustomProfileGeolocation:@"customLocation"];
    XCTAssertTrue([loc.longitude isEqualToNumber:result.longitude]);
    XCTAssertTrue([loc.latitude isEqualToNumber:result.latitude]);
}

- (void)testPublicGettersBeforeRegisteration {
    [TuneUserDefaultsUtils setUserDefaultCustomVariable:[TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"notnil"] forKey:@"foobar"];
    XCTAssertNil([Tune getCustomProfileString:@"foobar"]);
}

- (void)testTooYoungForTargetedAds {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertNil(profile.age);
    XCTAssertFalse([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(6)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(13)];
    XCTAssertFalse([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(12)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(17)];
    XCTAssertFalse([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(-1)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(0)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testReregisterUnsetProfileVariables {
    TuneUserProfile *profile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    
    [profile registerString:@"myString"];
    XCTAssertNil([profile getCustomProfileString:@"myString"]);
    
    profile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    
    [profile registerString:@"myString" withDefault:@"default"];
    XCTAssertTrue([@"default" isEqualToString:[profile getCustomProfileString:@"myString"]]);
    
    [profile setStringValue:@"not default" forVariable:@"myString"];
    
    profile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    
    [profile registerString:@"myString" withDefault:@"default two"];
    XCTAssertTrue([@"not default" isEqualToString:[profile getCustomProfileString:@"myString"]]);
}

- (void)testCustomProfileVariablesPersistBetweenSessions {
    [[TuneManager currentManager].userProfile registerString:@"persistingString" withDefault:@"persistingValue"];
    
    // Trigger a save of the custom variable names
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self userInfo:nil];
    waitForQueuesToFinish();
    
    // Re-init profile manager
    TuneUserProfile *profile = [[TuneManager currentManager].userProfile initWithTuneManager:[TuneManager currentManager]];
    
    // Trigger a load of the custom variable names
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self userInfo:@{@"sessionId": @"123", @"sessionStartTime": [NSDate date]}];
    waitForQueuesToFinish();
    
    // Check that previously registered profile variable persists
    XCTAssertEqualObjects(@"persistingValue", [profile getCustomProfileString:@"persistingString"]);
}

- (void)testAppleReceiptOnlySentWithFirstSession {
    // Set first session to true
    [[TuneManager currentManager].userProfile setIsFirstSession:@(1)];
    
    // Trigger a marshaling to dictionary as an analytics event would do
    NSArray *profileArray = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    
    // Assert that the user profile toArrayOfDictionaries method contains an apple receipt for the first session
    NSArray *receiptVar = [[[[TuneManager currentManager].userProfile getProfileVariables] objectForKey:TUNE_KEY_INSTALL_RECEIPT] toArrayOfDicts];
    
    XCTAssertTrue([profileArray containsObject:receiptVar[0]]);
    
    // Set first session to false
    [[TuneManager currentManager].userProfile setIsFirstSession:@(0)];
    
    // Trigger another marshaling to dictionary
    profileArray = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
    
    // Assert that the user profile toArrayOfDictionaries method does not contain an apple receipt for the non-first session
    XCTAssertFalse([profileArray containsObject:receiptVar[0]]);
}

@end
