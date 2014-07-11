//
//  AlteredModelAlbumQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlteredModelAlbumQueue.h"
#define INTERNAL_QUEUE_KEY @"internalQueue"
#define COUNT_KEY @"count"

@implementation AlteredModelAlbumQueue
@synthesize count;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

//main operations
- (void)enqueue:(AlteredModelItem *)theAlbumItem
{
    [internalQueue enqueue:theAlbumItem];
    count = internalQueue.count;
}

- (AlteredModelItem *)dequeue
{
    count = internalQueue.count;
    return [internalQueue dequeue];
}

- (void)clear
{
    [internalQueue clear];
    count = internalQueue.count;
}

- (AlteredModelItem *)peek
{
    return [internalQueue peek];
}

//helper methods
- (AlteredModelAlbumQueue *)enqueueAlbumModelItemsFromArray:(NSArray *)anArray
{
    [internalQueue enqueueObjectsFromArray:anArray];
    count = internalQueue.count;
    return self;
}

- (NSArray *)allQueueAlteredItemsAsArray
{
    return [internalQueue allQueueObjectsAsArray];
}

//-----------------NSCoding stuff---------------
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        internalQueue = [aDecoder decodeObjectForKey:INTERNAL_QUEUE_KEY];
        count = [aDecoder decodeIntegerForKey:COUNT_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:internalQueue forKey:INTERNAL_QUEUE_KEY];
    [aCoder encodeInteger:count forKey:COUNT_KEY];
}

+ (AlteredModelAlbumQueue *)loadDataFromDisk
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].AlteredModelAlbumQueueFileUrl];
    if(!data){
        //if class not instantiated before,(file not yet written to disk), return nil
        return nil;
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)saveDataToDisk
{
    AlteredModelAlbumQueue *thisInstance = self;
    
    //save to disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:thisInstance];  //encode this class
    return [fileData writeToURL:[FileIOConstants createSingleton].AlteredModelAlbumQueueFileUrl atomically:YES];
}

@end