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
@property (nonatomic, strong) NSArray *originalData;
@property (nonatomic, strong) NSMutableArray *arrayWithTolerance;
@property (nonatomic, assign) NSUInteger lastKnownArraySize;  //for the array w/ tolerance
@property (nonatomic, assign) NSUInteger outOfBoundsTolerance;
@end
@implementation MZEnumerator
static NSString * const CANT_INIT_WITH_NIL_ARRAY_MSG = @"Cannot itialize an MZEnumerator w/ a nil array!";

- (id)initWithArray:(NSArray *)array
{
    NSAssert(array != nil, CANT_INIT_WITH_NIL_ARRAY_MSG);
    if(self = [self initWithArray:array andIndex:0]) {
        //any additional logic...
    }
    return self;
}

- (id)initWithArray:(NSArray *)array andIndex:(NSUInteger)index
{
    NSAssert(array != nil, CANT_INIT_WITH_NIL_ARRAY_MSG);
    if(self = [super init]) {
        _cursor = index;
        _originalData = array;
        _arrayWithTolerance = [NSMutableArray arrayWithArray:array];
        _lastKnownArraySize = _arrayWithTolerance.count;
        _outOfBoundsTolerance = 0;
    }
    return self;
}

- (id)initWithArray:(NSArray *)array andIndex:(NSUInteger)index outOfBoundsTolerance:(NSUInteger)tolerance
{
    NSAssert(array != nil, CANT_INIT_WITH_NIL_ARRAY_MSG);
    if(self = [self initWithArray:array andIndex:index]) {
        _outOfBoundsTolerance = tolerance;
        
        //this is how we add some 'bounds tolerance'.
        for(int i = 0; i < tolerance; i++) {
            //pad the front and end of the array with NSNull
            [_arrayWithTolerance insertObject:[NSNull null] atIndex:0];
            [_arrayWithTolerance addObject:[NSNull null]];
        }
        _cursor = index + tolerance;
        _lastKnownArraySize = _arrayWithTolerance.count;
    }
    return self;
}

- (void)dealloc
{
    _arrayWithTolerance = nil;
    _originalData = nil;
}

/** Moves the 'cursor' to the first element, if applicable.
    Otherwise nil is returned (out of bounds.)*/
- (id)moveTofirstObject
{
    if(_arrayWithTolerance.count != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_arrayWithTolerance.count == 0) {
        return nil;
    }
    _cursor = 0;
    while(_arrayWithTolerance[_cursor] == [NSNull null]) {
        //find first element that's not part of the 'out of bounds' tolerance padding.
        _cursor++;
    }
    return [_arrayWithTolerance objectAtIndex:_cursor];
}

/** Advances the hidden 'cursor' into the array and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds, including tolerance). */
- (id)nextObject
{
    if(_arrayWithTolerance.count != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_arrayWithTolerance.count == 0) {
        return nil;
    }
    
    _cursor++;  //advance
    if(_cursor > _arrayWithTolerance.count-1) {
        //cursor went out of bounds, lets keep the index at the last index in the array.
        //don't want to allow going 'off the edge' of the physical array bounds.
        _cursor = _arrayWithTolerance.count-1;
        return nil;
    } else {
        return [_arrayWithTolerance objectAtIndex:_cursor];
    }
}

/** Returns YES IFF a call to nextObject would return a non-nil result. */
- (BOOL)hasNext
{
    if(_arrayWithTolerance.count != 0
       && _cursor <= _arrayWithTolerance.count-1
       && _arrayWithTolerance[_cursor] != [NSNull null]) {
        return YES;
    } else {
        return NO;
    }
}

/** 
 Gets the object at the current 'cursor' location in the array. Nil if operation fails or if
 you hit the 'tolerance' zone.
 */
- (id)currentObject
{
    if(_arrayWithTolerance.count != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_arrayWithTolerance.count == 0) {
        return nil;
    }
    
    if(_cursor > _arrayWithTolerance.count-1
       || _cursor < 0
       || _arrayWithTolerance[_cursor] == [NSNull null]) {
        return nil;
    } else {
        return [_arrayWithTolerance objectAtIndex:_cursor];
    }
}

/** Returns YES IFF a call to previousObject would return a non-nil result. */
- (BOOL)hasPrevious
{
    if(_arrayWithTolerance.count != 0 && _cursor > 0 && _arrayWithTolerance[_cursor] != [NSNull null]) {
        return YES;
    } else {
        return NO;
    }
}

/** Moves the hidden 'cursor' into the array backward and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)previousObject
{
    if(_arrayWithTolerance.count != _lastKnownArraySize) {
        @throw NSInternalInconsistencyException;
    }
    if(_arrayWithTolerance.count == 0) {
        return nil;
    }
    
    _cursor--;  //go backward
    if(_cursor < 0) {
        //cursor went out of bounds, lets keep the index at the first index in the array.
        //don't want to allow going 'off the edge' of the physical array bounds.
        _cursor = 0;
        return nil;
    } else {
        return [_arrayWithTolerance objectAtIndex:_cursor];
    }
}

/** NSArray from the underlying enumerator. Does NOT return a copy.*/
- (NSArray *)underlyingArray
{
    return _originalData;
}

- (id)copyWithZone:(NSZone *)zone
{
    MZEnumerator *deepCopy = [[MZEnumerator alloc] initWithArray:_originalData
                                                        andIndex:_cursor
                                            outOfBoundsTolerance:_outOfBoundsTolerance];
    return deepCopy;
}

@end
