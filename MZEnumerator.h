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
@interface MZEnumerator : NSObject

/** Initialize w/ array. Modification of array during enumeration will result in an exception! */
- (id)initWithArray:(NSArray *)array;
- (id)initWithArray:(NSArray *)array andIndex:(NSUInteger)index;

/** Advances the hidden 'cursor' into the array and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)nextObject;

/** Moves the hidden 'cursor' into the array backward and retrieves the value at the new location. Nil if no more objects in this direction (out of bounds). */
- (id)previousObject;

@end
