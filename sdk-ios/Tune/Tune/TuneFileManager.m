//
//  TuneFileManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneManager.h"
#import "TuneModule.h"
#import "TuneSkyhookCenter.h"
#import "TuneConfiguration.h"

static NSObject *_remoteConfigFileLock;
static NSObject *_analyticsFileLock;
static NSObject *_playlistFileLock;
static NSObject *_localConfigFileLock;
static NSObject *_imageFileLock;

NSString *const TUNE_ANALYTICS_FILE_NAME  = @"tune_analytics.plist";
NSString *const TUNE_REMOTE_CONFIG_FILE_NAME     = @"tune_remote_config.plist";
NSString *const TUNE_PLAYLIST_FILE_NAME   = @"tune_playlist.plist";
NSString *const TUNE_LOCAL_CONFIG_FILE_NAME   = @"TuneConfiguration";
NSString *const TUNE_IMAGE_STORAGE_FOLDER  = @"images";
NSString *const TUNE_FILE_STORAGE_FOLDER  = @"tune";

NSUInteger const TUNE_FULL_ANALYTICS_DELETE_COUNT = 10;

@implementation TuneFileManager

#pragma mark - Initialization

+(void)initialize {
    _analyticsFileLock = [[NSObject alloc] init];
    _playlistFileLock = [[NSObject alloc] init];
    _remoteConfigFileLock = [[NSObject alloc] init];
    _localConfigFileLock = [[NSObject alloc] init];
    _imageFileLock = [[NSObject alloc] init];
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
            
            NSNumber *messageStorageLimit = [TuneManager currentManager].configuration.analyticsMessageStorageLimit;
            
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
        ErrorLog(@"Error saving event to path: %@. Exception: %@ Stack: %@", [TuneFileManager getPathToAnalytics], [exception description], [exception callStackSymbols]);
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
        ErrorLog(@"Error saving analytics file at path: %@. Exception: %@ Stack: %@", [TuneFileManager getPathToAnalytics], [exception description], [exception callStackSymbols]);
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
        ErrorLog(@"Error deleting analytics events (by saving over old) at path: %@. Exception: %@ Stack: %@", [TuneFileManager getPathToAnalytics], [exception description], [exception callStackSymbols]);
    } @finally {
        return returnCode;
    }
}

+ (BOOL)deleteAnalyticsFromDisk {
    return [TuneFileManager deleteDictionaryAtPath:[TuneFileManager getPathToAnalytics] withFileLock:_analyticsFileLock];
}

#pragma mark - Remote Configuration File Management

+ (NSDictionary *)loadRemoteConfigurationFromDisk {
    return [TuneFileManager loadDictionaryAtPath:[TuneFileManager getRemoteConfigurationFilePath] withFileLock:_remoteConfigFileLock];
}

+ (BOOL)saveRemoteConfigurationToDisk:(NSDictionary*)config {
    return [TuneFileManager saveDictionary:config toPath:[TuneFileManager getRemoteConfigurationFilePath] withFileLock:_remoteConfigFileLock];
}

+ (BOOL)deleteRemoteConfigurationFromDisk {
    return [TuneFileManager deleteDictionaryAtPath:[TuneFileManager getRemoteConfigurationFilePath] withFileLock:_remoteConfigFileLock];
}

#pragma mark - Local Configuration File Management

+ (NSDictionary *)loadLocalConfigurationFromDisk {
    return [TuneFileManager loadDictionaryAtPath:[TuneFileManager getLocalConfigurationPath] withFileLock:_localConfigFileLock];
}

#pragma mark - Playlist File Management

+ (NSDictionary *)loadPlaylistFromDisk {
    return [TuneFileManager loadDictionaryAtPath:[TuneFileManager getPlaylistFilePath] withFileLock:_playlistFileLock];
}

+ (BOOL)savePlaylistToDisk:(TunePlaylist *)playlist {
    return [TuneFileManager saveDictionary:playlist.toDictionary toPath:[TuneFileManager getPlaylistFilePath] withFileLock:_playlistFileLock];
}

+ (BOOL)deletePlaylistFromDisk {
    return [TuneFileManager deleteDictionaryAtPath:[TuneFileManager getPlaylistFilePath] withFileLock:_playlistFileLock];
}

#pragma mark - Image File Management

+ (UIImage *)loadImageFromDiskNamed:(NSString *)name {
    UIImage *result = nil;
    NSString *imagePath = [TuneFileManager getImageFilePathForImageNamed:name];
    @try {
        @synchronized(_imageFileLock) {
            if ([TuneFileUtils fileExists:imagePath]) {
                result = [TuneFileUtils loadImageAtPath:imagePath];
            }
        }
    } @catch (NSException *exception) {
        ErrorLog(@"Error loading image at path: %@. Exception: %@ Stack: %@", imagePath, [exception description], [exception callStackSymbols]);
    } @finally {
        return result;
    }
}

+ (BOOL)saveImageData:(NSData *)data toDiskWithName:(NSString *)name {
    [TuneFileUtils createDirectory:[self getImageStorageDirectory]];
    
    BOOL returnCode = NO;
    NSString *imagePath = [TuneFileManager getImageFilePathForImageNamed:name];
    @try {
        @synchronized(_imageFileLock) {
            returnCode = [TuneFileUtils saveImageData:data toPath:imagePath];
        }
    } @catch (NSException *exception) {
        ErrorLog(@"Error saving image to path: %@. Exception: %@ Stack: %@", imagePath, [exception description], [exception callStackSymbols]);
    } @finally {
        return returnCode;
    }
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
        ErrorLog(@"Error loading file at path: %@. Exception: %@ Stack: %@", path, [exception description], [exception callStackSymbols]);
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
        ErrorLog(@"Error saving file at path: %@. Exception: %@ Stack: %@", path, [exception description], [exception callStackSymbols]);
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
        ErrorLog(@"Error deleting file at path: %@. Exception: %@ Stack: %@", path, [exception description], [exception callStackSymbols]);
    } @finally {
        return returnCode;
    }
}

#pragma mark - File Paths

+ (NSString *)getPathToAnalytics {
    return [[self getStorageDirectory] stringByAppendingPathComponent:TUNE_ANALYTICS_FILE_NAME];
}
    
+ (NSString *)getRemoteConfigurationFilePath {
    return [[self getStorageDirectory] stringByAppendingPathComponent:TUNE_REMOTE_CONFIG_FILE_NAME];
}

+ (NSString *)getPlaylistFilePath {
    return [[self getStorageDirectory] stringByAppendingPathComponent:TUNE_PLAYLIST_FILE_NAME];
}

+ (NSString *)getLocalConfigurationPath {
    return [[NSBundle bundleForClass:[self class]] pathForResource:TUNE_LOCAL_CONFIG_FILE_NAME ofType:@"plist"];
}

+ (NSString *)getImageFilePathForImageNamed:(NSString *)name {
    return [[TuneFileManager getImageStorageDirectory] stringByAppendingPathComponent:name];
}

#pragma mark - Storage Directory

+ (NSString *)getStorageDirectory {
    static NSString *storageDirectory = nil;
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

+ (NSString *)getImageStorageDirectory {
    return [[self getStorageDirectory] stringByAppendingPathComponent:TUNE_IMAGE_STORAGE_FOLDER];
}

@end
