//
//  MJGStack.m
//  MJGFoundation
//
//  Created by Matt Galloway on 06/01/2012.
//  Copyright (c) 2012 Matt Galloway. All rights reserved.
//
//NOTE: See header file for more copyright information. This file's implementation has been modified...
//method has been added to support 'dropping' an object at the bottom of the stack (so it is discarded).

#if ! __has_feature(objc_arc)
#error This file requires ARC to be enabled. Either enable ARC for the entire project or use -fobjc-arc flag.
#endif

#import "Stack.h"

@interface Stack ()
@property (nonatomic, strong) NSMutableArray *objects;
@end

@implementation Stack

@synthesize objects = _objects;

#pragma mark -

- (id)init {
    if ((self = [self initWithArray:nil])) {
    }
    return self;
}

- (id)initWithArray:(NSArray*)array {
    if ((self = [super init])) {
        _objects = [[NSMutableArray alloc] initWithArray:array];
    }
    return self;
}

#pragma mark -

/**
 * End of returned array is the top of the stack.
 */
- (NSArray *)arrayFromStack
{
    return (NSArray *)_objects;
}

#pragma mark - Custom accessors

- (NSUInteger)count {
    return _objects.count;
}


#pragma mark -

- (void)pushObject:(id)object {
    if (object) {
        [_objects addObject:object];
    }
}

- (void)pushObjects:(NSArray*)objects {
    for (id object in objects) {
        [self pushObject:object];
    }
}

- (void)discardBottomObject
{
    if (_objects.count > 0) {
        [_objects removeObjectAtIndex:0];
    }
}

- (id)popObject {
    if (_objects.count > 0) {
        id object = [_objects objectAtIndex:(_objects.count - 1)];
        [_objects removeLastObject];
        return object;
    }
    return nil;
}

- (id)peekObject {
    if (_objects.count > 0) {
        id object = [_objects objectAtIndex:(_objects.count - 1)];
        return object;
    }
    return nil;
}


#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [_objects countByEnumeratingWithState:state objects:buffer count:len];
}

@end
