//
//  MATRequestsQueue.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATRequestsQueue.h"
#import "MATRequestsQueuePart.h"

NSString * const XML_FILE_NAME = @"queue/queue_parts_descs.xml";

@interface MATRequestsQueue()

@property (nonatomic, retain) NSMutableArray * queueParts;

- (MATRequestsQueuePart*)getLastPart;
- (MATRequestsQueuePart*)getFirstPart;
- (MATRequestsQueuePart*)addNewPart;
- (BOOL)removePart:(MATRequestsQueuePart*)part;
- (NSUInteger)getSmallestPartFreeIndex;

@end

@implementation MATRequestsQueue

@synthesize queueParts = queueParts_;

@dynamic queuedRequestsCount;

- (NSUInteger)queuedRequestsCount
{
    NSUInteger count = 0;
    
    for (MATRequestsQueuePart * part in queueParts_)
    {
        count += part.queuedRequestsCount;
    }
    
    return count;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        queueParts_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    self.queueParts = nil;

    [super dealloc];
}

- (MATRequestsQueuePart*)getLastPart
{
    if ([queueParts_ count] > 0)
    {
        return [self.queueParts lastObject];
    }
    
    return nil;
}

- (MATRequestsQueuePart*)getFirstPart
{
    if ([queueParts_ count] > 0)
    {
        return [self.queueParts objectAtIndex:0];
    }
    
    return nil;
}

- (MATRequestsQueuePart*)addNewPart
{
    MATRequestsQueuePart * part = [MATRequestsQueuePart partWithIndex:[self getSmallestPartFreeIndex]];
    [queueParts_ addObject:part];
    
    return part;
}

- (BOOL)removePart:(MATRequestsQueuePart*)part
{
    if (!part) { return NO; }
    
    [[NSFileManager defaultManager] removeItemAtPath:part.filePathName error:nil];
    [self.queueParts removeObject:part];

    return YES;
}

- (NSUInteger)getSmallestPartFreeIndex
{
    NSUInteger index = 0;
    for (MATRequestsQueuePart * part in self.queueParts)
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
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex : 0];
    NSString * dirPathName = [documentsDirectory stringByAppendingPathComponent:@"queue"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPathName])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPathName withIntermediateDirectories:NO attributes:nil error:nil];
    }    
    
    /// Save parts description file
    NSString * fileName = [NSString stringWithFormat:@"%@", XML_FILE_NAME];
    NSString * filePathName = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSError * error = nil;
    
    NSMutableString *strDescr = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Parts>"];

    for (MATRequestsQueuePart * part in self.queueParts)
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
    
    [strDescr writeToFile:filePathName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
    {
        NSLog(@"%@", [error localizedDescription]);
    }
}

- (BOOL)load
{
    BOOL result = NO;
    
    [self.queueParts removeAllObjects];
    
    /// Load parts desciptor file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex : 0];
    
    NSString * fileName = [NSString stringWithFormat:@"%@", XML_FILE_NAME];
    NSString * filePathName = [documentsDirectory stringByAppendingPathComponent:fileName];

    NSData * descsData = [NSData dataWithContentsOfFile:filePathName];
    if (descsData)
    {
        NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:descsData];
        [xmlParser setDelegate:self];
        [xmlParser parse];
        [xmlParser release]; xmlParser = nil;
        
        result = YES;
    }

    /// Load first part from file
    {
        MATRequestsQueuePart * part = [self getFirstPart];
        if (part)
        {
            [part load];
        }
    }

    /// Load last part from file
    {
        MATRequestsQueuePart * part = [self getLastPart];
        if (part)
        {
            [part load];
        }
    }
    
    return result;    
}

#pragma mark -
#pragma mark NSXMLParser Delegate Methods

// sent when the parser finds an element start tag.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if(0 == [elementName compare:@"Part"])
    {
        NSUInteger index = [[attributeDict objectForKey:@"index"] intValue];
        NSUInteger requests = [[attributeDict objectForKey:@"requests"] intValue];
        
        MATRequestsQueuePart * part = [MATRequestsQueuePart partWithIndex:index];
        part.queuedRequestsCount = requests;
        part.shouldLoadOnRequest = YES;
        [self.queueParts addObject:part];
    }
}


@end
