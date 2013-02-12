//
//  NSString+MATURLEncoding.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/17/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MATURLEncoding)

- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;

@end