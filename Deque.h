//
//  Deque.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Deque : NSObject
//NOTE: Index 0 starts at the head, the last index is the tail. Objects may entered into the deque at either end-it does not matter.

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
- (NSArray *)enqueueObjectsFromArrayToHead:(NSArray *)anArray;  //shoves new items in front
- (NSArray *)allQueueObjectsAsArray;

//breaking deque rules
- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(id)object;
- (NSArray *)insertItem:(id)anObject atIndex:(NSUInteger)index;
- (void)removeObjectFromQueue:(id)anObject;
- (NSInteger)numObjectsAfterThisOne:(id)anObject;

@property (atomic, readonly) NSUInteger count;
@end