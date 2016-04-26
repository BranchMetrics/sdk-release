//
//  TuneMessageImageBundle.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

@interface TuneMessageImageBundle : NSObject

// This will pull out the screen appropriate image names from the dictionary

// Phone Landscape
@property (strong, nonatomic) UIImage *phoneLandscapeImage;

// Phone Portrait
@property (strong, nonatomic) UIImage *phonePortraitImage;

// Tablet Landscape
@property (strong, nonatomic) UIImage *tabletLandscapeImage;

// Tablet Portrait
@property (strong, nonatomic) UIImage *tabletPortraitImage;


// Pass in the image dictionaries and init will select the screen appropriate (standard,retina) version of the image name
- (id)initWithPhoneLandscape480Dictionary:(NSDictionary *)phoneLandscape480Dictionary
              phoneLandscape568Dictionary:(NSDictionary *)phoneLandscape568Dictionary
               phonePortrait480Dictionary:(NSDictionary *)phonePortrait480Dictionary
               phonePortrait568Dictionary:(NSDictionary *)phonePortrait568Dictionary
                tabletLandscapeDictionary:(NSDictionary *)tabletLandscapeDictionary
                 tabletPortraitDictionary:(NSDictionary *)tabletPortraitDictionary;

- (id)initWithSlideInMessageDictionary:(NSDictionary *)messageDictionary;
- (id)initWithTakeOverMessageDictionary:(NSDictionary *)messageDictionary;

@end
