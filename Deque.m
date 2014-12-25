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

- (id)init
{
    if(self = [super init])
    {
        internalArray = [NSMutableArray array];
        count = 0;
    }
    return self;
}

- (id)initWithArray:(NSArray *)anArray
{
    if(self = [super init])
    {
        internalArray = [NSMutableArray arrayWithArray:anArray];
        count = internalArray.count;
    }
    return self;
}

- (void)enqueue:(id)anObject
{
    [internalArray addObject:anObject];
    count = internalArray.count;
}

- (void)enqueueObjectAtHead:(id)anObject
{
    [internalArray insertObject:anObject atIndex:0];
    count = internalArray.count;
}

- (NSArray *)enqueueObjectsFromArrayToHead:(NSArray *)anArray
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, anArray.count - 1)];
    [internalArray insertObjects:anArray atIndexes:indexSet];
    count = internalArray.count;
    return internalArray;
}

- (NSArray *)enqueueObjectsFromArray:(NSArray *)anArray
{
    [internalArray addObjectsFromArray:anArray];
    count = internalArray.count;
    return internalArray;
}

- (id)dequeue
{
    id obj = nil;
    if(internalArray.count > 0)
    {
        obj = [internalArray objectAtIndex:0];
        [internalArray removeObjectAtIndex:0];
        count = internalArray.count;
    }
    return obj;
}

- (void)clear
{
    [internalArray removeAllObjects];
    count = 0;
}

- (id)peekAtHead
{
    if(count > 0)
        return [internalArray objectAtIndex:0];
    else
        return nil;
}

- (id)peekAtTail
{
    if(count > 0)
        return [internalArray objectAtIndex: (count - 1)];
    else
        return nil;
}

- (void)newOrderOfQueue:(NSArray *)anArray
{
    if(count != [anArray count])
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
    if(count > 0){
        [internalArray removeObject:anObject];
    }
}

- (NSInteger)numObjectsAfterThisOne:(id)anObject
{
    //check if object in array at all
    NSInteger index = [internalArray indexOfObjectIdenticalTo:anObject];
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

@end
