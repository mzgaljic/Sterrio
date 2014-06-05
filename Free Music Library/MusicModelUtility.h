//
//  MusicModelUtility.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicModel.h"

@interface MusicModelUtility : NSObject //generate singletons inside of these class methods to update the properties in MusicModel.m

//creating new songs, albums, artists, and playlists. All returns their respective ID's
+ (int)newSongWithName:(NSString *)songName withLink:(NSString *)aLink;
+ (int)newPlaylistWithName:(NSString *)playlistName;
+ (int)newArtistWithName:(NSString *)artistName;
+ (int)newAlbumWithName:(NSString *)albumName;

//adding existing content to other content/categories in the music library
+ (BOOL)addExistingSongWithID:(int)songID
        toExistingAlbumWithID:(int)albumID
       toExistingArtistWithID:(int)artistID
                      toGenre:(int)genreID
     toExistingPlaylistWithID:(int)playlistID;  //arguments optional...can be nil.

+ (BOOL)addExisitingAlbumWithID:(int)albumID
         toExistingArtistWithID:(int)artistID
                  toGenreWithID:(int)genreID
      toExisitingPlaylistWithID:(int)playlistID;

+ (BOOL)addExistingArtistWithID:(int)artistID toExistingPlaylistWithID:(int)playlistID;

+ (BOOL)addExistingPlaylistWithID:(int)sourcePlaylistID toExistingPlaylistWithID:(int)destinationPlaylistID;

//obtain an ID given other information. To use, provide as much information as you can, and provide nil as ab argument to unknown paramters.
+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithName:(NSString *)albumName fromArtistWithName:(NSString *)artistName;
+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithID:(int)albumID fromArtistWithName:(NSString *)artistName;
+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithName:(NSString *)albumName fromArtistWithID:(int)artistID;
+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithID:(int)albumID fromArtistWithID:(int)artistID;

+ (int)convertAlbumNameToAlbumID:(NSString *)albumName containingSongName:(NSString *)songName;
+ (int)convertAlbumNameToAlbumID:(NSString *)albumName containingSongID:(int)songID;

+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithName:(NSString *)songName singerOfAlbumWithName:(NSString *)albumName;
+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithID:(int)songID singerOfAlbumWithName:(NSString *)albumName;
+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithName:(NSString *)songName singerOfAlbumWithID:(int)albumID;
+ (int)convertArtistNameToArtistID:(NSString *)artistName singerOfSongWithID:(int)songID singerOfAlbumWithID:(int)albumID;

//obtain content name given its ID.
+ (NSString *)convertSongIDToSongName:(int)songID;
+ (NSString *)convertAlbumIDToAlbumName:(int)albumID;
+ (NSString *)convertArtistIDToArtistName:(int)artistID;
+ (NSString *)convertPlaylistIDToPlaylistName:(int)playlistID;
+ (NSString *)convertGenreIDToGenreName:(int)GenreID;

@end
