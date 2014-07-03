//
//  AlteredModelSongQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlteredModelSongQueue.h"
#define INTERNAL_QUEUE_KEY @"internalQueue"
#define COUNT_KEY @"count"

@implementation AlteredModelSongQueue
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
- (void)enqueue:(Song *)aSong
{
    [internalQueue enqueue:[[AlteredModelItem alloc] initWithAddedSong: aSong]];
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
- (AlteredModelSongQueue *)enqueueSongsFromArray:(NSArray *)anArray
{
    //parameter contains Song objects! gotta be careful here...
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:anArray.count];
    for(Song *someSong in anArray){
        [tempArray addObject:[[AlteredModelItem alloc] initWithAddedSong: someSong]];
    }
    [internalQueue enqueueObjectsFromArray:tempArray];
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

+ (AlteredModelSongQueue *)loadDataFromDisk
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].AlteredModelSongQueueFileUrl];
    if(!data){
        //if class not instantiated before,(file not yet written to disk), return nil
        return nil;
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)saveDataToDisk
{
    AlteredModelSongQueue *thisInstance = self;
    
    //save to disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:thisInstance];  //encode this class
    return [fileData writeToURL:[FileIOConstants createSingleton].AlteredModelSongQueueFileUrl atomically:YES];
}

@end
