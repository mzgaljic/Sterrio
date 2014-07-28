//
//  Album.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Album.h"
#define ALBUM_NAME_KEY @"albumName"
#define RELEASE_DATE_KEY @"releaseDate"
#define ALBUM_ART_FILE_NAME_KEY @"albumArtFileName"
#define ARTIST_KEY @"artist"
#define ALBUM_SONGS_KEY @"albumSongs"
#define GENRE_CODE_KEY @"albumGenreCode"
#define ALBUM_ID_KEY @"albumID"

@implementation Album
@synthesize albumName = _albumName, releaseDate = _releaseDate, albumArtFileName = _albumArtFileName, artist = _artist, albumSongs = _albumSongs, genreCode = _genreCode, albumID = _albumID;

static  int const SAVE_ALBUM = 0;
static int const DELETE_ALBUM = 1;
static int const UPDATE_ALBUM = 2;

- (id)init
{
    if(self = [super init]){
        _albumID = [[NSObject UUID] copy];
    }
    return self;
}

//custom setter method
- (void)setArtist:(Artist *)artist
{
    if([_artist isEqual:artist])
        return;
    else{
        [[_artist allAlbums] removeObject:self];
        if(! [artist.allAlbums containsObject:self])
            [[artist allAlbums] addObject:self];
        if(_artist.allSongs.count == 0 && _artist.allAlbums.count ==0)
            [_artist deleteArtist];
    }

    _artist = artist;
}
//end of custom setters

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        _albumID = [aDecoder decodeObjectForKey:ALBUM_ID_KEY];
        _albumName = [aDecoder decodeObjectForKey:ALBUM_NAME_KEY];
        _releaseDate = [aDecoder decodeObjectForKey:RELEASE_DATE_KEY];
        _albumArtFileName = [aDecoder decodeObjectForKey:ALBUM_ART_FILE_NAME_KEY];
        _artist = [aDecoder decodeObjectForKey:ARTIST_KEY];
        _albumSongs = [aDecoder decodeObjectForKey:ALBUM_SONGS_KEY];
        _genreCode = [aDecoder decodeIntForKey:GENRE_CODE_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_albumID forKey:ALBUM_ID_KEY];
    [aCoder encodeObject:_albumName forKey:ALBUM_NAME_KEY];
    [aCoder encodeObject:_releaseDate forKey:RELEASE_DATE_KEY];
    [aCoder encodeObject:_albumArtFileName forKey:ALBUM_ART_FILE_NAME_KEY];
    [aCoder encodeObject:_artist forKey:ARTIST_KEY];
    [aCoder encodeObject:_albumSongs forKey:ALBUM_SONGS_KEY];
    [aCoder encodeInteger:_genreCode forKey:GENRE_CODE_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved albums
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].albumsFileURL];
    if(!data){
        //if no albums exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)saveAlbum  //saves the current album (instance of this class) to the list of all albums on disk
{
    return [self performModelAction:SAVE_ALBUM];
}

- (BOOL)deleteAlbum
{
    return [self performModelAction:DELETE_ALBUM];
}

- (BOOL)updateExistingAlbum
{
    return [self performModelAction:UPDATE_ALBUM];
}

- (BOOL)performModelAction:(int)desiredActionConst  //does the 'hard work' of altering the model.
{
    NSMutableArray *albums = (NSMutableArray *)[Album loadAll];
    switch (desiredActionConst) {
        case SAVE_ALBUM:
            [albums insertObject:self atIndex:0];  //should sort this array based on alphabetical order!
            //new albums added to array will appear at top of 'list'
            
            //update the artist details for this album
            if(self.artist)
                [[self.artist allAlbums] removeObject:self];
            
            break;
            
        case DELETE_ALBUM:
        {
            [self removeAlbumArt]; //delete album art from disk
            
            self.artist = nil;
            
            //If the last song in this album is to be deleted, Song.m will delete the song and delegate control to this class while it waits for the album to be deleted.
            if(self.albumSongs == 0)
                [albums removeObject:self];
            
            //delete the album AND the albums songs from our model on disk
            Album *thisAlbum = albums[[albums indexOfObject:self]];
            if(self.albumSongs.count > 0){
                NSMutableArray *songs = (NSMutableArray *)[Song loadAll];
                for(Song *librarySong in songs){  //for each song (in the entire library)
                    for(Song *thisAlbumsSong in thisAlbum.albumSongs){  //check if it is one of the songs within this album
                        if([librarySong isEqual:thisAlbumsSong]){  //if it's a match, delete the song!
                            [librarySong deleteSong];
                        }
                    }
                }
            }
                
            [thisAlbum.albumSongs removeAllObjects];
            [albums removeObject:self];
            
            break;
        }
            
        case UPDATE_ALBUM:
            //replace the old object saved in the array with the current object
            if(albums.count > 0){
                [albums replaceObjectAtIndex:[albums indexOfObject:self] withObject:self];
            }
            break;
            
        default:
            return NO;
            
    } //end of swtich
    
    if([AppEnvironmentConstants smartAlphabeticalSort])
        [Album sortExistingAlbumsWithSmartSort: &albums];
    else
        [Album sortExistingAlbumsAlphabetically: &albums];
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:albums];  //encode albums
    return [fileData writeToURL:[FileIOConstants createSingleton].albumsFileURL atomically:YES];
}

- (BOOL)setAlbumArt:(UIImage *)image
{
    BOOL success = NO;
    
    if(image == nil){
        _albumArtFileName = nil;
        return YES;
    }
    
    NSString *artFileName = [NSString stringWithFormat:@"%@.png", self.albumName];
    
    //save the UIImage to disk
    if([AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:artFileName])
        success = YES;
    else{
        success = [AlbumArtUtilities saveAlbumArtFileWithName:artFileName andImage:image];
    }
    
    _albumArtFileName = artFileName;
    return success;
}

- (void)removeAlbumArt
{
    if(_albumArtFileName){
        //remove file from disk
        [AlbumArtUtilities deleteAlbumArtFileWithName:_albumArtFileName];
        
        //made albumArtFileName property nil
        _albumArtFileName = nil;
        
        //set this change to all songs in this album as well
        for(Song *albumSong in self.albumSongs){
            [albumSong setAlbumArt:nil];
            [albumSong updateExistingSong];
        }
    }
}

+ (void)sortExistingAlbumsAlphabetically:(NSMutableArray **)albumModel
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"albumName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [*albumModel sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

+ (void)sortExistingAlbumsWithSmartSort:(NSMutableArray **)albumModel
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"albumName" ascending:YES selector:@selector(smartSort:)];
    [*albumModel sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (NSMutableArray *)insertNewAlbumIntoAlphabeticalArray:(Album *)unInsertedAlbum
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)  //same object instance
        return YES;
    if(!object || ![object isMemberOfClass:[self class]])  //object is nil or not an album object
        return NO;
    
    //return ([self customSmartAlbumComparison:(Album *)object]) ? YES : NO;
    return ([_albumID isEqualToString:((Album *)object).albumID]) ? YES : NO;
}

/**
- (BOOL)customSmartAlbumComparison:(Album *)mysteryAlbum
{
    BOOL sameName = NO;
    //check if album names are equal -every album name needs to be unique in library as it is!
    if([self.albumName isEqualToString:mysteryAlbum.albumName])
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
    //result = prime * result + [self.albumName hash];
    //result = prime * result + [self.releaseDate hash];
    //result = prime * result + [self.albumArtFileName hash];
    //result = prime * result + [self.artist.artistName hash];
    //result = prime * result + [self.albumSongs hash];
    return prime * result + [_albumID hash];
    
    // Add primitive variables (int)
    //result = prime * result + self.genreCode;
    
    // Boolean values (BOOL)
    //result = prime * result + self.isSelected ? yesPrime : noPrime;
    
    return result;
}

@end
