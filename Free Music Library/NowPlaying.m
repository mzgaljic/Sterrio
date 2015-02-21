//
//  NowPlaying.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "NowPlaying.h"

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
    if([super init]){
        self.nowPlaying = nil;
    }
    return self;
}

//if the song was selected in the song tab, then only the song parameter is set. If
//the song was selected from an artist, album, or playlist, then the appropriate parameter
//will be non-nil.
- (void)setNewNowPlayingSong:(Song *)newSong
                 WithContext:(SongPlaybackContext)context
{
    self.nowPlaying = newSong;
    self.context = context;
}

- (BOOL)isEqual:(Song *)aSong context:(SongPlaybackContext)context
{
    BOOL sameSongIDs = [self.nowPlaying.song_id isEqualToString:aSong.song_id];
    BOOL sameContexts = (self.context == context);
    return sameSongIDs && sameContexts;
}

@end
