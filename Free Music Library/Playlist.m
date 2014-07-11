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
@synthesize playlistName = _playlistName, songsInThisPlaylist = _songsInThisPlaylist;

static  int const SAVE_PLAYLIST = 0;
static int const DELETE_PLAYLIST = 1;
static int const UPDATE_PLAYLIST = 2;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        _playlistName = [aDecoder decodeObjectForKey:PLAYLIST_NAME_KEY];
        _songsInThisPlaylist = [aDecoder decodeObjectForKey:SONGS_IN_THIS_PLAYLIST_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_playlistName forKey:PLAYLIST_NAME_KEY];
    [aCoder encodeObject:_songsInThisPlaylist forKey:SONGS_IN_THIS_PLAYLIST_KEY];
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

- (BOOL)deletePlaylist
{
    return [self performModelAction:DELETE_PLAYLIST];
}

- (BOOL)updateExistingPlaylist
{
    return [self performModelAction:UPDATE_PLAYLIST];
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
            
        default:
            return NO;
            
    } //end of swtich
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:playlists];  //encode playlists
    return [fileData writeToURL:[FileIOConstants createSingleton].playlistsFileURL atomically:YES];
}


- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
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
    
    return ([self customSmartArtistComparison:(Playlist *)object]) ? YES : NO;
}

//each playlist must have a unique name
- (BOOL)customSmartArtistComparison:(Playlist *)mysteryPlaylist
{
    BOOL sameName = NO;
    
    if([_playlistName isEqualToString:mysteryPlaylist.playlistName])
        sameName = YES;
    
    return (sameName) ? YES : NO;
}

-(NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    //NSUInteger yesPrime = 1231;
    //NSUInteger noPrime = 1237;
    
    // Add any object that already has a hash function (NSString)
    result = prime * result + [_playlistName hash];
    result = prime * result + [_songsInThisPlaylist hash];
    
    // Add primitive variables (int)
    //result = prime * result + self.genreCode;
    
    // Boolean values (BOOL)
    //result = prime * result + self.isSelected ? yesPrime : noPrime;
    
    return result;
}

@end