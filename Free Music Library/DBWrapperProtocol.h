//
//  DBWrapperProtocol.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/26/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Songs.h"
#import "Artists.h"
#import "Albums.h"
#import "Genres.h"
#import "Playlists.h"

@protocol DBWrapperProtocol

@required
//once loaded, album objects will have song and genre data as instance properties (among other data).
+ (NSArray*)LibraryAlbums;
+ (NSArray*)LibraryPlaylists;


+ (BOOL)addSongToLibrary: (Song*)aSong
               withAlbum: (Album*)anAlbum
    withAlbumReleaseDate: (NSDate*)releaseDate
               withGenre: (Genre*)aGenre
        withOptionalPlaylist: (Playlist*)aPlaylist;

+ (BOOL)addExisitingSongToPlaylist: (Song*)aSong
                   withAlbum: (Album*)anAlbum withGenre: (Genre*)aGenre
        withOptionalPlaylist: (Playlist*)aPlaylist;

+ (BOOL)createNewPlaylistWithName: (NSString*)playlistName;

+ (BOOL)initializeNewPlaylistWithName: (NSString*)playlistName
                            withSongs: (NSArray*)listOfSongs;

@end

@interface MusicLibraryFileIO : NSObject
@end
