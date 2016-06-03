//
//  TunePlaylistPlayer.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/20/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneJSONPlayer.h"
#import "TuneJSONUtils.h"

@implementation TuneJSONPlayer

- (id)init {
    self = [super init];
    if (self) {
        counter = -1;
        self.files = @[]; // start with an empty array
    }
    return self;
}

-(void)setFiles:(NSArray *)filenames {
    if(filenames==nil) {
        filenames = @[];
    }
    
    _files = [self buildArrayWithFilenames:filenames];
}

-(void)incrementDownload {
    if([self.files count] > 0){
        if (counter + 1 < [self.files count]) {
            counter++;
        }
    }
}

-(NSDictionary *)getNext {
    [self incrementDownload];
    return self.files[counter];
}

#pragma mark - Helpers

-(NSArray *)buildArrayWithFilenames:(NSArray *)filenames {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSString *filename in filenames) {
        NSDictionary *dictionary = [self getDictionaryFromJSONFile:filename];
        [array addObject:dictionary];
    }
    return [NSArray arrayWithArray:array];
}

-(NSDictionary *)getDictionaryFromJSONFile:(NSString *)filename {
    NSString *updateFilename = [filename substringToIndex:([filename length] -5)];
    NSString *path = [[NSBundle mainBundle] pathForResource:updateFilename ofType:@"json"];
    NSString *JSON = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *messageDictionary = [TuneJSONUtils createDictionaryFromJSONString:JSON];
    return messageDictionary;
}

@end
