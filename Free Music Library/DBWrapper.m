//
//  DBWrapper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "DBWrapper.h"

@implementation DBWrapper
+ (NSArray*)LibraryAlbums
{
    return nil;
}

+ (NSArray*)LibraryPlaylists
{
    return nil;
}

+ (BOOL)addSongToLibrary: (Song*)aSong withAlbum: (Album*)anAlbum withAlbumReleaseDate: (NSDate*)releaseDate withGenre: (Genre*)aGenre withOptionalPlaylist: (Playlist*)aPlaylist
{
    return NO;
}

+ (BOOL)addExisitingSongToPlaylist: (Song*)aSong withAlbum: (Album*)anAlbum withGenre: (Genre*)aGenre withOptionalPlaylist: (Playlist*)aPlaylist
{
    return NO;
}

+ (BOOL)createNewPlaylistWithName: (NSString*)playlistName
{
    return NO;
}

+ (BOOL)initializeNewPlaylistWithName: (NSString*)playlistName withSongs: (NSArray*)listOfSongs
{
    return NO;
}

@end
