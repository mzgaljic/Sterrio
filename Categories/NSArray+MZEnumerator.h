//
//  NSArray+MZEnumerator.h
//  Sterrio
//
//  Created by Mark Zgaljic on 6/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZEnumerator.h"

@interface NSArray (MZEnumerator)

- (MZEnumerator *)biDirectionalEnumerator;
- (MZEnumerator *)biDirectionalEnumeratorAtIndex:(NSUInteger)index;
- (MZEnumerator *)biDirectionalEnumeratorWithOutOfBoundsTolerance:(NSUInteger)tolerance;
- (MZEnumerator *)biDirectionalEnumeratorAtIndex:(NSUInteger)index
                        withOutOfBoundsTolerance:(NSUInteger)tolerance;

@end
