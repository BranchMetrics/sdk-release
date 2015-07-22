//
//  TuneAdMetadata.h
//  Tune
//
//  Created by Harshal Ogale on 11/14/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/** @name Gender type constants */
typedef NS_ENUM(NSInteger, TuneGender)
{
    TuneGenderMale       = 0,                // Gender type MALE. Equals 0.
    TuneGenderFemale     = 1,                // Gender type FEMALE. Equals 1.
    TuneGenderUnknown    = 2
};


/*!
 Properties to be included when requesting ads for an ad view
 */
@interface TuneAdMetadata : NSObject <NSCopying>

/*!
 User birthdate.
 */
@property (nonatomic, copy) NSDate *birthDate;

/*!
 Keywords describing the current app for use by the ad server
 */
@property (nonatomic, copy) NSArray *keywords;

/*!
 Key-value pairs to be used by the ad targeting expressions on the server
 */
@property (nonatomic, copy) NSDictionary *customTargets;

/*!
 Gender to be targeted by the ads. Defaults to TuneGenderUnknown.
 */
@property (nonatomic, assign) TuneGender gender;

/*!
 Latitude part of the location (latitude, logitude, altitude) to be targeted by the ads
 */
@property (nonatomic, assign) CGFloat latitude;

/*!
 Longitude part of the location (latitude, logitude, altitude) to be targeted by the ads
 */
@property (nonatomic, assign) CGFloat longitude;

/*!
 Altitude part of the location (latitude, logitude, altitude) to be targeted by the ads
 */
@property (nonatomic, assign) CGFloat altitude;

/*!
 Ad view debug mode status
 */
@property (nonatomic, assign) BOOL debugMode;

@end
