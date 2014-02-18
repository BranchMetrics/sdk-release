//
//  MATTestParams.m
//  MobileAppTracker
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import "MATTestParams.h"
#import "MATTests.h"
#import <MobileAppTracker/MobileAppTracker.h>
#import "MATUtils.h"

static NSString* const kDataItemKey = @"testBodyDataItems";
static NSString* const kReceiptItemKey = @"testBodyReceipt";

@implementation MATTestParams

-(NSString*) description
{
    return [params description];
}


#pragma mark - Data extractors

-(BOOL) extractParamsString:(NSString*)string
{
    //NSLog( @"params from string %@", string );
    NSArray *components = [string componentsSeparatedByString:@"&"];
    for( NSString *component in components ) {
        if( [component isEqualToString:@""] ) continue;
        
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        if( [keyValue count] != 2 ) continue;
        if( [keyValue[0] isEqualToString:@""] ) continue;
        
        NSString *unencodedValue = keyValue[1];
        if( ![unencodedValue isEqualToString:@""] )
            unencodedValue = [unencodedValue stringByRemovingPercentEncoding];

        if( params == nil )
            params = [NSMutableDictionary dictionary];
        params[keyValue[0]] = unencodedValue;
    }
    
    return TRUE;
}

-(BOOL) extractParamsJSON:(NSString*)json
{
    //NSLog( @"params from JSON %@", json );
    NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    if( error )
        return FALSE;
    else {
        if( [data isKindOfClass:[NSDictionary class]] ) {
            if( data[@"data"] != nil ) {
                NSArray *items = data[@"data"];
                if( [items isKindOfClass:[NSArray class]] ) {
                    if( params == nil )
                        params = [NSMutableDictionary dictionary];
                    if( params[kDataItemKey] == nil )
                        params[kDataItemKey] = [NSMutableArray array];
                    for( NSDictionary *item in items ) {
                        if( [item isKindOfClass:[NSDictionary class]] )
                            [params[kDataItemKey] addObject:item];
                        else
                            return FALSE;
                    }
                }
                else
                    return FALSE;
            }
            if( data[@"store_receipt"] != nil ) {
                if( params == nil )
                    params = [NSMutableDictionary dictionary];
                params[kReceiptItemKey] = data[@"store_receipt"];
            }
        }
        else
            return FALSE;
    }
    
    return TRUE;
}


-(NSString*) valueForKey:(NSString*)key
{
    return params[key];
}


#pragma mark - Value assertions

-(BOOL) checkIsEmpty
{
    return (params == nil);
}


-(BOOL) checkKeyHasValue:(NSString*)key
{
    return (params[key] != nil);
}

-(BOOL) checkKey:(NSString*)key isEqualToValue:(NSString*)value
{
    return [self checkKeyHasValue:key] && [params[key] isEqualToString:value];
}

-(BOOL) checkAppValues
{
    BOOL retval =
    [self checkKey:@"advertiser_id" isEqualToValue:kTestAdvertiserId] &&
    [self checkKey:@"package_name" isEqualToValue:kTestBundleId] &&
    [self checkKeyHasValue:@"ios_ifv"];
    
    if( !retval )
        NSLog( @"app values failed: %d %d %d", [self checkKey:@"advertiser_id" isEqualToValue:kTestAdvertiserId], [self checkKey:@"package_name" isEqualToValue:kTestBundleId], [self checkKeyHasValue:@"ios_ifv"] );
    
    return retval;
}

-(BOOL) checkSdkValues
{
    BOOL retval =
    [self checkKey:@"sdk" isEqualToValue:@"ios"] &&
    [self checkKeyHasValue:@"ver"];
    
    if( !retval )
        NSLog( @"sdk values failed: %d %d", [self checkKey:@"sdk" isEqualToValue:@"ios"], [self checkKeyHasValue:@"ver"] );
    
    return retval;
}

-(BOOL) checkDeviceValues
{
    BOOL retval =
    [self checkKeyHasValue:@"conversion_user_agent"] &&
    [self checkKeyHasValue:@"country_code"] &&
    [self checkKeyHasValue:@"language"] &&
    [self checkKeyHasValue:@"system_date"] &&
    [self checkKeyHasValue:@"device_brand"] &&
    [self checkKeyHasValue:@"device_model"] &&
    [self checkKeyHasValue:@"os_version"] &&
    [self checkKeyHasValue:@"insdate"] &&
    [self checkKey:@"os_jailbroke" isEqualToValue:@"0"];
    
    if( !retval )
        NSLog( @"device values failed: %d %d %d %d %d %d %d %d %d", [self checkKeyHasValue:@"conversion_user_agent"], [self checkKeyHasValue:@"country_code"], [self checkKeyHasValue:@"language"], [self checkKeyHasValue:@"system_date"], [self checkKeyHasValue:@"device_brand"], [self checkKeyHasValue:@"device_model"], [self checkKeyHasValue:@"os_version"], [self checkKeyHasValue:@"insdate"], [self checkKey:@"os_jailbroke" isEqualToValue:@"0"] );
    
    return retval;
}

-(BOOL) checkDefaultValues
{
    return
    [self checkAppValues] &&
    [self checkSdkValues] &&
    [self checkDeviceValues];
}

-(BOOL) checkDataItems:(NSArray*)items
{
    NSArray *foundItems = params[kDataItemKey];
    if( [items count] != [foundItems count] )
        return FALSE;
    
    for( NSInteger i = 0; i < [foundItems count]; i++ ) {
        NSDictionary *foundItem = foundItems[i];
        MATEventItem *item = items[i];
        if( ![foundItem[@"item"] isEqualToString:item.item] ) {
            NSLog( @"names must be identical: sent '%@' and got '%@'", item.item, foundItem[@"item"] );
            return FALSE;
        }
        NSString *testString = [NSString stringWithFormat:@"%d", item.quantity];
        if( ![foundItem[@"quantity"] isEqualToString:testString] ) {
            NSLog( @"quantities must match: sent %d got %@", item.quantity, foundItem[@"quantity"] );
            return FALSE;
        }
        testString = [NSString stringWithFormat:@"%f", item.unitPrice];
        if( ![foundItem[@"unit_price"] isEqualToString:testString] ) {
            NSLog( @"prices must match: sent %f got %@", item.unitPrice, foundItem[@"unit_price"] );
            return FALSE;
        }
    }
    
    return TRUE;
}

-(BOOL) checkNoDataItems
{
    return (params[kDataItemKey] == nil);
}

-(BOOL) checkReceiptEquals:(NSData*)receiptValue
{
    return [params[kReceiptItemKey] isEqualToString:[MATUtils MATbase64EncodedStringFromData:receiptValue]];
}

@end
