//
//  Album.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Album.h"
#import "FileIOConstants.h"
#define ALBUM_NAME_KEY @"albumName"
#define RELEASE_DATE_KEY @"releaseDate"
#define ALBUM_ART_FILE_NAME_KEY @"albumArtFileName"
#define ARTIST_KEY @"artist"
#define ALBUM_SONGS_KEY @"albumSongs"
#define GENRE_CODE_KEY @"albumGenreCode"

@implementation Album
@synthesize albumName, releaseDate, albumArtFileName, artist, albumSongs, genreCode;

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
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].libraryFileURL];
    if(!data){
        //if no albums exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)save  //saves the current album (instance of this class) to the list of all albums on disk
{
    NSMutableArray *albums = (NSMutableArray *)[Album loadAll];
    
    //should sort this array based on alphabetical order!
    [albums insertObject:self atIndex:0];  //new albums added to array will appear at top of 'list'
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:albums];  //encode albums
    return [fileData writeToURL:[FileIOConstants createSingleton].libraryFileURL atomically:YES];
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
}

- (NSMutableArray *)insertNewAlbumIntoAlphabeticalArray:(Album *)unInsertedAlbum
{
    return nil;
}

@end
