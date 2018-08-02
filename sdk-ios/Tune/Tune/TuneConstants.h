//
//  TuneConstants.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 12/2/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef TuneConstants_h
#define TuneConstants_h

#pragma mark - enumerated types

/** Error codes. */
typedef NS_ENUM(NSInteger, TuneErrorCode)
{
    /**
     Error code when no advertiser ID is provided.
     */
    TuneNoAdvertiserIDProvided          = 1101,
    /**
     Error code when no conversion key is provided.
     */
    TuneNoConversionKeyProvided         = 1102,
    /**
     Error code when an invalid conversion key is provided.
     */
    TuneInvalidConversionKey            = 1103,
    /**
     Error code when an event request has failed.
     */
    TuneServerErrorResponse             = 1111,
    /**
     Error code when an event's name is empty, or when attempting to measure a "close" event.
     */
    TuneInvalidEvent                    = 1131,
    /**
     Error code when an invalid Advertiser Id or Tune Conversion Key is used.
     */
    TuneMeasurementWithoutInitializing  = 1132,
    /**
     Error code when there are duplicate "session" event measurements calls in the same session.
     */
    TuneInvalidDuplicateSession         = 1133
};

/** Gender type constants. */
typedef NS_ENUM(NSInteger, TuneGender)
{
    /**
     Gender type MALE. Equals 0.
     */
    TuneGenderMale       = 0,
    /**
     Gender type FEMALE. Equals 1.
     */
    TuneGenderFemale     = 1,
    /**
     Gender type UNKNOWN. Equals 2.
     */
    TuneGenderUnknown    = 2
};


#endif /* TuneConstants_h */

