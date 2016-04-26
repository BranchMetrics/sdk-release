//
//  TunePlaylistPlayer.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/20/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneJSONPlayer : NSObject {
    NSInteger counter;
}

@property (nonatomic, copy) NSArray *files;

- (NSDictionary *)getNext;
- (void)setFiles:(NSArray *)filenames;

@end
