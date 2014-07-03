//
//  AlteredModelSongQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Queue.h"
#import "AlteredModelItem.h"

@interface AlteredModelSongQueue : NSObject <NSCoding>
{
    Queue* internalQueue;
}

+ (instancetype)createSingleton;

//main operations
- (void)enqueue:(Song *)aSong;
- (AlteredModelItem *)dequeue;
- (void)clear;
- (AlteredModelItem *)peek;

//helper methods
- (AlteredModelSongQueue *)enqueueSongsFromArray:(NSArray *)anArray;
- (NSArray *)allQueueAlteredItemsAsArray;

//NSCoding stuff
+ (AlteredModelSongQueue *)loadDataFromDisk;
- (BOOL)saveDataToDisk;

@property (atomic, readonly) NSUInteger count;
@end
