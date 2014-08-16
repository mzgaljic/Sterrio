//
//  StackController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "StackController.h"

@implementation StackController  //flag added in build settings since this is a non-arc class.

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        stack = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addBlock:(void (^)())block
{
    @synchronized(stack)
    {
        [stack addObject:[[block copy] autorelease]];
    }
    
    if (stack.count == 1)
    {
        // If the stack was empty before this block was added, processing has ceased, so start processing.
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(queue, ^{
            [self startNextBlock];
        });
    }
}

- (void)startNextBlock
{
    if (stack.count > 0)
    {
        @synchronized(stack)
        {
            id blockToPerform = [stack lastObject];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(queue, ^{
                [StackController performBlock:[[blockToPerform copy] autorelease]];
            });
            
            [stack removeObject:blockToPerform];
        }
        
        [self startNextBlock];
    }
}

+ (void)performBlock:(void (^)())block
{
    @autoreleasepool {
        block();
    }
}

- (void)dealloc {
    [stack release];
    [super dealloc];
}

@end
