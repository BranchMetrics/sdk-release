//
//  TuneFileUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/4/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneFileUtils.h"
#import "TuneLog.h"
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
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading plist from disk at path: %@", filePathName];
        [TuneLog.shared logError:errorMessage];
        return nil;
    }
    return plist;
}

+ (BOOL)savePropertyList:(id)object filePathName:(NSString *)filePathName plistFormat:(int)plistFormat {
    NSError *error;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:object format:plistFormat options:NSPropertyListWriteInvalidError error:&error];
    if (error != nil) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error saving object to disk as plist to path: %@", filePathName];
        [TuneLog.shared logError:errorMessage];
        return NO;
    }
    
    NSError *writeToFileError = nil;
    BOOL success = [plistData writeToFile:filePathName options:NSDataWritingAtomic error:&writeToFileError];
    if (!success) {
        NSString *errorMessage = [NSString stringWithFormat:@"Failed to write %@ to file.", filePathName];
        [TuneLog.shared logError:errorMessage];
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
        success = NO;
    } else if (![self fileExists:folderPath]) {
        NSError *error;
        success = [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if ( success && !error && [self fileExists:folderPath]) {
            if(!shouldBackup) {
                [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:folderPath]];
            }
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
    return deleted;
}

+ (BOOL)moveFileOrDirectory:(NSString *)fileOrDirectory toFileOrDirectory:(NSString *)toFileOrDirectory {
    NSError *error;
    BOOL moved = [[NSFileManager defaultManager] moveItemAtPath:fileOrDirectory toPath:toFileOrDirectory error:&error];
    return moved;
}

// Refer: http://developer.apple.com/library/ios/#qa/qa1719/_index.html#//apple_ref/doc/uid/DTS40011342
// How do I prevent files from being backed up to iCloud and iTunes?
//
// For iOS versions 5.0.1 and above set a flag to denote that the queue storage files should not be backed up on iCloud.
// No-op for iOS versions 5.0 and below.
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {    
    BOOL success = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) {
        NSError *error = nil;
        success = [URL setResourceValue:@(YES)
                                 forKey:NSURLIsExcludedFromBackupKey
                                  error:&error];
#if DEBUG_LOG
        if(!success) {
            NSString *errorMessage = [NSString stringWithFormat:@"TuneUtils addSkipBackupAttributeToItemAtURL: Error excluding %@ from backup %@", [URL lastPathComponent], error];
            [TuneLog.shared logError:errorMessage];
        }
#endif
    }
    
    return success;
}

@end
