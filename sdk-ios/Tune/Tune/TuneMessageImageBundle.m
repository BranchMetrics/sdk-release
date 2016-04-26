//
//  TuneMessageImageBundle.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageImageBundle.h"
#import "TuneDeviceDetails.h"
#import "TuneInAppUtils.h"

@implementation TuneMessageImageBundle

- (id)initWithPhoneLandscape480Dictionary:(NSDictionary *)phoneLandscape480Dictionary
              phoneLandscape568Dictionary:(NSDictionary *)phoneLandscape568Dictionary
               phonePortrait480Dictionary:(NSDictionary *)phonePortrait480Dictionary
               phonePortrait568Dictionary:(NSDictionary *)phonePortrait568Dictionary
                tabletLandscapeDictionary:(NSDictionary *)tabletLandscapeDictionary
                 tabletPortraitDictionary:(NSDictionary *)tabletPortraitDictionary {
    
    self = [super init];
    
    if(self)
    {
        if ([TuneDeviceDetails runningOnPhone]) {
            if ([TuneDeviceDetails appSupportsLandscape]) {
                if ([TuneDeviceDetails runningOn480HeightPhone] && phoneLandscape480Dictionary != nil) {
                    self.phoneLandscapeImage = [TuneInAppUtils getScreenAppropriateImageFromDictionary:phoneLandscape480Dictionary];
                }
                else {
                    if (phoneLandscape568Dictionary != nil) {
                        self.phoneLandscapeImage = [TuneInAppUtils getScreenAppropriateImageFromDictionary:phoneLandscape568Dictionary];
                    }
                }
            }
            
            if ([TuneDeviceDetails appSupportsPortrait]) {
                if ([TuneDeviceDetails runningOn480HeightPhone] && phonePortrait480Dictionary != nil) {
                    self.phonePortraitImage = [TuneInAppUtils getScreenAppropriateImageFromDictionary:phonePortrait480Dictionary];
                }
                else {
                    if (phonePortrait568Dictionary != nil) {
                        self.phonePortraitImage = [TuneInAppUtils getScreenAppropriateImageFromDictionary:phonePortrait568Dictionary];
                    }
                }
            }
        }
        else {
            if ([TuneDeviceDetails appSupportsLandscape] && tabletLandscapeDictionary != nil) {
                self.tabletLandscapeImage = [TuneInAppUtils getScreenAppropriateImageFromDictionary:tabletLandscapeDictionary];
            }
            if ([TuneDeviceDetails appSupportsPortrait] && tabletPortraitDictionary != nil) {
                self.tabletPortraitImage = [TuneInAppUtils getScreenAppropriateImageFromDictionary:tabletPortraitDictionary];
            }
        }
    }
    return self;
}

- (id)initWithSlideInMessageDictionary:(NSDictionary *)messageDictionary {
    return [self initWithPhoneLandscape480Dictionary:messageDictionary[@"phoneLandscapeBackgroundImage-480"]
                         phoneLandscape568Dictionary:messageDictionary[@"phoneLandscapeBackgroundImage-568"]
                          phonePortrait480Dictionary:messageDictionary[@"phonePortraitBackgroundImage"]
                          phonePortrait568Dictionary:messageDictionary[@"phonePortraitBackgroundImage"]
                           tabletLandscapeDictionary:messageDictionary[@"tabletLandscapeBackgroundImage"]
                            tabletPortraitDictionary:messageDictionary[@"tabletPortraitBackgroundImage"]];
}

- (id)initWithTakeOverMessageDictionary:(NSDictionary *)messageDictionary {
    return [self initWithPhoneLandscape480Dictionary:messageDictionary[@"phoneLandscapeBackgroundImage-480"]
                         phoneLandscape568Dictionary:messageDictionary[@"phoneLandscapeBackgroundImage-568"]
                          phonePortrait480Dictionary:messageDictionary[@"phonePortraitBackgroundImage-480"]
                          phonePortrait568Dictionary:messageDictionary[@"phonePortraitBackgroundImage-568"]
                           tabletLandscapeDictionary:messageDictionary[@"tabletLandscapeBackgroundImage"]
                            tabletPortraitDictionary:messageDictionary[@"tabletPortraitBackgroundImage"]];
}

@end
