//
//  MATTestParams.h
//  MobileAppTracker
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ASSERT_KEY_VALUE( key, value ) XCTAssertTrue( [params checkKey:key isEqualToValue:value], \
                                                      @"key '%@' must equal '%@'; found '%@' instead", key, value, [params valueForKey:key] );
#define ASSERT_NO_VALUE_FOR_KEY( key ) XCTAssertFalse( [params checkKeyHasValue:key], \
                                                       @"must not have a value for '%@', but found '%@'", key, [params valueForKey:key] );


@interface MATTestParams : NSObject

-(BOOL) isEqualToParams:(MATTestParams*)other;
-(BOOL) isEmpty;

-(BOOL) extractParamsString:(NSString*)string;
-(BOOL) extractParamsJSON:(NSString*)json;

-(NSString*) valueForKey:(NSString*)key;

-(BOOL) checkIsEmpty;
-(BOOL) checkKeyHasValue:(NSString*)key;
-(BOOL) checkKey:(NSString*)key isEqualToValue:(NSString*)value;
-(BOOL) checkDefaultValues;
-(BOOL) checkDataItems:(NSArray*)items;
-(BOOL) checkNoDataItems;
-(BOOL) checkReceiptEquals:(NSData*)receiptValue;

@end
