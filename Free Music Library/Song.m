//
//  Song.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Song.h"
#import "Album.h"
#import "FileIOConstants.h"
#define SONG_NAME_KEY @"songName"
#define YOUTUBE_LINK_KEY @"youtubeLink"
#define ALBUM_ART_FILE_NAME_KEY @"albumArtFileName"
#define ALBUM_KEY @"album"
#define ARTIST_KEY @"artist"
#define GENRE_CODE_KEY @"songGenreCode"
#define ASSOCIATED_WITH_ALBUM_KEY @"associatedWithAlbum"

@implementation Song
@synthesize songName, youtubeLink, albumArtFileName, album = _album, artist, genreCode, associatedWithAlbum;

static  int const SAVE_SONG = 0;
static int const DELETE_SONG = 1;
static int const UPDATE_SONG = 2;

//custom property setter
- (void)setAlbum:(Album *)album
{
    //when this song is associated w/ an album, add this song to its albumSongs array
    _album = album;
    if(!album.albumSongs)
        album.albumSongs = [NSMutableArray array];
    [_album.albumSongs addObject:self];
}

/**
-(id)init
{
    //set associted with album boolean value?
}
 */

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.songName = [aDecoder decodeObjectForKey:SONG_NAME_KEY];
        self.youtubeLink = [aDecoder decodeObjectForKey:YOUTUBE_LINK_KEY];
        self.albumArtFileName = [aDecoder decodeObjectForKey:ALBUM_ART_FILE_NAME_KEY];
        self.album = [aDecoder decodeObjectForKey:ALBUM_KEY];
        self.artist = [aDecoder decodeObjectForKey:ARTIST_KEY];
        self.genreCode = [aDecoder decodeIntForKey:GENRE_CODE_KEY];
        self.associatedWithAlbum = [aDecoder decodeBoolForKey:ASSOCIATED_WITH_ALBUM_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.songName forKey:SONG_NAME_KEY];
    [aCoder encodeObject:self.youtubeLink forKey:YOUTUBE_LINK_KEY];
    [aCoder encodeObject:self.albumArtFileName forKey:ALBUM_ART_FILE_NAME_KEY];
    [aCoder encodeObject:self.album forKey:ALBUM_KEY];
    [aCoder encodeObject:self.artist forKey:ARTIST_KEY];
    [aCoder encodeInteger:self.genreCode forKey:GENRE_CODE_KEY];
    [aCoder encodeBool:self.associatedWithAlbum forKey:ASSOCIATED_WITH_ALBUM_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved songs
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].songsFileURL];
    if(!data){
        //if no songs exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)saveSong  //saves the current song (instance of this class) to the list of all songs on disk
{
    return [self performModelAction:SAVE_SONG];
}

- (BOOL)deleteSong
{
    return [self performModelAction:DELETE_SONG];
}

- (BOOL)updateExistingSong
{
    return [self performModelAction:UPDATE_SONG];
}

- (BOOL)performModelAction:(int)desiredActionConst  //does the 'hard work' of altering the model.
{
    NSMutableArray *songs = (NSMutableArray *)[Song loadAll];
    switch (desiredActionConst) {
        case SAVE_SONG:
            [songs insertObject:self atIndex:0]; //new songs added to array will appear at top of 'list'
            break;
            
        case DELETE_SONG:
        {
            //is this the last song in an album? If so, delete the album too.
          //  if(self.album.albumSongs.count == 1)  //BROKEN CODE
            //    [self.album deleteAlbum];
            
            //remove songs from any playlists?
            
            //remove the actual song from model on disk and from albums list of songs
            [songs removeObject:self];
            [self.album.albumSongs removeObject:self];
            break;

        }
    
        case UPDATE_SONG:
            //replace the old object saved in the array with the current object
            if(songs.count > 0){
                [songs replaceObjectAtIndex:[songs indexOfObject:self] withObject:self];
            }
            break;
            
        default:
            return NO;
            
    } //end of swtich
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:songs];  //encode songs
    return [fileData writeToURL:[FileIOConstants createSingleton].songsFileURL atomically:YES];
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
}

- (NSMutableArray *)insertNewSongIntoAlphabeticalArray:(Song *)unInsertedSong
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)  //same object instance
        return YES;
    if(!object || ![object isMemberOfClass:[self class]])  //object is nil or not an album object
        return NO;
    
    return ([self customSmartAlbumComparison:(Song *)object]) ? YES : NO;
}

- (BOOL)customSmartAlbumComparison:(Song *)mysterySong
{
    BOOL sameSongName = NO, sameAlbumName = YES;
    //check if album names are equal -remember, every album name needs to be unique.
    if([self.album.albumName isEqualToString:mysterySong.album.albumName])
        sameAlbumName = YES;
    if([self.songName isEqualToString:mysterySong.songName])
        sameSongName = YES;
    
    return (sameAlbumName && sameSongName) ? YES : NO;
}

-(NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    NSUInteger yesPrime = 1231;
    NSUInteger noPrime = 1237;
    
    // Add any object that already has a hash function (NSString)
    result = prime * result + [self.songName hash];
    result = prime * result + [self.youtubeLink hash];
    result = prime * result + [self.albumArtFileName hash];
    
    result = prime * result + [self.album.albumName hash];
    result = prime * result + [self.album.releaseDate hash];
    result = prime * result + [self.album.albumArtFileName hash];
    result = prime * result + [self.album.albumSongs hash];
    
    result = prime * result + [self.artist.artistName hash];
    
    //Add primitive variables (int)
    result = prime * result + self.genreCode;
    result = prime * result + self.album.genreCode;
    
    //Boolean values (BOOL)
    result = (prime * result + self.associatedWithAlbum) ? yesPrime : noPrime;
    
    return result;
}

@end