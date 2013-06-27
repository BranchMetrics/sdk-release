//
//  MATRequestsQueue.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATRequestsQueue.h"

NSString * const MAT_REQUEST_QUEUE_FOLDER = @"queue";
NSString * const XML_FILE_NAME = @"queue_parts_descs.xml";

@interface MATRequestsQueue()

@property (nonatomic, retain) NSMutableArray * queueParts;
@property (nonatomic, retain) NSString *pathStorageDir, *pathStorageFile, *pathOld;

- (MATRequestsQueuePart*)getLastPart;
- (MATRequestsQueuePart*)getFirstPart;
- (MATRequestsQueuePart*)addNewPart;
- (BOOL)removePart:(MATRequestsQueuePart*)part;
- (NSUInteger)getSmallestPartFreeIndex;

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
        
        float systemVersion = [MATUtils getNumericiOSVersion:[[UIDevice currentDevice] systemVersion]];
        
        NSSearchPathDirectory folderType = systemVersion < IOS_VERSION_501 ? NSCachesDirectory : NSDocumentDirectory;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(folderType, NSUserDomainMask, YES);
        NSString *baseFolder = [paths objectAtIndex:0];
        
#if DEBUG_LOG
        NSLog(@"storage dir  = %@", self.pathStorageDir);
        NSLog(@"storage file = %@", self.pathStorageFile);
#endif
        
        self.pathStorageDir = [baseFolder stringByAppendingPathComponent:MAT_REQUEST_QUEUE_FOLDER];
        self.pathStorageFile = [self.pathStorageDir stringByAppendingPathComponent:XML_FILE_NAME];
        
#if DEBUG_LOG
        NSLog(@"MATRequestsQueue.init: systemVersion = %f", systemVersion);
        NSLog(@"MATRequestsQueue.init: pathStorageDir = %@, exists = %d", pathStorageDir, [[NSFileManager defaultManager] fileExistsAtPath:pathStorageDir]);
        NSLog(@"MATRequestsQueue.init: pathStorageFile = %@", pathStorageFile);
#endif
        
        if(systemVersion < IOS_VERSION_501)
        {
#if DEBUG_LOG
            NSLog(@"MATRequestsQueue.init: set pathOld");
#endif
            self.pathOld = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MAT_REQUEST_QUEUE_FOLDER];
        }
        
        // make sure that the queue storage folder exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.pathStorageDir])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.pathStorageDir withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
#if DEBUG_LOG
        NSLog(@"MATRequestsQueue.init: pathOld = %@", self.pathOld);
#endif
        
        [self fixForiCloud];
    }
    
    return self;
}

- (void)dealloc
{
    [queueParts_ release], queueParts_ = nil;
    [pathOld release], pathOld = nil;
    [pathStorageDir release], pathStorageDir = nil;
    [pathStorageFile release], pathStorageFile = nil;

    [super dealloc];
}

#pragma mark - Queue Helper Methods

- (MATRequestsQueuePart*)getLastPart
{
    // if queue parts exist then return the last queue part
    return [queueParts_ count] > 0 ? [queueParts_ lastObject] : nil;
}

- (MATRequestsQueuePart*)getFirstPart
{
    // if queue parts exist then return the first queue part
    return [queueParts_ count] > 0 ? [queueParts_ objectAtIndex:0] : nil;
}

- (MATRequestsQueuePart*)addNewPart
{
#if DEBUG_LOG
    NSLog(@"MATReqQue.addNewPart: pathStorageDir = %@", self.pathStorageDir);
#endif
    
    MATRequestsQueuePart * part = [MATRequestsQueuePart partWithIndex:[self getSmallestPartFreeIndex] parentFolder:self.pathStorageDir];
    [queueParts_ addObject:part];
    
    return part;
}

- (BOOL)removePart:(MATRequestsQueuePart*)part
{
    if (!part) { return NO; }
    
    [[NSFileManager defaultManager] removeItemAtPath:part.filePathName error:nil];
    [queueParts_ removeObject:part];

    return YES;
}

- (NSUInteger)getSmallestPartFreeIndex
{
    NSUInteger index = 0;
    for (MATRequestsQueuePart * part in queueParts_)
    {
        if (part.index == index)
        {
            ++index;
        }
        else
        {
            break;
        }
    }
    
    return index;
}

- (void)push:(NSDictionary*)object
{
    @synchronized(self)
    {
        MATRequestsQueuePart * lastPart = [self getLastPart];
        if (!lastPart || lastPart.requestsLimitReached)
        {
            lastPart = [self addNewPart];
        }
        
        [lastPart push:object];
    }
}

- (NSDictionary*)pop
{
    NSDictionary * object = nil;
    
    @synchronized(self)
    {
        MATRequestsQueuePart * firstPart = [self getFirstPart];
        if (firstPart)
        {
            object = [firstPart pop];
            if (firstPart.empty)
            {
                [self removePart:firstPart];
            }
        }
    }
    
    return object;
}

- (void)save
{
#if DEBUG_LOG
    NSLog(@"MATRequestsQueue.save()");
#endif
    
    /// Save parts description file
    NSString * filePathName = self.pathStorageFile;
    
    NSMutableString *strDescr = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Parts>"];
    
    for (MATRequestsQueuePart *part in queueParts_)
    {
        /// If part is modified save it to file
        if (part.isModified)
        {
            [part save];
        }
        
        /// Store it's information
        [strDescr appendFormat:@"<Part index=\"%d\" requests=\"%d\"></Part>", part.index, part.queuedRequestsCount];
    }
    
    [strDescr appendString:@"</Parts>"];
    
    NSError * error = nil;
    [strDescr writeToFile:filePathName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
    {
#if DEBUG_LOG
        NSLog(@"%@", [error localizedDescription]);
#endif
    }
}

- (BOOL)load
{
#if DEBUG_LOG
    NSLog(@"MATRequestsQueue.load()");
#endif
    
    BOOL result = NO;
    
    [queueParts_ removeAllObjects];
    
    /// Load parts desciptor file
    
    NSData * descsData = [NSData dataWithContentsOfFile:self.pathStorageFile];
    if (descsData)
    {
        NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:descsData];
        [xmlParser setDelegate:self];
        [xmlParser parse];
        [xmlParser release]; xmlParser = nil;
        
        result = YES;
    }

    /// Load first part from file
    [[self getFirstPart] load];
    
    /// Load last part from file
    [[self getLastPart] load];
    
    return result;    
}

#pragma mark - NSXMLParser Delegate Methods

// sent when the parser finds an element start tag.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if(0 == [elementName compare:@"Part"])
    {
        NSUInteger index = [[attributeDict objectForKey:@"index"] intValue];
        NSUInteger requests = [[attributeDict objectForKey:@"requests"] intValue];
        
#if DEBUG_LOG
        NSLog(@"MATReqQue.parser: pathStorageDir = %@", self.pathStorageDir);
#endif
        
        MATRequestsQueuePart * part = [MATRequestsQueuePart partWithIndex:index parentFolder:self.pathStorageDir];
        part.queuedRequestsCount = requests;
        part.shouldLoadOnRequest = YES;
        [queueParts_ addObject:part];
    }
}

#pragma mark - File Helper Methods

// Performs fixes to make sure that the queue storage folder
// does not get backed up to iCloud.
// -- for iOS v5.0.1 and above : Sets file attributes
// -- for iOS v5.0   and below : Moves file to Library/Caches
- (void)fixForiCloud
{
#if DEBUG_LOG
    NSLog(@"MATRequestsQueue.fixForCloud: KEY_MAT_FIXED_FOR_ICLOUD = %d", [[NSUserDefaults standardUserDefaults] boolForKey:KEY_MAT_FIXED_FOR_ICLOUD]);
#endif
    
    // This fix is needed only once and never again.
    if(![[NSUserDefaults standardUserDefaults] boolForKey:KEY_MAT_FIXED_FOR_ICLOUD])
    {
        NSString *queueStorageFolder = self.pathStorageDir;
        
        NSError *error = nil;
        
        float systemVersion = [MATUtils getNumericiOSVersion:[[UIDevice currentDevice] systemVersion]];
        
#if DEBUG_LOG
        NSLog(@"MATRequestsQueue.fixForCloud: systemVersion = %f", systemVersion);
#endif
        
        if(systemVersion < IOS_VERSION_501)
        {
            NSString *oldPath = self.pathOld;
            
#if DEBUG_LOG
            NSLog(@"MATRequestsQueue.fixForCloud: oldPath = %@, exists = %d", oldPath, [[NSFileManager defaultManager] fileExistsAtPath:oldPath]);
#endif
            
            // If old request queue storage folder Documents/queue exists, then move it to the Library/Caches folder.
            if([[NSFileManager defaultManager] fileExistsAtPath:oldPath])
            {
#if DEBUG_LOG
                NSLog(@"MATRequestsQueue.fixForCloud: Removing destination path = %@.", queueStorageFolder);
#endif
                // Make sure that the destination does not already contain a folder with the same name
                [[NSFileManager defaultManager] removeItemAtPath:queueStorageFolder error:&error];

#if DEBUG_LOG
                NSLog(@"MATRequestsQueue.fixForCloud: Moving old %@ to new %@.", oldPath, queueStorageFolder);
#endif
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
            NSLog(@"MATRequestsQueue.fixForCloud: Error = %@", error);
        }
#endif
        
        if(!error)
        {
#if DEBUG_LOG
            NSLog(@"MATRequestsQueue.fixForCloud: set key KEY_MAT_FIXED_FOR_ICLOUD = TRUE");
#endif
            // Set a flag to note that the do-not-back-to-iCloud change was successful.
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:KEY_MAT_FIXED_FOR_ICLOUD];
        }
    }
}


@end
