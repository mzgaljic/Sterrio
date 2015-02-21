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

@interface NowPlaying : NSObject

@property (nonatomic, strong) Song *nowPlaying;
@property (nonatomic, strong) Artist *originatingArtist;
@property (nonatomic, strong) Album *originatingAlbum;
@property (nonatomic, strong) Playlist *originatingPlaylist;

+ (instancetype)sharedInstance;
- (BOOL)isEqual:(Song *)aSong;

//if the song was selected in the song tab, then only the song parameter is set. If
//the song was selected from an artist, album, or playlist, then the appropriate parameter
//will be non-nil.
- (void)setNewNowPlayingSong:(Song *)newSong
                  fromArtist:(Artist *)artist
                   fromAlbum:(Album *)album
                fromPlaylist:(Playlist *)playlist;

@end
