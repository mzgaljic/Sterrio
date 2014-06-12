//
//  Song.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Song.h"
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


@end
