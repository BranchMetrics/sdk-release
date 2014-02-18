//
//  MATRequestsQueuePart.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/26/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATRequestsQueuePart.h"
#import "MATKeyStrings.h"
#import "NSString+MATURLEncoding.h"

const NSUInteger REQUESTS_MAX_COUNT_IN_PART         =  50;

NSString * const XML_NODE_QUEUEPART = @"QueuePart";
NSString * const XML_NODE_REQUEST = @"Request";

@interface MATRequestsQueuePart()

@property (nonatomic, retain) NSMutableArray * requests;

@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) NSUInteger loadedRequestsCount;

- (NSString*)generateFileName;

@end


@implementation MATRequestsQueuePart

@dynamic index;
@dynamic requestsLimitReached;
@dynamic empty;
@dynamic queuedRequestsCount;

@synthesize modified = modified_;
@synthesize fileName = fileName_;
@synthesize filePathName = filePathName_;
@synthesize parentFolder = parentFolder_;

@synthesize requests = requests_;
@synthesize loaded = loaded_;
@synthesize shouldLoadOnRequest = shouldLoadOnRequest_;
@synthesize loadedRequestsCount = loadedRequestsCount_;

- (NSInteger)index
{
    return index_;
}

- (void)setIndex:(NSInteger)targetIndex
{
    index_ = targetIndex;
    [self generateFileName];
    self.modified = YES;
}

- (BOOL)requestsLimitReached
{
    return ([self.requests count] >= REQUESTS_MAX_COUNT_IN_PART);
}

- (BOOL)empty
{
    return ([self.requests count] == 0);
}

- (NSUInteger)queuedRequestsCount
{
    if (self.requests && [self.requests count] > 0)
    {
        return [self.requests count];
    }
    
    return self.loadedRequestsCount;
}

- (void)setQueuedRequestsCount:(NSUInteger)count
{
    self.loadedRequestsCount = count;
}

+ (id)partWithIndex:(NSInteger)targetIndex parentFolder:(NSString *)parentFolder
{
    return [[MATRequestsQueuePart alloc] initWithIndex:targetIndex parentFolder:parentFolder];
}

- (id)initWithIndex:(NSInteger)targetIndex parentFolder:(NSString *)parentDir
{
    self = [super init];
    
    if (self)
    {
        index_ = targetIndex;
        self.parentFolder = parentDir;
        [self generateFileName];
        modified_ = NO;
        self.requests = [NSMutableArray array];
    }
    
    return self;
}


- (BOOL)push:(NSDictionary*)requestData
{
    DLog(@"MATReqQuePart: push: %@", requestData);
    
    if (self.requestsLimitReached) { return NO; }
    
    [requests_ addObject:requestData];
    
    self.modified = YES;
    
    return YES;
}

- (NSDictionary*)pop
{
    NSDictionary * requestData = nil;
	
    DLog(@"MATReqQuePart: pop: filePath      = %@", self.filePathName);
    DLog(@"MATReqQuePart: pop: requestsCnt   = %lu", (unsigned long)self.requests.count);
    DLog(@"MATReqQuePart: pop: loadedReqCnt  = %lu", (unsigned long)self.loadedRequestsCount);
    DLog(@"MATReqQuePart: pop: shouldLoad    = %d", self.shouldLoadOnRequest);
    
    /// Load requests from file if should load is set
    if ([requests_ count] == 0 && self.shouldLoadOnRequest)
    {
        [self load];
    }
    
    if ([requests_ count] > 0)
    {
        requestData = [requests_ objectAtIndex:0];
        
        [requests_ removeObjectAtIndex:0];
        self.modified = YES;
    }
    
    DLog(@"MATReqQuePart: pop: remaining requests queue size = %lu", (unsigned long)requests_.count);
    
    DLog(@"MATReqQuePart: pop: %@", requestData);
    return requestData;
}

- (BOOL)load
{
    DLog(@"MATReqQuePart: load: fileName = %@, is already loaded: %d", self.fileName, self.loaded);
    if (!self.loaded)
    {
        NSData * fileData = [NSData dataWithContentsOfFile:self.filePathName];
        
#if DEBUG_LOG
        NSLog(@"MATReqQuePart: load: data length = %lu", (unsigned long)fileData.length);
        
        NSString *strFileData = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        NSLog(@"MATReqQuePart: load: data to be parsed = %@", strFileData);
#endif
        
        if (fileData)
        {
            NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:fileData];
            [xmlParser setDelegate:self];
            [xmlParser parse];
            
            self.loaded = YES;
            self.shouldLoadOnRequest = NO;
        }
    }
    
    return self.loaded;
}

-(NSString*) serialize
{
    NSMutableString *strDescr = [NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@>", XML_NODE_QUEUEPART];
    
    for (NSDictionary * request in self.requests)
    {
        // clean up the text to make it compliant with XML
        NSString *urlValue = [request valueForKey:KEY_URL];
        NSString *encodedUrl = [urlValue MATgtm_stringBySanitizingAndEscapingForXML];
        
        NSString *jsonValue = [request valueForKey:KEY_JSON];
        NSString *encodedJson = [jsonValue MATgtm_stringBySanitizingAndEscapingForXML];
        encodedJson = encodedJson ? [NSString stringWithFormat:@" %@=\"%@\"", KEY_JSON, encodedJson] : STRING_EMPTY;
        
        NSDate *runDate = [request valueForKey:KEY_RUN_DATE];
        NSString *encodedDate = [runDate description];
        encodedDate = encodedDate ? [NSString stringWithFormat:@" %@=\"%@\"", KEY_RUN_DATE, encodedDate] : STRING_EMPTY;
		
        // serialize the request
        [strDescr appendFormat:@"<%@ %@=\"%@\"%@%@></%@>", XML_NODE_REQUEST, KEY_URL, encodedUrl, encodedJson, encodedDate, XML_NODE_REQUEST];
    }
    
    [strDescr appendFormat:@"</%@>", XML_NODE_QUEUEPART];
    
    return strDescr;
}

- (void)save
{
    DLog(@"MATReqQuePart save");
    NSError * error = nil;
    NSString *strDescr = [self serialize];
    [strDescr writeToFile:self.filePathName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
#if DEBUG_LOG
    
    if (error)
    {
        NSLog(@"MATReqQuePart: save: error = %@", [error localizedDescription]);
    }
    
    NSError *error1 = nil;
    NSString *content = [NSString stringWithContentsOfFile:self.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error1];
    NSLog(@"MATReqQuePart: save: read: error1  = %@", error1);
    NSLog(@"MATReqQuePart: save: read: path    = %@", self.filePathName);
    NSLog(@"MATReqQuePart: save: read: content = %@", content);
#endif
    
    self.modified = NO;
}

-(NSString*) description
{
    return [self serialize];
}


- (NSString*)generateFileName
{
    self.fileName = [NSString stringWithFormat:@"queue_part_%ld.xml", (long)self.index];
	
    DLog(@"MATReqQuePart: generateFileName: dir  = %@", self.parentFolder);
    DLog(@"MATReqQuePart: generateFileName: file = %@", self.fileName);
    
    self.filePathName = [self.parentFolder stringByAppendingPathComponent:self.fileName];
    
#if DEBUG_LOG
    NSLog(@"MATReqQuePart: generateFileName: fileName     = %@", self.fileName);
    NSLog(@"MATReqQuePart: generateFileName: filePathName = %@", self.filePathName);
    
    NSError *error2 = nil;
    NSString* content = [NSString stringWithContentsOfFile:self.filePathName
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error2];
    NSLog(@"MATReqQuePart: generateFileName: read: error2  = %@", error2);
    NSLog(@"MATReqQuePart: generateFileName: read: path    = %@", self.filePathName);
    NSLog(@"MATReqQuePart: generateFileName: read: content = %@", content);
#endif
    
    return self.fileName;
}

- (NSComparisonResult)indexComparator:(MATRequestsQueuePart*)other
{
    if (self.index < other.index)
    {
        return NSOrderedAscending;
    }
    else if (self.index > other.index)
    {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}

#pragma mark mark - NSXMLParser Delegate Methods

// sent when the parser finds an element start tag.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    DLog(@"MATReqQuePart: parser: elementName = %@", elementName);
    
    if([elementName isEqualToString:XML_NODE_REQUEST])
    {
        DLog(@"MATReqQuePart: parser: create object using: %@", attributeDict);
        
        [self push:[NSDictionary dictionaryWithDictionary:attributeDict]];
    }
}

@end
