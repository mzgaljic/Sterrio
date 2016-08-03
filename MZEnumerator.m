//
//  MZEnumerator.m
//  Sterrio
//
//  Created by Mark Zgaljic on 6/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZEnumerator.h"

//ENUMERATOR DOES NOT ALLOW ARRAY SIZE TO CHANGE DURING ENUMERATION
@interface MZEnumerator ()
@property (nonatomic, assign) NSInteger cursor;
@property (nonatomic, strong) NSArray *array;
@property (nonatomic, assign) NSUInteger lastKnownArraySize;
@end
@implementation MZEnumerator

- (id)initWithArray:(NSArray *)array
{
    if(self = [super init]) {
        _cursor = 0;
        _array = array;
        _lastKnownArraySize = (_array == nil) ? NSUIntegerMax : _array.count;
    }
    return self;
}

- (id)initWithArray:(NSArray *)array andIndex:(NSUInteger)index
{
    if(self = [self initWithArray:array]) {
        _cursor = index;
    }
    return self;
}

- (void)dealloc
{
    _array = nil;
}

/** Moves the hidden 'cursor' into the array to position 0, if applicable. Otherwise nil is returned
 * (out of bounds.)*/
- (id)moveTofirstObject
{
    NSUInteger arraySize = (_array == nil) ? NSUIntegerMax : _array.count;
    if(arraySize != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_array == nil || _array.count == 0) {
        return nil;
    }
    _cursor = 0;
    return [_array objectAtIndex:_cursor];
}

/** Advances the hidden 'cursor' into the array and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)nextObject
{
    NSUInteger arraySize = (_array == nil) ? NSUIntegerMax : _array.count;
    if(arraySize != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_array == nil || _array.count == 0) {
        return nil;
    }
    
    _cursor++;  //advance
    if(_cursor > _array.count-1) {
        //cursor went out of bounds, lets keep the index at the last index in the array.
        //don't want to allow going 'off the edge' of the array bounds.
        _cursor = _array.count-1;
        return nil;
    } else {
        return [_array objectAtIndex:_cursor];
    }
}

/** Returns YES IFF a call to nextObject would return a non-nil result. */
- (BOOL)hasNext
{
    return (_array != nil && _array.count != 0 && _cursor <= _array.count-1) ? YES : NO;
}

/** Gets the object at the current 'cursor' location in the array. Nil if operation fails. */
- (id)currentObject
{
    NSUInteger arraySize = (_array == nil) ? NSUIntegerMax : _array.count;
    if(arraySize != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_array == nil || _array.count == 0) {
        return nil;
    }
    
    return (_cursor > _array.count-1 || _cursor < 0) ? nil : [_array objectAtIndex:_cursor];
}

/** Returns YES IFF a call to previousObject would return a non-nil result. */
- (BOOL)hasPrevious
{
    return (_array != nil && _array.count != 0 && _cursor > 0) ? YES : NO;
}

/** Moves the hidden 'cursor' into the array backward and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)previousObject
{
    NSUInteger arraySize = (_array == nil) ? NSUIntegerMax : _array.count;
    if(arraySize != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_array == nil || _array.count == 0) {
        return nil;
    }
    
    _cursor--;  //go backward
    if(_cursor < 0) {
        //cursor went out of bounds, lets keep the index at the first index in the array.
        //don't want to allow going 'off the edge' of the array bounds.
        _cursor = 0;
        return nil;
    } else {
        return [_array objectAtIndex:_cursor];
    }
}

/** NSArray from the underlying enumerator. Does NOT return a copy.*/
- (NSArray *)underlyingArray
{
    return _array;
}

- (id)copyWithZone:(NSZone *)zone
{
    MZEnumerator *deepCopy = [[MZEnumerator alloc] initWithArray:_array andIndex:_cursor];
    return deepCopy;
}

@end
