//
//  PlaybackContext.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlaybackContext.h"

@implementation PlaybackContext

- (instancetype)initWithFetchRequest:(NSFetchRequest *)aRequest
                     prettyQueueName:(NSString *)name
                           contextId:(NSString *)anIdentifier
{
    if(self = [super init]){
        _request = aRequest;
        _queueName = name;
        _contextId = anIdentifier;
        NSAssert(anIdentifier != nil, @"Error: a playback context was created w/out an id.");
    }
    return self;
}

- (BOOL)isEqualToContext:(PlaybackContext *)someContext
{
    return [_contextId isEqualToString:someContext.contextId];
}


@end
