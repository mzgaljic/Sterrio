//
//  Album.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Album.h"
#import "Song.h"
#import "FileIOConstants.h"
#define ALBUM_NAME_KEY @"albumName"
#define RELEASE_DATE_KEY @"releaseDate"
#define ALBUM_ART_FILE_NAME_KEY @"albumArtFileName"
#define ARTIST_KEY @"artist"
#define ALBUM_SONGS_KEY @"albumSongs"
#define GENRE_CODE_KEY @"albumGenreCode"

@implementation Album
@synthesize albumName, releaseDate, albumArtFileName, artist, albumSongs, genreCode;

static  int const SAVE_ALBUM = 0;
static int const DELETE_ALBUM = 1;
static int const UPDATE_ALBUM = 2;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.albumName = [aDecoder decodeObjectForKey:ALBUM_NAME_KEY];
        self.releaseDate = [aDecoder decodeObjectForKey:RELEASE_DATE_KEY];
        self.albumArtFileName = [aDecoder decodeObjectForKey:ALBUM_ART_FILE_NAME_KEY];
        self.artist = [aDecoder decodeObjectForKey:ARTIST_KEY];
        self.albumSongs = [aDecoder decodeObjectForKey:ALBUM_SONGS_KEY];
        self.genreCode = [aDecoder decodeIntForKey:GENRE_CODE_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.albumName forKey:ALBUM_NAME_KEY];
    [aCoder encodeObject:self.releaseDate forKey:RELEASE_DATE_KEY];
    [aCoder encodeObject:self.albumArtFileName forKey:ALBUM_ART_FILE_NAME_KEY];
    [aCoder encodeObject:self.artist forKey:ARTIST_KEY];
    [aCoder encodeObject:self.albumSongs forKey:ALBUM_SONGS_KEY];
    [aCoder encodeInteger:self.genreCode forKey:GENRE_CODE_KEY];
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
            break;
            
        case DELETE_ALBUM:
        {
            //delete the songs
            NSArray *mySongs = [self albumSongs];
            while(mySongs.count != 0){
                [[mySongs lastObject] deleteSong];
            }
            
            //remove album songs from any playlists?
            
            //delete the album itself
            [albums removeObject:self];  //implemented custom isEqual and hash methods, so this works!
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
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:albums];  //encode albums
    return [fileData writeToURL:[FileIOConstants createSingleton].albumsFileURL atomically:YES];
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
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
    
    return ([self customSmartAlbumComparison:(Album *)object]) ? YES : NO;
}

- (BOOL)customSmartAlbumComparison:(Album *)mysteryAlbum
{
    BOOL sameName = NO;
    //check if album names are equal -every album name needs to be unique in library as it is!
    if([self.albumName isEqualToString:mysteryAlbum.albumName])
        sameName = YES;
    
    return (sameName) ? YES : NO;
}

-(NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    //NSUInteger yesPrime = 1231;
    //NSUInteger noPrime = 1237;
    
    // Add any object that already has a hash function (NSString)
    result = prime * result + [self.albumName hash];
    result = prime * result + [self.releaseDate hash];
    result = prime * result + [self.albumArtFileName hash];
    result = prime * result + [self.artist.artistName hash];
    result = prime * result + [self.albumSongs hash];
    
    // Add primitive variables (int)
    result = prime * result + self.genreCode;
    
    // Boolean values (BOOL)
    //result = prime * result + self.isSelected ? yesPrime : noPrime;
    
    return result;
}

@end
