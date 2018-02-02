//
//  TuneTestParams.h
//  Tune
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ASSERT_KEY_VALUE( key, value ) XCTAssertTrue( [params checkKey:key isEqualToValue:value], \
                                                      @"key '%@' must equal '%@'; found '%@' instead", key, value, [params valueForKey:key] );
#define ASSERT_NO_VALUE_FOR_KEY( key ) XCTAssertFalse( [params checkKeyHasValue:key], \
                                                       @"must not have a value for '%@', but found '%@'", key, [params valueForKey:key] );


@interface TuneTestParams : NSObject

@property (nonatomic, strong) NSMutableDictionary *params;

- (BOOL)isEqualToParams:(TuneTestParams*)other;
- (BOOL)isEmpty;

- (BOOL)extractParamsFromQueryString:(NSString*)string;
- (BOOL)extractParamsFromJson:(NSString*)json;

- (NSString*)valueForKey:(NSString*)key;

- (BOOL)checkIsEmpty;
- (BOOL)checkKeyHasValue:(NSString*)key;
- (BOOL)checkKey:(NSString*)key isEqualToValue:(NSString*)value;

/*!
 Checks default values for all params except "conversion_user_agent" param.
 This allows running testcases that are unable to wait for user-agent population which may require ~1 sec on the main thread.
 */
- (BOOL)checkDefaultValues;
- (BOOL)checkDataItems:(NSArray*)items;
- (BOOL)checkNoDataItems;
- (BOOL)checkReceiptEquals:(NSData*)receiptValue;
- (BOOL)checkAppleReceiptEquals:(NSData*)receiptValue;

@end
