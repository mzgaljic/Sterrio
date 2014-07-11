//
//  AlteredModelAlbumQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Album.h"
#import "Queue.h"
#import "AlteredModelItem.h"

@interface AlteredModelAlbumQueue : NSObject
{
    Queue* internalQueue;
}

+ (instancetype)createSingleton;

//main operations
- (void)enqueue:(AlteredModelItem *)theAlbumItem;
- (AlteredModelItem *)dequeue;
- (void)clear;
- (AlteredModelItem *)peek;

//helper methods
- (AlteredModelAlbumQueue *)enqueueAlbumModelItemsFromArray:(NSArray *)anArray;
- (NSArray *)allQueueAlteredItemsAsArray;

//NSCoding stuff
+ (AlteredModelAlbumQueue *)loadDataFromDisk;
- (BOOL)saveDataToDisk;

@property (atomic, readonly) NSUInteger count;
@end
