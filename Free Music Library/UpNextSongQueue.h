//
//  UpNextSongQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Deque.h"
#import "Song.h"
#import "Album.h"
#import "Playlist.h"
#import "Artist.h"

@interface UpNextSongQueue : Deque

+ (void)addSongToUpNext:(Song *)aSong;
+ (void)addSongsToUpNext:(NSArray *)aSongs;
+ (void)addAlbumToUpNext:(Album *)anAlbum;
+ (void)addPlaylistToUpNext:(Playlist *)aPlaylist;
+ (void)addAllSongsFromTheArtist:(Artist *)anArtist;
+ (Song *)nextSong;
+ (NSArray *)listOfUpNextSongs;
+ (void)changeOrderOfUpNextTo:(NSArray *)reorderedSongs;

@end