//
//  NSString+MATURLEncoding.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/17/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "NSString+MATURLEncoding.h"

@implementation NSString (MATURLEncoding)

- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                (CFStringRef)self,
                                                                NULL,
                                                                (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}

@end