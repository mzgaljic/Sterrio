//
//  Queue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Queue.h"
#define INTERNAL_ARRAY_KEY @"internalArray"
#define COUNT_KEY @"count"

@implementation Queue
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

- (void)enqueue:(id)anObject
{
    [internalArray addObject:anObject];
    count = internalArray.count;
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

- (id)peek
{
    if(count > 0)
        return [internalArray objectAtIndex:0];
    else
        return nil;
}

- (NSArray *)allQueueObjectsAsArray
{
    return (NSArray *)internalArray;
}

//-----------------NSCoding stuff---------------
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        count = [aDecoder decodeIntegerForKey:COUNT_KEY];
        internalArray = [aDecoder decodeObjectForKey:INTERNAL_ARRAY_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:count forKey:COUNT_KEY];
    [aCoder encodeObject:internalArray forKey:INTERNAL_ARRAY_KEY];
}

//loading and saving code should be done with a root object (object that holds a pointer to this queue).

@end
