//
//  NSArray+MZEnumerator.m
//  Sterrio
//
//  Created by Mark Zgaljic on 6/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "NSArray+MZEnumerator.h"

@implementation NSArray (MZEnumerator)

- (MZEnumerator *)biDirectionalEnumerator
{
    return [[MZEnumerator alloc] initWithArray:self];
}

- (MZEnumerator *)biDirectionalEnumeratorAtIndex:(NSUInteger)index
{
    return [[MZEnumerator alloc] initWithArray:self andIndex:index];
}

@end
