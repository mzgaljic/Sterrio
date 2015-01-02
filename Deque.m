//
//  Deque.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Deque.h"

@interface Deque ()
{
    NSMutableArray* internalArray;
}
@end

@implementation Deque
@synthesize count;

//custom setters and getters
- (NSUInteger)count
{
    return internalArray.count;
}

- (id)init
{
    if(self = [super init])
    {
        internalArray = [NSMutableArray array];
    }
    return self;
}

- (id)initWithArray:(NSArray *)anArray
{
    if(self = [super init])
    {
        internalArray = [NSMutableArray arrayWithArray:anArray];
    }
    return self;
}

- (void)enqueue:(id)anObject
{
    [internalArray addObject:anObject];
}

- (void)enqueueObjectAtHead:(id)anObject
{
    [internalArray insertObject:anObject atIndex:0];
}

- (NSArray *)enqueueObjectsFromArrayToHead:(NSArray *)anArray
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, anArray.count - 1)];
    [internalArray insertObjects:anArray atIndexes:indexSet];
    return internalArray;
}

- (NSArray *)enqueueObjectsFromArray:(NSArray *)anArray
{
    [internalArray addObjectsFromArray:anArray];
    return internalArray;
}

- (id)dequeue
{
    id obj = nil;
    if(internalArray.count > 0)
    {
        obj = [internalArray objectAtIndex:0];
        [internalArray removeObjectAtIndex:0];
    }
    return obj;
}

- (void)clear
{
    [internalArray removeAllObjects];
}

- (id)peekAtHead
{
    if(internalArray.count > 0)
        return [internalArray objectAtIndex:0];
    else
        return nil;
}

- (id)peekAtTail
{
    if(internalArray.count > 0)
        return [internalArray objectAtIndex: (internalArray.count - 1)];
    else
        return nil;
}

- (void)newOrderOfQueue:(NSArray *)anArray
{
    if(internalArray.count != [anArray count])
        return;
    [self clear];
    [self enqueueObjectsFromArray:anArray];
}

- (NSArray *)allQueueObjectsAsArray
{
    return (NSArray *)internalArray;
}

//breaking deque rules
- (id)objectAtIndex:(NSUInteger)index
{
    return [internalArray objectAtIndex:index];
}

- (NSUInteger)indexOfObject:(id)object
{
    return [internalArray indexOfObject:object];
}

- (NSArray *)insertItem:(id)anObject atIndex:(NSUInteger)index
{
    [internalArray insertObject:anObject atIndex:index];
    return internalArray;
}

- (void)removeObjectFromQueue:(id)anObject
{
    if(internalArray.count > 0){
        [internalArray removeObject:anObject];
    }
}

- (NSInteger)numObjectsAfterThisOne:(id)anObject
{
    //check if object in array at all
    NSInteger index = [internalArray isEqual:anObject];
    if(index == NSNotFound){
        return -1;
    } else{
        NSInteger lastIndex;
        if(internalArray.count > 0)
            lastIndex = internalArray.count - 1;
        else
            lastIndex = internalArray.count;
        
        if(index == lastIndex)
            return 0;
        else if(index < lastIndex)
            return lastIndex - index;
        else if (index > lastIndex)
            return -1;  //should never happen. indicates dequeue is broken.
        else
            return -1;
    }
}

- (BOOL)isObjectInQueue:(id)object
{
    return [internalArray containsObject:object] ? YES : NO;
}

@end
