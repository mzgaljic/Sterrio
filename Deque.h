//
//  Deque.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Deque : NSObject
{
    NSMutableArray* internalArray;
}

//main operations
- (void)enqueue:(id)anObject;
- (void)enqueueObjectAtHead:(id)anObject;
- (id)dequeue;
- (void)clear;
- (id)peekAtHead;
- (id)peekAtTail;
- (void)newOrderOfQueue:(NSArray *)anArray;

//helper methods
- (id)initWithArray:(NSArray *)anArray;
- (NSArray *)enqueueObjectsFromArray:(NSArray *)anArray;
- (NSArray *)enqueueObjectsFromArrayToHead:(NSArray *)anArray;
- (NSArray *)allQueueObjectsAsArray;

@property (atomic, readonly) NSUInteger count;
@end