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
        self.nowPlayingPlaylist = nil;
        self.context = SongPlaybackContextUnspecified;
    }
    return self;
}

//if the song was selected in the song tab, then only the song parameter is set. If
//the song was selected from an artist, album, or playlist, then the appropriate parameter
//will be non-nil.
- (void)setNewNowPlayingSong:(Song *)newSong
                 WithContext:(SongPlaybackContext)context
            optionalPlaylist:(Playlist *)playlist
{
    self.nowPlaying = newSong;
    self.context = context;
    self.nowPlayingPlaylist = playlist;
}

- (BOOL)isEqual:(Song *)aSong
        context:(SongPlaybackContext)context
optionalPlaylist:(Playlist *)playlist
{
    BOOL sameSongIDs = [self.nowPlaying.song_id isEqualToString:aSong.song_id];
    BOOL sameContexts = (self.context == context);
    
    if(playlist == nil)
        return sameSongIDs && sameContexts;
    else{
        BOOL samePlaylists = [self.nowPlayingPlaylist.playlist_id isEqualToString:playlist.playlist_id];
        return sameSongIDs && sameContexts && samePlaylists;
    }
}

@end
