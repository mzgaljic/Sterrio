//
//  AlteredModelArtistQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Artist.h"
#import "Queue.h"
#import "AlteredModelItem.h"

@interface AlteredModelArtistQueue : NSObject
{
    Queue* internalQueue;
}

+ (instancetype)createSingleton;

//main operations
- (void)enqueue:(Artist *)anArtist;
- (AlteredModelItem *)dequeue;
- (void)clear;
- (AlteredModelItem *)peek;

//helper methods
- (AlteredModelArtistQueue *)enqueueArtistsFromArray:(NSArray *)anArray;
- (NSArray *)allQueueAlteredItemsAsArray;

//NSCoding stuff
+ (AlteredModelArtistQueue *)loadDataFromDisk;
- (BOOL)saveDataToDisk;

@property (atomic, readonly) NSUInteger count;
@end
