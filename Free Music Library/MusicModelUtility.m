//
//  MusicModelUtility.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicModelUtility.h"
#import "MusicModel.h"
#import "GenreConstants.h"

@implementation MusicModelUtility
static MusicModel *modelPointer = nil;

//creating new songs, albums, artists, and playlists. All returns their respective ID's
+ (int)newSongWithName:(NSString *)songName withLink:(NSString *)aLink
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)newPlaylistWithName:(NSString *)playlistName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}
+ (int)newArtistWithName:(NSString *)artistName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)newAlbumWithName:(NSString *)albumName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    
}

//adding existing content to other content/categories in the music library
+ (BOOL)addExistingSongWithID:(int)songID
        toExistingAlbumWithID:(int)albumID
       toExistingArtistWithID:(int)artistID
                      toGenre:(int)genreID
     toExistingPlaylistWithID:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (BOOL)addExisitingAlbumWithID:(int)albumID
         toExistingArtistWithID:(int)artistID
                  toGenreWithID:(int)genreID
      toExisitingPlaylistWithID:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (BOOL)addExistingArtistWithID:(int)artistID toExistingPlaylistWithID:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (BOOL)addExistingPlaylistWithID:(int)sourcePlaylistID toExistingPlaylistWithID:(int)destinationPlaylistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

//obtain an ID given other information. To use, provide as much information as you can, and provide nil as ab argument to unknown paramters.
+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithName:(NSString *)albumName fromArtistWithName:(NSString *)artistName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithID:(int)albumID fromArtistWithName:(NSString *)artistName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithName:(NSString *)albumName fromArtistWithID:(int)artistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithID:(int)albumID fromArtistWithID:(int)artistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertAlbumNameToAlbumID:(NSString *)albumName containingSongName:(NSString *)songName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertAlbumNameToAlbumID:(NSString *)albumName containingSongID:(int)songID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithName:(NSString *)songName singerOfAlbumWithName:(NSString *)albumName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithID:(int)songID singerOfAlbumWithName:(NSString *)albumName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithName:(NSString *)songName singerOfAlbumWithID:(int)albumID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithID:(int)songID singerOfAlbumWithID:(int)albumID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

//obtain content name given its ID.
+ (NSString *)convertSongIDToSongName:(int)songID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (NSString *)convertAlbumIDToAlbumName:(int)albumID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (NSString *)convertArtistIDToArtistName:(int)artistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
}

+ (NSString *)convertPlaylistIDToPlaylistName:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    //execute sql statement
    
    //update model (appropriate array)
}

+ (NSString *)convertGenreIDToGenreName:(int)GenreID
{
    return [[GenreConstants createSingleton] genreCodeToString:GenreID];
}


+ (void)createMusicModelSingletonIfNotAlreadyCreated
{
    modelPointer = [MusicModel createSingleton];
}

@end
