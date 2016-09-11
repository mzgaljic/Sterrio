//
//  MZArrayShuffler.m
//  Sterrio
//
//  Created by Mark Zgaljic on 6/26/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZArrayShuffler.h"

@implementation MZArrayShuffler

+ (void)shuffleArray:(NSMutableArray **)arrayToModify
{
    if(arrayToModify == nil) {
        return;
    }
    
    //Fisher-yates algorithm
    NSUInteger count = (*arrayToModify).count;
    if(count < 1) {
        return;
    }
    for(NSUInteger i = 0; i < count -1; i++) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
        [(*arrayToModify) exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

+ (void)shuffleArray:(NSMutableArray **)arrayToModify moveItemAtIndexToFront:(NSUInteger)index
{
    if(arrayToModify == nil) {
        return;
    }
    
    //Fisher-yates algorithm
    NSUInteger count = (*arrayToModify).count;
    if(count < 1) {
        return;
    }
    NSAssert(count - 1 >= index, @"Index out of range! Index: %lu is larger than the last index of: %lu.", (unsigned long)index, count-1);
    NSAssert(index > 0, @"Index out of range! Index value of: %lu is less than 0!", (unsigned long)index);
    
    //to make the the desired element stays in front. Then shuffle the remainder of the array.
    [(*arrayToModify) exchangeObjectAtIndex:0 withObjectAtIndex:index];
    for(NSUInteger i = 1; i < count -1; i++) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
        [(*arrayToModify) exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end
