//
//  TuneFileManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneLog.h"
#import "TuneManager.h"
#import "TuneModule.h"
#import "TuneSkyhookCenter.h"
#import "TuneConfiguration.h"
#import "TuneUtils.h"

static NSObject *_analyticsFileLock;

NSString *const TUNE_ANALYTICS_FILE_NAME  = @"tune_analytics.plist";
// Stuff to delete!
//NSString *const TUNE_REMOTE_CONFIG_FILE_NAME     = @"tune_remote_config.plist";
//NSString *const TUNE_PLAYLIST_FILE_NAME   = @"tune_playlist.plist";
//NSString *const TUNE_LOCAL_CONFIG_FILE_NAME   = @"TuneConfiguration";
//NSString *const TUNE_IMAGE_STORAGE_FOLDER  = @"images";
NSString *const TUNE_FILE_STORAGE_FOLDER  = @"tune";

NSUInteger const TUNE_FULL_ANALYTICS_DELETE_COUNT = 10;

@implementation TuneFileManager

#pragma mark - Initialization

+(void)initialize {
    _analyticsFileLock = [[NSObject alloc] init];
}

#pragma mark - Analytics Storage File Management

+ (NSDictionary *)loadAnalyticsFromDisk {
    return [TuneFileManager loadDictionaryAtPath:[TuneFileManager getPathToAnalytics] withFileLock:_analyticsFileLock];
}

+ (BOOL)saveAnalyticsEventToDisk:(NSString *)eventJSON withId:(NSString *)eventId {
    BOOL returnCode = YES;
    
    @try {
        NSMutableDictionary *currentAnalytics = nil;
        [TuneFileUtils createDirectory:[self getStorageDirectory]];
        
        @synchronized(_analyticsFileLock){
            // Load the latest edition of the file
            if ([TuneFileUtils fileExists:[TuneFileManager getPathToAnalytics]]) {
                currentAnalytics = [[TuneFileUtils loadPropertyList:[TuneFileManager getPathToAnalytics]] mutableCopy];
            }
            
            NSNumber *messageStorageLimit = TuneConfiguration.sharedConfiguration.analyticsMessageStorageLimit;
            
            // Check if the file is empty or over the size limit.
            if (currentAnalytics == nil) {
                currentAnalytics = [[NSMutableDictionary alloc] init];
            } else if (([currentAnalytics count] > TUNE_FULL_ANALYTICS_DELETE_COUNT) && messageStorageLimit && ([NSNumber numberWithUnsignedInteger:[currentAnalytics count]] >= messageStorageLimit)) {
                
                // We're over the size limit, so delete the x oldest messages (as sorted from their timestamp-based keys)
                NSArray *deleteArray = [[[currentAnalytics allKeys] sortedArrayUsingSelector: @selector(compare:)] subarrayWithRange:NSMakeRange(0, TUNE_FULL_ANALYTICS_DELETE_COUNT)];
                for (NSString *deleteKey in deleteArray) {
                    [currentAnalytics removeObjectForKey:deleteKey];
                }
            }
            
            // Add the new message and save it.
            [currentAnalytics setObject:eventJSON forKey:eventId];
            returnCode = [TuneFileUtils savePropertyList:currentAnalytics
                                            filePathName:[TuneFileManager getPathToAnalytics]
                                             plistFormat:NSPropertyListXMLFormat_v1_0];
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat: @"Error saving event to path: %@. Exception: %@ Stack: %@", [TuneFileManager getPathToAnalytics], [exception description], [exception callStackSymbols]];
        [TuneLog.shared logError:errorMessage];
        
    } @finally {
        return returnCode;
    }
}

+ (BOOL)saveAnalyticsToDisk:(NSDictionary *)analytics {
    BOOL returnCode = YES;
    
    @try {
        [TuneFileUtils createDirectory:[self getStorageDirectory]];
        
        NSDictionary *dictionaryCopy = analytics;
        @synchronized(_analyticsFileLock) {
            returnCode = [TuneFileUtils savePropertyList:dictionaryCopy
                                            filePathName:[TuneFileManager getPathToAnalytics]
                                             plistFormat:NSPropertyListXMLFormat_v1_0];
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat: @"Error saving analytics file at path: %@. Exception: %@ Stack: %@", [TuneFileManager getPathToAnalytics], [exception description], [exception callStackSymbols]];
        [TuneLog.shared logError:errorMessage];
    } @finally {
        return returnCode;
    }
}

+ (BOOL)deleteAnalyticsEventsFromDisk:(NSArray *)eventsToDelete {
    BOOL returnCode = YES;
    NSMutableDictionary *currentAnalytics = nil;
    
    @try {
        @synchronized(_analyticsFileLock) {
            // Load the latest edition of the file and remove the target events.
            if ([TuneFileUtils fileExists:[TuneFileManager getPathToAnalytics]]) {
                currentAnalytics = [TuneFileUtils loadPropertyList:[TuneFileManager getPathToAnalytics]];
                
                for (NSString *eventIdToDelete in eventsToDelete) {
                    [currentAnalytics removeObjectForKey:eventIdToDelete];
                }
                
                returnCode = [TuneFileUtils savePropertyList:currentAnalytics
                                                filePathName:[TuneFileManager getPathToAnalytics]
                                                 plistFormat:NSPropertyListXMLFormat_v1_0];
            }
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat: @"Error deleting analytics events (by saving over old) at path: %@. Exception: %@ Stack: %@", [TuneFileManager getPathToAnalytics], [exception description], [exception callStackSymbols]];
        [TuneLog.shared logError:errorMessage];
    } @finally {
        return returnCode;
    }
}

+ (BOOL)deleteAnalyticsFromDisk {
    return [TuneFileManager deleteDictionaryAtPath:[TuneFileManager getPathToAnalytics] withFileLock:_analyticsFileLock];
}

#pragma mark - Helpers

+ (NSDictionary *)loadDictionaryAtPath:(NSString *)path withFileLock:(NSObject *)fileLock {
    NSDictionary *dictionary;
    
    @try {
        @synchronized(fileLock){
            if ([TuneFileUtils fileExists:path]) {
                dictionary = [TuneFileUtils loadPropertyList:path];
            }
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat: @"Error loading file at path: %@. Exception: %@ Stack: %@", path, [exception description], [exception callStackSymbols]];
        [TuneLog.shared logError:errorMessage];
    } @finally {
        return dictionary;
    }
}

+ (BOOL)saveDictionary:(NSDictionary *)dictionary toPath:(NSString *)path withFileLock:(NSObject *)fileLock {
    BOOL returnCode = YES;
    [TuneFileUtils createDirectory:[self getStorageDirectory]];
    
    @try {
        @synchronized(fileLock){
            returnCode = [TuneFileUtils savePropertyList:dictionary
                                            filePathName:path
                                             plistFormat:NSPropertyListXMLFormat_v1_0];
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat: @"Error saving file at path: %@. Exception: %@ Stack: %@", path, [exception description], [exception callStackSymbols]];
        [TuneLog.shared logError:errorMessage];
    } @finally {
        return returnCode;
    }
}

+ (BOOL)deleteDictionaryAtPath:(NSString *)path withFileLock:(NSObject *)fileLock {
    BOOL returnCode = YES;
    
    @try {
        @synchronized(fileLock){
            if ([TuneFileUtils fileExists:path]) {
                returnCode = [TuneFileUtils deleteFileOrDirectory:path];
            }
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat: @"Error deleting file at path: %@. Exception: %@ Stack: %@", path, [exception description], [exception callStackSymbols]];
        [TuneLog.shared logError:errorMessage];
    } @finally {
        return returnCode;
    }
}

#pragma mark - File Paths

+ (NSString *)getPathToAnalytics {
    return [[self getStorageDirectory] stringByAppendingPathComponent:TUNE_ANALYTICS_FILE_NAME];
}

#pragma mark - Storage Directory

+ (NSString *)getStorageDirectory {
    // migrate old queue directory
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self moveOldQueueStorageDirectoryToTemp];
    });
    
    return [self tuneTmpDirectory];
}

+ (NSString *)tuneTmpDirectory {
    return [NSTemporaryDirectory() stringByAppendingString:TUNE_FILE_STORAGE_FOLDER];
}

// SDK-231 legacy code, only used for data migration
+ (NSString *)oldStorageDirectory {
    NSString *storageDirectory = nil;
    if (!storageDirectory) {
        NSSearchPathDirectory storageParentFolder = NSDocumentDirectory;
        
#if TARGET_OS_TV // || TARGET_OS_WATCH
        storageParentFolder = NSCachesDirectory;
#endif
        NSArray *paths = NSSearchPathForDirectoriesInDomains(storageParentFolder, NSUserDomainMask, YES);
        NSString *baseFolder = [paths objectAtIndex:0];
        
        storageDirectory = [baseFolder stringByAppendingPathComponent:TUNE_FILE_STORAGE_FOLDER];
    }
    
    return storageDirectory;
}

// SDK-231 move queue storage to the temp directory
// old queue storage is in the documents directory, this is against Apple's data storage guidelines
// https://developer.apple.com/icloud/documentation/data-storage/index.html
+ (void)moveOldQueueStorageDirectoryToTemp {
    NSString *oldDirectory = [self oldStorageDirectory];
    NSString *newDirectory = [self tuneTmpDirectory];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *error;
    NSArray *files = [fm contentsOfDirectoryAtPath:oldDirectory error:&error];
    
    for (NSString *file in files) {
        [fm moveItemAtPath:[oldDirectory stringByAppendingPathComponent:file] toPath:[newDirectory stringByAppendingPathComponent:file] error:&error];
    }
    [fm removeItemAtPath:oldDirectory error:&error];
}

@end
