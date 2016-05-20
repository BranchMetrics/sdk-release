//
//  TuneFileUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/4/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneFileUtils.h"
#import "TuneUtils.h"

NSString *const TuneFileUtilsConfigDirectory = @"Library/Caches/";
NSString *const TuneFileUtilsConfigFileName = @"tune.plist";

@implementation TuneFileUtils

#pragma mark - Property List

+ (id)loadPropertyList:(NSString *)filePathName {
    return [[self class] loadPropertyList:filePathName mutabilityOption:NSPropertyListImmutable];
}

+ (id)loadPropertyList:(NSString *)filePathName mutabilityOption:(NSPropertyListMutabilityOptions)opt {
    NSData *plistData = [NSData dataWithContentsOfFile:filePathName];
    if (!plistData) { return nil; }

    NSError *error;
    id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:&error];
    if (error) {
        ErrorLog(@"Error loading plist from disk at path: %@", filePathName);
        return nil;
    }
    return plist;
}

+ (BOOL)savePropertyList:(id)object filePathName:(NSString *)filePathName plistFormat:(int)plistFormat {
    NSError *error;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:object format:plistFormat options:NSPropertyListWriteInvalidError error:&error];
    if (error != nil) {
        ErrorLog(@"Error saving object to disk as plist to path: %@", filePathName);
        return NO;
    }
    
    NSError *writeToFileError = nil;
    BOOL success = [plistData writeToFile:filePathName options:NSDataWritingAtomic error:&writeToFileError];
    if (!success) {
        ErrorLog(@"Failed to write %@ to file.", filePathName);
    }
    
    return success;
}

#pragma mark - Data

+ (UIImage *)loadImageAtPath:(NSString *)path {
    return [UIImage imageWithContentsOfFile:path];
}

+ (BOOL)saveImageData:(NSData *)data toPath:(NSString *)path {
    NSError *error = nil;
    BOOL success = [data writeToFile:path options:NSDataWritingAtomic error:&error];
    if (!success) {
        ErrorLog(@"Failed to write image %@ to file. Error: %@", path, [error description]);
    }
    return success;
}

#pragma mark - File Management

+ (BOOL)createDirectory:(NSString *)folderPath {
    return [self createDirectory:folderPath backup:NO];
}

+ (BOOL)createDirectory:(NSString *)folderPath backup:(BOOL)shouldBackup {
    BOOL success = YES;
    
    if (nil == folderPath) {
        DebugLog(@"Attempting to create directory with nil string.");
        success = NO;
    } else if (![self fileExists:folderPath]) {
        NSError *error;
        success = [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if ( success && !error && [self fileExists:folderPath]) {
            if(!shouldBackup) {
                [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:folderPath]];
            }
        } else {
            DebugLog(@"Error creating directory at %@", folderPath);
        }
    }
    
    return success;
}

+ (BOOL)fileExists:(NSString *)filePath {
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+ (BOOL)deleteFileOrDirectory:(NSString *)fileOrDirectory {
    NSError *error;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:fileOrDirectory error:&error];
    
    if (!deleted) {
        DebugLog(@"Failed to delete file '%@', %@", fileOrDirectory, error);
    }
    
    return deleted;
}

+ (BOOL)moveFileOrDirectory:(NSString *)fileOrDirectory toFileOrDirectory:(NSString *)toFileOrDirectory {
    NSError *error;
    BOOL moved = [[NSFileManager defaultManager] moveItemAtPath:fileOrDirectory toPath:toFileOrDirectory error:&error];
    
    if (!moved) {
        DebugLog(@"failed to move file from '%@' to '%@', %@", fileOrDirectory, toFileOrDirectory, error);
    }
    
    return moved;
}

// Refer: http://developer.apple.com/library/ios/#qa/qa1719/_index.html#//apple_ref/doc/uid/DTS40011342
// How do I prevent files from being backed up to iCloud and iTunes?
//
// For iOS versions 5.0.1 and above set a flag to denote that the queue storage files should not be backed up on iCloud.
// No-op for iOS versions 5.0 and below.
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
    DebugLog(@"TuneUtils addSkipBackupAttributeToItemAtURL: %@", URL);
    
    BOOL success = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) {
        NSError *error = nil;
        success = [URL setResourceValue:@(YES)
                                 forKey:NSURLIsExcludedFromBackupKey
                                  error:&error];
#if DEBUG_LOG
        if(!success) {
            NSLog(@"TuneUtils addSkipBackupAttributeToItemAtURL: Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
#endif
    }
    
    return success;
}

+ (NSString *)pathToConfiguration {
    NSString *configFullDirectory = [NSHomeDirectory() stringByAppendingPathComponent:TuneFileUtilsConfigDirectory];
    NSString *configFileName = [configFullDirectory stringByAppendingPathComponent:TuneFileUtilsConfigFileName];
    return configFileName;
}

@end
