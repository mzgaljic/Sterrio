//
//  OperationQueuesSingeton.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/25/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "OperationQueuesSingeton.h"

@interface OperationQueuesSingeton ()
{
    NSOperationQueue *loadingSongsOpQueue;
}
@end
@implementation OperationQueuesSingeton

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if(self = [super init]){
        loadingSongsOpQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (NSOperationQueue *)loadingSongsOpQueue
{
    return loadingSongsOpQueue;
}

@end
