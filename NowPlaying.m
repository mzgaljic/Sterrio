//
//  NowPlayingSong.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "NowPlaying.h"
#import "PlayableItem.h"

@implementation NowPlaying

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
        _nowPlayingItem = nil;
    }
    return self;
}

- (BOOL)isEqualToItem:(PlayableItem *)anItem
{
    return [_nowPlayingItem isEqualToItem:anItem];
}

- (void)setNewNowPlayingItem:(PlayableItem *)newItem
{
    _nowPlayingItem = newItem;
}

@end
