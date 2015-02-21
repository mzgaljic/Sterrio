//
//  NowPlaying.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Artist.h"
#import "Album.h"
#import "Playlist.h"

typedef enum{
    SongPlaybackContextSongs,
    SongPlaybackContextAlbums,
    SongPlaybackContextArtists,
    SongPlaybackContextPlaylists,
    SongPlaybackContextUnspecified
} SongPlaybackContext;

@interface NowPlaying : NSObject

@property (nonatomic, strong) Song *nowPlaying;
@property (nonatomic, assign) SongPlaybackContext context;

+ (instancetype)sharedInstance;
- (BOOL)isEqual:(Song *)aSong context:(SongPlaybackContext)context;

- (void)setNewNowPlayingSong:(Song *)newSong
                 WithContext:(SongPlaybackContext)context;

@end
