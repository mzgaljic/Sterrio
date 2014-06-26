//
//  Song.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Song.h"
#import "FileIOConstants.h"
#define SONG_NAME_KEY @"songName"
#define YOUTUBE_LINK_KEY @"youtubeLink"
#define ALBUM_ART_PATH_KEY @"albumArtPath"
#define ALBUM_KEY @"album"
#define ARTIST_KEY @"artist"
#define GENRE_CODE_KEY @"songGenreCode"

@implementation Song
@synthesize songName, youtubeLink, albumArtPath, album, artist, genreCode;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.songName = [aDecoder decodeObjectForKey:SONG_NAME_KEY];
        self.youtubeLink = [aDecoder decodeObjectForKey:YOUTUBE_LINK_KEY];
        self.albumArtPath = [aDecoder decodeObjectForKey:ALBUM_ART_PATH_KEY];
        self.album = [aDecoder decodeObjectForKey:ALBUM_KEY];
        self.artist = [aDecoder decodeObjectForKey:ARTIST_KEY];
        self.genreCode = [aDecoder decodeIntForKey:GENRE_CODE_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.songName forKey:SONG_NAME_KEY];
    [aCoder encodeObject:self.youtubeLink forKey:YOUTUBE_LINK_KEY];
    [aCoder encodeObject:self.albumArtPath forKey:ALBUM_ART_PATH_KEY];
    [aCoder encodeObject:self.album forKey:ALBUM_KEY];
    [aCoder encodeObject:self.artist forKey:ARTIST_KEY];
    [aCoder encodeInteger:self.genreCode forKey:GENRE_CODE_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved songs
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].libraryFileURL];
    if(!data){
        //if no songs exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)save  //saves the current song (instance of this class) to the list of all songs on disk
{
    NSMutableArray *songs = (NSMutableArray *)[Song loadAll];
    
    //should sort this array based on alphabetical order!
    [songs insertObject:self atIndex:0];  //new songs added to array will appear at top of 'list'
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:songs];  //encode songs
    return [fileData writeToURL:[FileIOConstants createSingleton].libraryFileURL atomically:YES];
}

- (BOOL)deleteAlbum
{
    return NO;
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
}

- (NSMutableArray *)insertNewSongIntoAlphabeticalArray:(Song *)unInsertedSong
{
    return nil;
}


@end
