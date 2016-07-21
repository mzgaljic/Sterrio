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

@end
