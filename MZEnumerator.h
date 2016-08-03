//
//  MZEnumerator.h
//  Sterrio
//
//  Created by Mark Zgaljic on 6/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//
// A lightweight way of performing bi-directional enumeration. Sorta treats an NSArray like a linked list.

#import <Foundation/Foundation.h>

//WARNING: ENUMERATOR DOES NOT ALLOW ARRAY SIZE TO CHANGE DURING ENUMERATION
@interface MZEnumerator : NSObject <NSCopying>

/** Initialize w/ array. Modification of array during enumeration will result in an exception! 
 Starts at index 0.*/
- (id)initWithArray:(NSArray *)array;
- (id)initWithArray:(NSArray *)array andIndex:(NSUInteger)index;

/** Moves the hidden 'cursor' into the array to position 0, if applicable. Otherwise nil is returned 
 * (out of bounds.)*/
- (id)moveTofirstObject;

/** Advances the hidden 'cursor' into the array and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)nextObject;

/** Returns YES IFF a call to nextObject would return a non-nil result. */
- (BOOL)hasNext;

/** Gets the object at the current 'cursor' location in the array. Nil if operation fails. */
- (id)currentObject;

/** Returns YES IFF a call to previousObject would return a non-nil result. */
- (BOOL)hasPrevious;

/** Moves the hidden 'cursor' into the array backward and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)previousObject;

/** NSArray from the underlying enumerator. Does NOT return a copy. */
- (NSArray *)underlyingArray;

@end
