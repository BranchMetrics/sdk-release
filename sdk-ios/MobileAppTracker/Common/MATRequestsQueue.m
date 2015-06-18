//
//  MATRequestsQueue.m
//  MobileAppTracker
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATRequestsQueue.h"
#import "MATUtils.h"

NSString * const MAT_REQUEST_QUEUE_FOLDER = @"queue";
NSString * const XML_FILE_NAME = @"queue_parts_descs.xml";

NSString * const XML_NODE_PART = @"Part";
NSString * const XML_NODE_PARTS = @"Parts";

NSString * const XML_NODE_ATTRIBUTE_INDEX = @"index";
NSString * const XML_NODE_ATTRIBUTE_REQUESTS = @"requests";

@interface MATRequestsQueue()

@property (nonatomic, retain) NSMutableArray * queueParts;
@property (nonatomic, retain) NSString *pathStorageDir, *pathStorageFile, *pathOld;

@end


@implementation MATRequestsQueue

@synthesize queueParts = queueParts_;
@synthesize pathOld, pathStorageDir, pathStorageFile;

@dynamic queuedRequestsCount;

#pragma mark - Custom Setters

- (NSUInteger)queuedRequestsCount
{
    NSUInteger count = 0;
    
    for (MATRequestsQueuePart *part in queueParts_)
    {
        count += part.queuedRequestsCount;
    }
    
    return count;
}

#pragma mark - Lifecycle Management

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.queueParts = [NSMutableArray array];
        
        float systemVersion = [MATUtils numericiOSSystemVersion];
        
        NSSearchPathDirectory folderType = systemVersion < MAT_IOS_VERSION_501 ? NSCachesDirectory : NSDocumentDirectory;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(folderType, NSUserDomainMask, YES);
        NSString *baseFolder = [paths objectAtIndex:0];
        
        DLog(@"MATReqQue: init: storage dir  = %@", self.pathStorageDir);
        DLog(@"MATReqQue: init: storage file = %@", self.pathStorageFile);
        
        self.pathStorageDir = [baseFolder stringByAppendingPathComponent:MAT_REQUEST_QUEUE_FOLDER];
        self.pathStorageFile = [self.pathStorageDir stringByAppendingPathComponent:XML_FILE_NAME];
        
        DLog(@"MATReqQue: init: systemVersion = %f", systemVersion);
        DLog(@"MATReqQue: init: pathStorageDir = %@, exists = %d", pathStorageDir, [[NSFileManager defaultManager] fileExistsAtPath:pathStorageDir]);
        DLog(@"MATReqQue: init: pathStorageFile = %@", pathStorageFile);
        
        if(systemVersion < MAT_IOS_VERSION_501)
        {
            DLog(@"MATReqQue: init: set pathOld");
            self.pathOld = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MAT_REQUEST_QUEUE_FOLDER];
        }
        
        // make sure that the queue storage folder exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.pathStorageDir])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.pathStorageDir withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        DLog(@"MATReqQue: init: pathOld = %@", self.pathOld);
        
        [self fixForiCloud];
    }
    
    return self;
}

- (void)closedown
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.pathStorageFile])
    {
        // delete the legacy queue storage file
        [[NSFileManager defaultManager] removeItemAtPath:self.pathStorageFile error:nil];
    }
    
    // Note: We do not remove the legacy "queue" folder,
    // being a generic folder name, the client app may
    // be using "queue" folder for some other purpose.
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"queue with %lu items, %lu parts", (unsigned long)[queueParts_ count], (unsigned long)[self queuedRequestsCount]];
}

#pragma mark - Queue Helper Methods

- (MATRequestsQueuePart*)getLastPart
{
    @synchronized( queueParts_ ) {
        // if queue parts exist then return the last queue part
        return [queueParts_ count] > 0 ? [queueParts_ lastObject] : nil;
    }
}

- (MATRequestsQueuePart*)getFirstPart
{
    @synchronized( queueParts_ ) {
        // if queue parts exist then return the first queue part
        return [queueParts_ count] > 0 ? [queueParts_ objectAtIndex:0] : nil;
    }
}

- (MATRequestsQueuePart*)addNewPart
{
    DLog(@"MATReqQue: addNewPart: pathStorageDir = %@", self.pathStorageDir);
    
    @synchronized( queueParts_ ) {
        MATRequestsQueuePart * part = [MATRequestsQueuePart partWithIndex:[self getSmallestPartFreeIndex] parentFolder:self.pathStorageDir];
        [queueParts_ addObject:part];

        return part;
    }
}

- (BOOL)removePart:(MATRequestsQueuePart*)part
{
    if (!part) return NO;
    
    DLog(@"MATReqQue: removePart: partToRemove = %@", part.filePathName);
    
    @synchronized( queueParts_ ) {
        [[NSFileManager defaultManager] removeItemAtPath:part.filePathName error:nil];
        [queueParts_ removeObject:part];
    }

    return YES;
}

- (NSUInteger)getSmallestPartFreeIndex
{
    @synchronized( queueParts_ ) {
        NSUInteger indexFree = 0;
        for (MATRequestsQueuePart * part in queueParts_)
            if (part.index == indexFree)
                ++indexFree;
            else
                break;
        
        return indexFree;
    }
}

- (void)push:(NSDictionary*)object
{
    MATRequestsQueuePart * lastPart = [self getLastPart];
    if (!lastPart || lastPart.requestsLimitReached)
        lastPart = [self addNewPart];

#if DEBUG_LOG
    NSLog(@"MATReqQue: push: %@", object);
    BOOL pushSuccessful =
#endif
    [lastPart push:object];
        
#if DEBUG_LOG
    NSLog(@"MATReqQue: push: successful = %d", pushSuccessful);
        
    NSString* content = [NSString stringWithContentsOfFile:lastPart.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSLog(@"MATReqQue: push: path = %@", lastPart.filePathName);
    NSLog(@"MATReqQue: push: content = %@", content);
#endif
}

- (void)pushToHead:(NSDictionary*)object
{
    MATRequestsQueuePart * lastPart = [self getLastPart];
    if (!lastPart || lastPart.requestsLimitReached)
        lastPart = [self addNewPart];

#if DEBUG_LOG
    NSLog(@"MATReqQue: pushToHead: %@", object);
    BOOL pushSuccessful =
#endif
    [lastPart pushToHead:object];
        
#if DEBUG_LOG
    NSLog(@"MATReqQue: pushToHead: successful = %d", pushSuccessful);
        
    NSString* content = [NSString stringWithContentsOfFile:lastPart.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSLog(@"MATReqQue: pushToHead: path = %@", lastPart.filePathName);
    NSLog(@"MATReqQue: pushToHead: content = %@", content);
#endif
}

- (NSDictionary*)pop
{
    NSDictionary * object = nil;

    DLog(@"MATReqQue: pop: start");
    
    MATRequestsQueuePart * firstPart = [self getFirstPart];
    if (firstPart)
    {
        object = [firstPart pop];
        DLog(@"MATReqQue: pop: pass1: %@,\nfirstPart isEmpty = %d", object, firstPart.empty);
        if (firstPart.empty)
            [self removePart:firstPart];
    }
    
    DLog(@"MATReqQue: pop: end: %@", object);
    return object;
}

- (void)save
{
    DLog(@"MATReqQue: save: %@", self.pathStorageFile);
    
    /// Save parts description file
    NSString * filePath = self.pathStorageFile;
    
    NSMutableString *strDescr = [NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@>", XML_NODE_PARTS];
    
    @synchronized( queueParts_ ) {
        for (MATRequestsQueuePart *part in queueParts_)
        {
            /// If part is modified save it to file
            if (part.isModified)
                [part save];
            
            /// Store its information
            [strDescr appendFormat:@"<%@ %@=\"%ld\" %@=\"%lu\"></%@>", XML_NODE_PART, XML_NODE_ATTRIBUTE_INDEX, (long)part.index, XML_NODE_ATTRIBUTE_REQUESTS, (unsigned long)part.queuedRequestsCount, XML_NODE_PART];
        }
    }
    
    [strDescr appendFormat:@"</%@>", XML_NODE_PARTS];
    
    DLog(@"MATReqQue: save: strDescr = %@", strDescr);
    
    NSError * error = nil;
    [strDescr writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

#if DEBUG_LOG
    NSError *error1 = nil;
    NSString* content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error1];
    NSLog(@"MATReqQue: save: read: error1  = %@", error1);
    NSLog(@"MATReqQue: save: read: path    = %@", filePath);
    NSLog(@"MATReqQue: save: read: content = %@", content);
#endif
    
    if (error)
        DLog(@"MATReqQue: save: error = %@", [error localizedDescription]);
}

- (BOOL)load
{
    DLog(@"MATReqQue: load: filePath = %@", self.pathStorageFile);
    
    BOOL result = NO;
    
    @synchronized( queueParts_ ) {
        [queueParts_ removeAllObjects];
    
        /// Load parts desciptor file
        
        NSData * descsData = [NSData dataWithContentsOfFile:self.pathStorageFile];
        if (descsData)
        {
#if DEBUG_LOG
            NSString *fileContents = [[NSString alloc] initWithData:descsData encoding:NSUTF8StringEncoding];
            NSLog(@"MATReqQue: load: fileContents = %@", fileContents);
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
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if(0 == [elementName compare:XML_NODE_PART])
    {
        NSUInteger storedIndex = [[attributeDict objectForKey:XML_NODE_ATTRIBUTE_INDEX] intValue];
        NSUInteger requests = [[attributeDict objectForKey:XML_NODE_ATTRIBUTE_REQUESTS] intValue];
        
        DLog(@"MATReqQue: parser: pathStorageDir = %@", self.pathStorageDir);
        DLog(@"MATReqQue: parser: index          = %lu", (unsigned long)storedIndex);
        DLog(@"MATReqQue: parser: request Count  = %lu", (unsigned long)requests);
        
        MATRequestsQueuePart * part = [MATRequestsQueuePart partWithIndex:storedIndex parentFolder:self.pathStorageDir];
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
- (void)fixForiCloud
{
    DLog(@"MATReqQue: fixForCloud: is already fixed = %d", [[MATUtils userDefaultValueforKey:MAT_KEY_MAT_FIXED_FOR_ICLOUD] boolValue]);
    
    // This fix is needed only once and never again.
    if(![[MATUtils userDefaultValueforKey:MAT_KEY_MAT_FIXED_FOR_ICLOUD] boolValue])
    {
        NSString *queueStorageFolder = self.pathStorageDir;
        
        NSError *error = nil;
        
        float systemVersion = [MATUtils numericiOSSystemVersion];
        
        DLog(@"MATReqQue: fixForCloud: systemVersion = %f", systemVersion);
        
        if(systemVersion < MAT_IOS_VERSION_501)
        {
            NSString *oldPath = self.pathOld;
            
            DLog(@"MATReqQue: fixForCloud: oldPath = %@, exists = %d", oldPath, [[NSFileManager defaultManager] fileExistsAtPath:oldPath]);
            
            // If old request queue storage folder Documents/queue exists, then move it to the Library/Caches folder.
            if([[NSFileManager defaultManager] fileExistsAtPath:oldPath])
            {
                DLog(@"MATReqQue: fixForCloud: Removing destination path = %@.", queueStorageFolder);
                // Make sure that the destination does not already contain a folder with the same name
                [[NSFileManager defaultManager] removeItemAtPath:queueStorageFolder error:&error];

                DLog(@"MATReqQue: fixForCloud: Moving old %@ to new %@.", oldPath, queueStorageFolder);
                // move queue storage files from old Documents folder location to the new non-iCloud Library/Cache location
                [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:queueStorageFolder error:&error];
            }
        }
        else
        {
            // For iOS 5.0.1 and above set the ignore-for-iCloud-backup flag for the queue folder.
            [MATUtils addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:queueStorageFolder]];
        }
        
#if DEBUG_LOG
        if(error)
        {
            NSLog(@"MATReqQue: fixForCloud: Error = %@", error);
        }
#endif
        
        if(!error)
        {
            DLog(@"MATReqQue: fixForCloud: set key KEY_MAT_FIXED_FOR_ICLOUD = YES");
            // Set a flag to note that the do-not-back-to-iCloud change was successful.
            [MATUtils setUserDefaultValue:@TRUE forKey:MAT_KEY_MAT_FIXED_FOR_ICLOUD];
        }
    }
}

+ (BOOL)exists
{
    float systemVersion = [MATUtils numericiOSSystemVersion];
    
    NSSearchPathDirectory folderType = systemVersion < MAT_IOS_VERSION_501 ? NSCachesDirectory : NSDocumentDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(folderType, NSUserDomainMask, YES);
    NSString *baseFolder = [paths objectAtIndex:0];
    NSString *pathDir = [baseFolder stringByAppendingPathComponent:MAT_REQUEST_QUEUE_FOLDER];
    NSString *pathFile = [pathDir stringByAppendingPathComponent:XML_FILE_NAME];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:pathFile];
}

@end
