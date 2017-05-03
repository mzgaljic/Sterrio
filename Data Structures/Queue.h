//
//  Queue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Queue : NSObject <NSCoding>
{
    NSMutableArray* internalArray;
}

//NOTE: Index 0 starts at the head, the last index is the tail. Objects are entered into the queue at the tail "end".

//main operations
- (void)enqueue:(id)anObject;
- (id)dequeue;
- (void)clear;
- (id)peek;

//helper methods
- (NSArray *)enqueueObjectsFromArray:(NSArray *)anArray;
- (NSArray *)allQueueObjectsAsArray;

@property (atomic, readonly) NSUInteger count;
@end
