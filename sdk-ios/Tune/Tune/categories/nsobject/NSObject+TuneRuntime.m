//
//  NSObject+ArtisanRuntime.m
//  ARUXFLIP
//
//  Created by Michael Raber on 11/18/13.
//
//

#import "NSObject+ArtisanRuntime.h"
#import <objc/runtime.h>
#import "ArtisanSkyHookCenter.h"

@implementation NSObject (ArtisanRuntime)

+ (NSString *)artisanNameSpace {
  if([self respondsToSelector:@selector(_artisanNameSpace)]){
    NSString *nameSpace = [self performSelector:@selector(_artisanNameSpace)];
    
    if(nameSpace==nil) return @"";
    
    return nameSpace;
  }
  
  return @"";
}

@end
