//
//  TuneDebugUtilities.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 8/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Utilities to help with debuging and testing.
 */
@interface TuneDebugUtilities : NSObject

/**
 Specifies that the server responses should include debug information.

 @warning This is only for testing. You must turn this off for release builds.

 @param enable defaults to NO.
 */
+ (void)setDebugMode:(BOOL)enable;

/**
 Sets the status of the user in the given segment, for testing [Tune isUserInSegmentId:] or [Tune isUserInAnySegmentIds:]
 Only affects segment status locally, for testing. Does not update segments server-side.

 @warning This is only for testing. You must turn this off for release builds.

 @param isInSegment Status to modify of whether user is in the segment
 @param segmentId Segment to modify status for
 */
+ (void)forceSetUserInSegment:(BOOL)isInSegment forSegmentId:(NSString *)segmentId;

@end
