//
//  MZCommons.m
//  Sterrio
//
//  Created by Mark Zgaljic on 1/27/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZCommons.h"

@implementation MZCommons

void safeSynchronousDispatchToMainQueue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
