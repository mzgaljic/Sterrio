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
#define ALBUM_ART_PATH_KEY @"albumArtPath"
#define ARTIST_KEY @"artist"
#define GENRE_CODE_KEY @"albumGenreCode"

@implementation Album
@synthesize albumName, releaseDate, albumArtPath, artist, genreCode;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.albumName = [aDecoder decodeObjectForKey:ALBUM_NAME_KEY];
        self.releaseDate = [aDecoder decodeObjectForKey:RELEASE_DATE_KEY];
        self.albumArtPath = [aDecoder decodeObjectForKey:ALBUM_ART_PATH_KEY];
        self.artist = [aDecoder decodeObjectForKey:ARTIST_KEY];
        self.genreCode = [aDecoder decodeIntForKey:GENRE_CODE_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.albumName forKey:ALBUM_NAME_KEY];
    [aCoder encodeObject:self.releaseDate forKey:RELEASE_DATE_KEY];
    [aCoder encodeObject:self.albumArtPath forKey:ALBUM_ART_PATH_KEY];
    [aCoder encodeObject:self.artist forKey:ARTIST_KEY];
    [aCoder encodeInteger:self.genreCode forKey:GENRE_CODE_KEY];
}

@end
