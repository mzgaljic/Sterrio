//
//  NowPlayingSong.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "NowPlayingSong.h"

@implementation NowPlayingSong

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
        self.nowPlaying = nil;
        self.context = nil;
    }
    return self;
}

- (BOOL)isEqualToSong:(Song *)aSong
   compareWithContext:(PlaybackContext *)aContext
{
    BOOL sameSongIDs = [self.nowPlaying.uniqueId isEqualToString:aSong.uniqueId];
    BOOL sameContexts = ([self.context isEqualToContext:aContext]
                         || (self.context == nil && aContext == nil));
    return (sameSongIDs && sameContexts);
}

- (void)setNewNowPlayingSong:(Song *)newSong
                     context:(PlaybackContext *)aContext
{
    self.nowPlaying = newSong;
    self.context = aContext;
}

- (void)setPlayingBackFromPlayNextSongs:(BOOL)isTrue
{
    _isFromPlayNextSongs = isTrue;
}

@end
