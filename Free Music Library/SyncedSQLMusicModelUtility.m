//
//  SyncedSQLMusicModelUtility.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/5/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SyncedSQLMusicModelUtility.h"

@implementation SyncedSQLMusicModelUtility

const int ALBUMS = 10;
const int ARTISTS = 11;
const int PLAYLISTS = 12;
const int PLAYLIST_SONGS = 13;
const int SONGS = 14;
static SQLiteManager *dbManager;


+ (BOOL)tableExists:(NSString *)tableName
{
    return [dbManager isTableCreated:tableName];
}

+ (BOOL)newSQLTable:(int)tableConstant
{
    BOOL result;
    switch (tableConstant){
        case ALBUMS:
            result = [[[self alloc]init] newAlbumsSQLTable];
            break;
            
        case ARTISTS:
            result = [[[self alloc]init] newArtistsSQLTable];
            break;
        
        case PLAYLISTS:
            result = [[[self alloc]init] newPlaylistsSQLTable];
            break;
            
        case PLAYLIST_SONGS:
            result = [[[self alloc]init] newPlaylistSongsSQLTable];
            break;
            
        case SONGS:
            result = [[[self alloc]init] newSongsSQLTable];
            break;
        
        default:
            result = NO;
            break;
    }
    return result;
}

+ (BOOL)initAllModels
{   //!!WARNING!! Switch statement MUST be modified if objects are added to the array (or the order is switched)
    NSArray *allTables = [NSArray arrayWithObjects:@"Albums", @"Artists", @"Playlists", @"PlaylistSongs", @"Songs", nil];
    for(int i = 0; i < [allTables count]; i++){
        if([SyncedSQLMusicModelUtility tableExists:allTables[i]]){
            //table at index i already exists in DB
            break;
        } else{
            //DB doesn't contain table at index i yet, lets create it.
            switch (i) {
                case 0:
                    [SyncedSQLMusicModelUtility newSQLTable:ALBUMS];
                    break;
                    
                case 1:
                    [SyncedSQLMusicModelUtility newSQLTable:ARTISTS];
                    break;
                    
                case 2:
                    [SyncedSQLMusicModelUtility newSQLTable:PLAYLISTS];
                    break;
                    
                case 3:
                    [SyncedSQLMusicModelUtility newSQLTable:PLAYLIST_SONGS];
                    break;
                    
                case 4:
                    [SyncedSQLMusicModelUtility newSQLTable:SONGS];
                    break;
                    
                default:
                    return NO;  //undefined case, initialization failed.
            }
        }
    }
    return YES;  //for loop completed, all tables must have been initialized.
}

- (BOOL)newAlbumsSQLTable
{
    NSString *newTableStatement = @"CREATE TABLE Albums(id integer primary key autoincrement, artist_id integer, genre_id integer, name varchar, release_year integer);";
    NSError *errorOccured = [dbManager doQuery:newTableStatement];
	if (errorOccured) {
		NSLog(@"Error creating Albums table: %@",[errorOccured localizedDescription]);
        return NO;
	}
    else
        return YES;
}

- (BOOL)newArtistsSQLTable
{
    NSString *newTableStatement = @"CREATE TABLE Artists(id integer primary key autoincrement, name varchar);";
    NSError *errorOccured = [dbManager doQuery:newTableStatement];
	if (errorOccured) {
		NSLog(@"Error creating Artists table: %@",[errorOccured localizedDescription]);
        return NO;
	}
    else
        return YES;
}

- (BOOL)newPlaylistsSQLTable
{
    NSString *newTableStatement = @"CREATE TABLE Playlists(id integer primary key autoincrement, name varchar);";
    NSError *errorOccured = [dbManager doQuery:newTableStatement];
	if (errorOccured) {
		NSLog(@"Error creating Playlists table: %@",[errorOccured localizedDescription]);
        return NO;
	}
    else
        return YES;
}

- (BOOL)newPlaylistSongsSQLTable
{
    NSString *newTableStatement = @"CREATE TABLE PlaylistSongs(playlist_id integer , playlist_table_id integer, song_id integer);";
    NSError *errorOccured = [dbManager doQuery:newTableStatement];
	if (errorOccured) {
		NSLog(@"Error creating PlaylistSongs table: %@",[errorOccured localizedDescription]);
        return NO;
	}
    else
        return YES;
}

- (BOOL)newSongsSQLTable
{
    NSString *newTableStatement = @"CREATE TABLE Songs(id integer primary key autoincrement, album_id integer, artist_id integer, name varchar,youtube_link varchar);";
    NSError *errorOccured = [dbManager doQuery:newTableStatement];
	if (errorOccured) {
		NSLog(@"Error creating PlaylistSongs table: %@",[errorOccured localizedDescription]);
        return NO;
	}
    else
        return YES;
}

@end
