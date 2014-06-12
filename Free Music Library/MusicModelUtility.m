//
//  MusicModelUtility.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicModelUtility.h"

@implementation MusicModelUtility
static SQLiteManager *dbManager;
static MusicModel *modelPointer = nil;
static GenreConstants *genreConstantsPointer = nil;

//creating new songs, albums, artists, and playlists. All methods return their respective ID's
+ (unsigned int)newSongWithName:(NSString *)songName withLink:(NSString *)aLink
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    if(songName == nil || aLink == nil)  //nil values should never be provided.
        return -1;
    
    //execute sql statement to insert new song 'record' into the Songs table.
    NSString *statement = [NSString stringWithFormat:@"INSERT INTO Songs(id, album_id, artist_id, name, youtube_link)                                                                     VALUES (NULL, %i, %i, \"%@\", \"%@\");", modelPointer.NO_ID_VALUE, modelPointer.NO_ID_VALUE, songName, aLink];
    NSError *errorOccured = [dbManager doQuery:statement];
	if (errorOccured) {
		NSLog(@"Error adding new song to Songs table: %@",[errorOccured localizedDescription]);
        return modelPointer.NO_ID_VALUE;  //something went wrong, no valid id to return.
	}
    else{
        //update model
        unsigned int key = (unsigned int)[[[dbManager getRowsForQuery: @"SELECT * FROM Songs where id IN (SELECT MAX(id) FROM Songs);"] objectAtIndex:0] objectForKey:@"id"];
        [modelPointer.songDictionary setObject:songName forKey: [NSNumber numberWithInt:key + 1]];
        return key;
    }
}

+ (unsigned int)newPlaylistWithName:(NSString *)playlistName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    if(playlistName == nil)  //nil values should never be provided.
        return -1;

    //execute sql statement to insert new song 'record' into the Songs table.
    NSString *statement = [NSString stringWithFormat:@"INSERT INTO Playlists(id, name) VALUES (NULL, \"%@\");", playlistName];
    NSError *errorOccured = [dbManager doQuery:statement];
	if (errorOccured) {
		NSLog(@"Error creating new playlist in DB: %@",[errorOccured localizedDescription]);
        return modelPointer.NO_ID_VALUE;  //something went wrong, no valid id to return.
	}
    else{
        //update model
        unsigned int key = (unsigned int)[[[dbManager getRowsForQuery:@"SELECT * FROM Playlists where id IN (SELECT MAX(id) FROM Playlists);"] objectAtIndex:0] objectForKey:@"id"];
        [modelPointer.playlistDictionary setObject:playlistName forKey: [NSNumber numberWithInt:key + 1]];
        return key;
    }
}
+ (unsigned int)newArtistWithName:(NSString *)artistName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    if(artistName == nil)  //nil values should never be provided.
        return -1;

    //execute sql statement to insert new song 'record' into the Songs table.
    NSString *statement = [NSString stringWithFormat:@"INSERT INTO Artists(id, name) VALUES (NULL, \"%@\");", artistName];
    NSError *errorOccured = [dbManager doQuery:statement];
	if (errorOccured) {
		NSLog(@"Error creating new playlist in DB: %@",[errorOccured localizedDescription]);
        return modelPointer.NO_ID_VALUE;  //something went wrong, no valid id to return.
	}
    else{
        //update model
        unsigned int key = (unsigned int)[[[dbManager getRowsForQuery: @"SELECT * FROM Artists where id IN (SELECT MAX(id) FROM Artists);"] objectAtIndex:0] objectForKey:@"id"];
        [modelPointer.artistDictionary setObject:artistName forKey: [NSNumber numberWithInt:key + 1]];
        return key;
    }
}

+ (unsigned int)newAlbumWithName:(NSString *)albumName
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    if(albumName == nil)  //nil values should never be provided.
        return -1;
    
    //execute sql statement to insert new song 'record' into the Songs table.
    NSString *statement = [NSString stringWithFormat:@"INSERT INTO Albums(id, artist_id, genre_id, name, release_year) VALUES (NULL, %i, %i, \"%@\", %i);", modelPointer.NO_ID_VALUE, modelPointer.NO_ID_VALUE, albumName, modelPointer.NO_ID_VALUE];
    NSError *errorOccured = [dbManager doQuery:statement];
	if (errorOccured) {
		NSLog(@"Error creating new playlist in DB: %@",[errorOccured localizedDescription]);
        return modelPointer.NO_ID_VALUE;  //something went wrong, no valid id to return.
	}
    else{
        //update model
        unsigned int key = (unsigned int)[[[dbManager getRowsForQuery: @"SELECT * FROM Albums where id IN (SELECT MAX(id) FROM Albums);"] objectAtIndex:0] objectForKey:@"id"];
        [modelPointer.albumDictionary setObject:albumName forKey: [NSNumber numberWithInt:key + 1]];
        return key;
    }
}

//----------------------------------------
//adding existing content to other content/categories in the music library
+ (BOOL)addExistingSongWithID:(int)songID
        toExistingAlbumWithID:(int)albumID
       toExistingArtistWithID:(int)artistID
                      toGenre:(int)genreID
     toExistingPlaylistWithID:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    NSString *sqlString = @"UPDATE Songs SET id = ?, album_id = ?, artist_id = ?, name = ?, youtube_link = ? WHERE id = ?;";
    NSString *songName = [MusicModelUtility convertSongIDToSongName: songID];
    [self doUpdateQuery: sqlString withParams:[NSArray arrayWithObjects: songID, albumID, artistID, songName, nil]];
}

+ (BOOL)addExisitingAlbumWithID:(int)albumID
         toExistingArtistWithID:(int)artistID
                  toGenreWithID:(int)genreID
      toExisitingPlaylistWithID:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    //execute sql query
    //update model where necessary
}

+ (BOOL)addExistingArtistWithID:(int)artistID toExistingPlaylistWithID:(int)playlistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    //same as above
}

+ (BOOL)addExistingPlaylistWithID:(int)sourcePlaylistID toExistingPlaylistWithID:(int)destinationPlaylistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    //same as above
}

//---------------------------------
//obtain an ID given other information. To use, provide as much information as you can, and provide nil as an argument to unknown paramters.
+ (int)convertSongNameToSongID:(NSString *)songName fromAlbumWithName:(NSString *)albumName fromArtistWithName:(NSString *)artistName
{
    //fix this crap
    [self createMusicModelSingletonIfNotAlreadyCreated];
    
    NSArray *possibleKeys = [modelPointer.songDictionary allKeysForObject:songName];
    
    NSString *key = [temp objectAtIndex:0];
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

//------------------------------------------------
//obtain content name given its ID.
+ (NSString *)convertSongIDToSongName:(int)songID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    return [modelPointer.songDictionary objectForKey:[NSNumber numberWithInt:songID]];
}

+ (NSString *)convertAlbumIDToAlbumName:(int)albumID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    return [modelPointer.albumDictionary objectForKey:[NSNumber numberWithInt:albumID]];
}

+ (NSString *)convertArtistIDToArtistName:(int)artistID
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    return [modelPointer.artistDictionary objectForKey:[NSNumber numberWithInt:artistID]];
}

+ (NSString *)convertPlaylistIDToPlaylistName:(int)playlistID  //can't go from playlist name -> id? could 'ban' playlists with same name (by default, add a number after it!)
{
    [self createMusicModelSingletonIfNotAlreadyCreated];
    return [modelPointer.playlistDictionary objectForKey:[NSNumber numberWithInt:playlistID]];
}

+ (NSString *)convertGenreIDToGenreName:(int)genreID
{
    [self createGenreConstantsSingletonIfNotAlreadyCreated];
    return [genreConstantsPointer genreCodeToString:GenreID];
}

+ (int)convertGenreNameToGenreID:(NSString *)genreName
{
    [self createGenreConstantsSingletonIfNotAlreadyCreated];
    return [genreConstantsPointer genreStringToCode:genreName];
}


//-------------------------------------------------
//helper methods
+ (void)createMusicModelSingletonIfNotAlreadyCreated
{
    if(modelPointer)
        return;
    else
        modelPointer = [MusicModel createSingleton];
}

+ (void)createGenreConstantsSingletonIfNotAlreadyCreated
{
    if(genreConstantsPointer)
        return;
    else
        genreConstantsPointer = [GenreConstants createSingleton];
}

@end
