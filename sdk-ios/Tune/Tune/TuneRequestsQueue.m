//
//  TuneRequestsQueue.m
//  Tune
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "TuneRequestsQueue.h"

#import "TuneKeyStrings.h"
#import "TuneRequestsQueuePart.h"
#import "TuneUtils.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneFileUtils.h"

NSString * const TUNE_REQUEST_QUEUE_FOLDER = @"queue";
NSString * const XML_FILE_NAME = @"queue_parts_descs.xml";

NSString * const XML_NODE_PART = @"Part";
NSString * const XML_NODE_PARTS = @"Parts";

NSString * const XML_NODE_ATTRIBUTE_INDEX = @"index";
NSString * const XML_NODE_ATTRIBUTE_REQUESTS = @"requests";

@interface TuneRequestsQueue()

@property (nonatomic, retain) NSMutableArray * queueParts;
@property (nonatomic, retain) NSString *pathStorageDir, *pathStorageFile, *pathOld;

@end


@implementation TuneRequestsQueue

@synthesize queueParts = queueParts_;
@synthesize pathOld, pathStorageDir, pathStorageFile;

@dynamic queuedRequestsCount;

#pragma mark - Custom Setters

- (NSUInteger)queuedRequestsCount {
    NSUInteger count = 0;
    
    for (TuneRequestsQueuePart *part in queueParts_) {
        count += part.queuedRequestsCount;
    }
    
    return count;
}

#pragma mark - Lifecycle Management

- (id)init {
    self = [super init];
    
    if (self) {
        self.queueParts = [NSMutableArray array];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *baseFolder = [paths objectAtIndex:0];
        
        DebugLog(@"TuneReqQue: init: storage dir  = %@", self.pathStorageDir);
        DebugLog(@"TuneReqQue: init: storage file = %@", self.pathStorageFile);
        
        self.pathStorageDir = [baseFolder stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FOLDER];
        self.pathStorageFile = [self.pathStorageDir stringByAppendingPathComponent:XML_FILE_NAME];
        
        DebugLog(@"TuneReqQue: init: systemVersion = %f", [TuneUtils numericiOSSystemVersion]);
        DebugLog(@"TuneReqQue: init: pathStorageDir = %@, exists = %d", pathStorageDir, [[NSFileManager defaultManager] fileExistsAtPath:pathStorageDir]);
        DebugLog(@"TuneReqQue: init: pathStorageFile = %@", pathStorageFile);
        
        // make sure that the queue storage folder exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.pathStorageDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.pathStorageDir withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        DebugLog(@"TuneReqQue: init: pathOld = %@", self.pathOld);
        
        [self fixForiCloud];
    }
    
    return self;
}

- (void)closedown {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.pathStorageFile]) {
        // delete the legacy queue storage file
        [[NSFileManager defaultManager] removeItemAtPath:self.pathStorageFile error:nil];
    }
    
    // Note: We do not remove the legacy "queue" folder,
    // being a generic folder name, the client app may
    // be using "queue" folder for some other purpose.
}

- (NSString*)description {
    return [NSString stringWithFormat:@"queue with %lu items, %lu parts", (unsigned long)[queueParts_ count], (unsigned long)[self queuedRequestsCount]];
}

#pragma mark - Queue Helper Methods

- (TuneRequestsQueuePart*)getLastPart {
    @synchronized( queueParts_ ) {
        // if queue parts exist then return the last queue part
        return [queueParts_ count] > 0 ? [queueParts_ lastObject] : nil;
    }
}

- (TuneRequestsQueuePart*)getFirstPart {
    @synchronized( queueParts_ ) {
        // if queue parts exist then return the first queue part
        return [queueParts_ count] > 0 ? [queueParts_ objectAtIndex:0] : nil;
    }
}

- (TuneRequestsQueuePart*)addNewPart {
    DebugLog(@"TuneReqQue: addNewPart: pathStorageDir = %@", self.pathStorageDir);
    
    @synchronized( queueParts_ ) {
        TuneRequestsQueuePart * part = [TuneRequestsQueuePart partWithIndex:[self getSmallestPartFreeIndex] parentFolder:self.pathStorageDir];
        [queueParts_ addObject:part];

        return part;
    }
}

- (BOOL)removePart:(TuneRequestsQueuePart*)part {
    if (!part) return NO;
    
    DebugLog(@"TuneReqQue: removePart: partToRemove = %@", part.filePathName);
    
    @synchronized( queueParts_ ) {
        [[NSFileManager defaultManager] removeItemAtPath:part.filePathName error:nil];
        [queueParts_ removeObject:part];
    }

    return YES;
}

- (NSUInteger)getSmallestPartFreeIndex {
    @synchronized( queueParts_ ) {
        NSUInteger indexFree = 0;
        for (TuneRequestsQueuePart * part in queueParts_)
            if (part.index == indexFree) {
                ++indexFree;
            } else {
                break;
            }
        
        return indexFree;
    }
}

- (void)push:(NSDictionary*)object {
    TuneRequestsQueuePart * lastPart = [self getLastPart];
    if (!lastPart || lastPart.requestsLimitReached)
        lastPart = [self addNewPart];

#if DEBUG_LOG
    NSLog(@"TuneReqQue: push: %@", object);
    BOOL pushSuccessful =
#endif
    [lastPart push:object];
        
#if DEBUG_LOG
    NSLog(@"TuneReqQue: push: successful = %d", pushSuccessful);
        
    NSString* content = [NSString stringWithContentsOfFile:lastPart.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSLog(@"TuneReqQue: push: path = %@", lastPart.filePathName);
    NSLog(@"TuneReqQue: push: content = %@", content);
#endif
}

- (void)pushToHead:(NSDictionary*)object {
    TuneRequestsQueuePart * lastPart = [self getLastPart];
    if (!lastPart || lastPart.requestsLimitReached)
        lastPart = [self addNewPart];

#if DEBUG_LOG
    NSLog(@"TuneReqQue: pushToHead: %@", object);
    BOOL pushSuccessful =
#endif
    [lastPart pushToHead:object];
        
#if DEBUG_LOG
    NSLog(@"TuneReqQue: pushToHead: successful = %d", pushSuccessful);
        
    NSString* content = [NSString stringWithContentsOfFile:lastPart.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSLog(@"TuneReqQue: pushToHead: path = %@", lastPart.filePathName);
    NSLog(@"TuneReqQue: pushToHead: content = %@", content);
#endif
}

- (NSDictionary*)pop {
    NSDictionary * object = nil;

    DebugLog(@"TuneReqQue: pop: start");
    
    TuneRequestsQueuePart * firstPart = [self getFirstPart];
    if (firstPart) {
        object = [firstPart pop];
        DebugLog(@"TuneReqQue: pop: pass1: %@,\nfirstPart isEmpty = %d", object, firstPart.empty);
        if (firstPart.empty)
            [self removePart:firstPart];
    }
    
    DebugLog(@"TuneReqQue: pop: end: %@", object);
    return object;
}

- (void)save {
    DebugLog(@"TuneReqQue: save: %@", self.pathStorageFile);
    
    /// Save parts description file
    NSString * filePath = self.pathStorageFile;
    
    NSMutableString *strDescr = [NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@>", XML_NODE_PARTS];
    
    @synchronized( queueParts_ ) {
        for (TuneRequestsQueuePart *part in queueParts_) {
            /// If part is modified save it to file
            if (part.isModified)
                [part save];
            
            /// Store its information
            [strDescr appendFormat:@"<%@ %@=\"%ld\" %@=\"%lu\"></%@>", XML_NODE_PART, XML_NODE_ATTRIBUTE_INDEX, (long)part.index, XML_NODE_ATTRIBUTE_REQUESTS, (unsigned long)part.queuedRequestsCount, XML_NODE_PART];
        }
    }
    
    [strDescr appendFormat:@"</%@>", XML_NODE_PARTS];
    
    DebugLog(@"TuneReqQue: save: strDescr = %@", strDescr);
    
    NSError * error = nil;
    [strDescr writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

#if DEBUG_LOG
    NSError *error1 = nil;
    NSString* content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error1];
    NSLog(@"TuneReqQue: save: read: error1  = %@", error1);
    NSLog(@"TuneReqQue: save: read: path    = %@", filePath);
    NSLog(@"TuneReqQue: save: read: content = %@", content);
#endif
    
    if (error)
        DebugLog(@"TuneReqQue: save: error = %@", [error localizedDescription]);
}

- (BOOL)load {
    DebugLog(@"TuneReqQue: load: filePath = %@", self.pathStorageFile);
    
    BOOL result = NO;
    
    @synchronized( queueParts_ ) {
        [queueParts_ removeAllObjects];
    
        /// Load parts desciptor file
        
        NSData * descsData = [NSData dataWithContentsOfFile:self.pathStorageFile];
        if (descsData)
        {
#if DEBUG_LOG
            NSString *fileContents = [[NSString alloc] initWithData:descsData encoding:NSUTF8StringEncoding];
            NSLog(@"TuneReqQue: load: fileContents = %@", fileContents);
#endif
            NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:descsData];
            [xmlParser setDelegate:self];
            [xmlParser parse];
            
            result = YES;
        }
        
        /// Load first part from file
        [[self getFirstPart] load];
        
        /// Load last part from file
        [[self getLastPart] load];
    }
    
    return result;
}

#pragma mark - NSXMLParser Delegate Methods

// sent when the parser finds an element start tag.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if(0 == [elementName compare:XML_NODE_PART]) {
        NSUInteger storedIndex = [[attributeDict objectForKey:XML_NODE_ATTRIBUTE_INDEX] intValue];
        NSUInteger requests = [[attributeDict objectForKey:XML_NODE_ATTRIBUTE_REQUESTS] intValue];
        
        DebugLog(@"TuneReqQue: parser: pathStorageDir = %@", self.pathStorageDir);
        DebugLog(@"TuneReqQue: parser: index          = %lu", (unsigned long)storedIndex);
        DebugLog(@"TuneReqQue: parser: request Count  = %lu", (unsigned long)requests);
        
        TuneRequestsQueuePart * part = [TuneRequestsQueuePart partWithIndex:storedIndex parentFolder:self.pathStorageDir];
        part.queuedRequestsCount = requests;
        part.shouldLoadOnRequest = YES;
        @synchronized( queueParts_ ) {
            [queueParts_ addObject:part];
        }
    }
}

#pragma mark - File Helper Methods

// Performs fixes to make sure that the queue storage folder
// does not get backed up to iCloud.
// -- for iOS v5.0.1 and above : Sets file attributes
// -- for iOS v5.0   and below : Moves file to Library/Caches
- (void)fixForiCloud {
    DebugLog(@"TuneReqQue: fixForCloud: is already fixed = %d", [[TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_MAT_FIXED_FOR_ICLOUD] boolValue]);
    
    // This fix is needed only once and never again.
    if(![[TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_MAT_FIXED_FOR_ICLOUD] boolValue]) {
        NSString *queueStorageFolder = self.pathStorageDir;
        NSError *error = nil;
        
        DebugLog(@"TuneReqQue: fixForCloud: systemVersion = %f", [TuneUtils numericiOSSystemVersion]);
        
        [TuneFileUtils addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:queueStorageFolder]];
        
#if DEBUG_LOG
        if(error) {
            NSLog(@"TuneReqQue: fixForCloud: Error = %@", error);
        }
#endif
        
        if(!error) {
            DebugLog(@"TuneReqQue: fixForCloud: set key KEY_MAT_FIXED_FOR_ICLOUD = YES");
            // Set a flag to note that the do-not-back-to-iCloud change was successful.
            [TuneUserDefaultsUtils setUserDefaultValue:@TRUE forKey:TUNE_KEY_MAT_FIXED_FOR_ICLOUD];
        }
    }
}

+ (BOOL)exists {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseFolder = [paths objectAtIndex:0];
    NSString *pathDir = [baseFolder stringByAppendingPathComponent:TUNE_REQUEST_QUEUE_FOLDER];
    NSString *pathFile = [pathDir stringByAppendingPathComponent:XML_FILE_NAME];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:pathFile];
}

@end
