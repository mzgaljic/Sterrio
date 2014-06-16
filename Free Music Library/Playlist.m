//
//  Playlist.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Playlist.h"
#import "FileIOConstants.h"
#define PLAYLIST_NAME_KEY @"playlistName"
#define SONGS_IN_THIS_PLAYLIST_KEY @"songsInThisPlaylist"

@implementation Playlist
@synthesize playlistName, songsInThisPlaylist;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.playlistName = [aDecoder decodeObjectForKey:PLAYLIST_NAME_KEY];
        self.songsInThisPlaylist = [aDecoder decodeObjectForKey:SONGS_IN_THIS_PLAYLIST_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.playlistName forKey:PLAYLIST_NAME_KEY];
    [aCoder encodeObject:self.songsInThisPlaylist forKey:SONGS_IN_THIS_PLAYLIST_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved playlists
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].libraryFileURL];
    if(!data){
        //if no playlists exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)save  //saves the current playlist (instance of this class) to the list of all playlists on disk
{
    NSMutableArray *playlists = (NSMutableArray *)[Playlist loadAll];
    
    //should sort this array based on alphabetical order!
    [playlists insertObject:self atIndex:0];  //new playlists added to array will appear at top of 'list'
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:playlists];  //encode playlists
    return [fileData writeToURL:[FileIOConstants createSingleton].libraryFileURL atomically:YES];
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
}

- (NSMutableArray *)insertNewPlaylistIntoAlphabeticalArray:(Playlist *)unInsertedPlaylist
{
    return nil;
}

@end
