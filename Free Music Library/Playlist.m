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
#define STATUS_KEY @"status"

@implementation Playlist
@synthesize playlistName = _playlistName, songsInThisPlaylist = _songsInThisPlaylist;

static  int const SAVE_PLAYLIST = 0;
static int const DELETE_PLAYLIST = 1;
static int const UPDATE_PLAYLIST = 2;
static int const TEMP_SAVE_PLAYLIST_TO_DISK = 3;

- (id)init
{
    self = [super init];
    if (self) {
        _songsInThisPlaylist = [NSMutableArray array];
        _status = 0;  //code for playlist "in creation" mode
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        _playlistName = [aDecoder decodeObjectForKey:PLAYLIST_NAME_KEY];
        _songsInThisPlaylist = [aDecoder decodeObjectForKey:SONGS_IN_THIS_PLAYLIST_KEY];
        _status = [aDecoder decodeBoolForKey:STATUS_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_playlistName forKey:PLAYLIST_NAME_KEY];
    [aCoder encodeObject:_songsInThisPlaylist forKey:SONGS_IN_THIS_PLAYLIST_KEY];
    [aCoder encodeBool:_status forKey:STATUS_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved playlists
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].playlistsFileURL];
    if(!data){
        //if no playlists exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

///saves the current playlist (instance of this class) to the list of all playlists on disk
- (BOOL)savePlaylist
{
    return [self performModelAction:SAVE_PLAYLIST];
}

- (BOOL)saveTempPlaylistOnDisk
{
    return [self performModelAction:TEMP_SAVE_PLAYLIST_TO_DISK];
}

+ (Playlist *)loadTempPlaylistFromDisk
{
    //load the playlist object
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].tempPlaylistsFileURL];
    if(!data){
        //if no data, no playlist object was actually archived.
        return [[Playlist alloc] init];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded playlist object
}

/**
 Send an argument of nil if you'd like the temporary playlist on disk to be deleted. Otherwise, pass a
 non-nil playlist object to be inserted into the playlist model.
 */
+ (BOOL)reInsertTempPlaylist:(Playlist *)playlistToInsert
{
    if(playlistToInsert){
        //add the loaded playlist back into the main model on disk. Re-sort the model.
        NSMutableArray *playlists = (NSMutableArray *)[Playlist loadAll];
        if([playlists containsObject:playlistToInsert]){
            [playlists removeObject:playlistToInsert];
            [playlists addObject:playlistToInsert];
        }
        else
            [playlists addObject:playlistToInsert];
        
        //save changes to model on disk
        NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:playlists];  //encode playlists
        [fileData writeToURL:[FileIOConstants createSingleton].playlistsFileURL atomically:YES];
    }
    
    //delete temp playlist file on disk
    [[NSFileManager defaultManager] removeItemAtURL:[FileIOConstants createSingleton].tempPlaylistsFileURL error:nil];
    
    return YES;
}

- (BOOL)deletePlaylist
{
    return [self performModelAction:DELETE_PLAYLIST];
}

- (BOOL)updateExistingPlaylist
{
    return [self performModelAction:UPDATE_PLAYLIST];
}

- (BOOL)saveUnderNewName:(NSString *)newName
{
    NSMutableArray *playlists = (NSMutableArray *)[Playlist loadAll];
    if(playlists.count > 0){
        int index = (int)[playlists indexOfObject:self];
        _playlistName = newName;
        [playlists replaceObjectAtIndex:index withObject:self];
        
        //save changes to model on disk
        NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:playlists];  //encode playlists
        return [fileData writeToURL:[FileIOConstants createSingleton].playlistsFileURL atomically:YES];
    }
    else
        return NO;
}

- (BOOL)performModelAction:(int)desiredActionConst  //does the 'hard work' of altering the model.
{
    NSMutableArray *playlists = (NSMutableArray *)[Playlist loadAll];
    switch (desiredActionConst) {
        case SAVE_PLAYLIST:
            [playlists insertObject:self atIndex:0];  //new playlists will appear at top of 'list'
            break;
            
        case DELETE_PLAYLIST:
        {
            //delete the playlists object
            [playlists removeObject:self];
            break;
        }
            
        case UPDATE_PLAYLIST:
            //replace the old object saved in the array with the current object
            if(playlists.count > 0){
                [playlists replaceObjectAtIndex:[playlists indexOfObject:self] withObject:self];
            }
            break;
            
        case TEMP_SAVE_PLAYLIST_TO_DISK:
        {
            if(_songsInThisPlaylist.count > 0)  //we are adding songs to an existing playlist in the model
                [self deletePlaylist];  //temporarily delete it
            
            //save changes to model on disk
            NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:self];  //encode it
            return [fileData writeToURL:[FileIOConstants createSingleton].tempPlaylistsFileURL atomically:YES];
        }
            
        default:
            return NO;
            
    } //end of swtich
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:playlists];  //encode playlists
    return [fileData writeToURL:[FileIOConstants createSingleton].playlistsFileURL atomically:YES];
}

- (NSMutableArray *)insertNewPlaylistIntoAlphabeticalArray:(Playlist *)unInsertedPlaylist
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)  //same object instance
        return YES;
    if(!object || ![object isMemberOfClass:[self class]])  //object is nil or not a playlist object
        return NO;
    
    return ([_playlistName isEqualToString:((Playlist *)object).playlistName]) ? YES : NO;
}

/**
//each playlist must have a unique name
- (BOOL)customSmartArtistComparison:(Playlist *)mysteryPlaylist
{
    BOOL sameName = NO;
    
    if([_playlistName isEqualToString:mysteryPlaylist.playlistName])
        sameName = YES;
    
    return (sameName) ? YES : NO;
}
 */

- (NSUInteger)hash
{
    NSUInteger result = 1;
    NSUInteger prime = 31;
    //NSUInteger yesPrime = 1231;
    //NSUInteger noPrime = 1237;
    
    // Add any object that already has a hash function (NSString)
    result = prime * result + [_playlistName hash];
    result = prime * result + [_songsInThisPlaylist hash];
    
    // Add primitive variables (int)
    result = prime * result + _status;
    
    // Boolean values (BOOL)
    //result = (prime * result + _fullyCreated) ? yesPrime : noPrime;
    
    return result;
}

@end