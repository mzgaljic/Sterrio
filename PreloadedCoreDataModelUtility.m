//
//  PreloadedCoreDataModelUtility.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/24/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PreloadedCoreDataModelUtility.h"
#import "Song+Utilities.h"
#import "Artist+Utilities.h"
#import "Album+Utilities.h"

@implementation PreloadedCoreDataModelUtility
static NSString * const SONG1_NAME = @"Bleeding Love";
static NSString * const SONG1_YTID = @"7_weSk0BonM";
static NSString * const ARTIST1_NAME = @"Leona Lewis";
//static NSString * const ALBUM1_NAME = @"Spirit (Deluxe)";

static NSString * const SONG2_NAME = @"Summer of 69";
static NSString * const SONG2_YTID = @"9f06QZCVUHg";
static NSString * const ARTIST2_NAME = @"Bryan Adams";
static NSString * const ALBUM2_NAME = @"Reckless";

static NSString * const SONG3_NAME = @"Let It Be";
static NSString * const SONG3_YTID = @"WcBnJw-H2wQ";
static NSString * const ARTIST3_NAME = @"The Beatles";


+ (void)createCoreDataSampleMusicData
{
    [PreloadedCoreDataModelUtility createSongWithName:SONG1_NAME byArtistName:ARTIST1_NAME partOfAlbumNamed:nil youtubeID:SONG1_YTID];
    [PreloadedCoreDataModelUtility createSongWithName:SONG2_NAME byArtistName:ARTIST2_NAME partOfAlbumNamed:ALBUM2_NAME youtubeID:SONG2_YTID];
    [PreloadedCoreDataModelUtility createSongWithName:SONG3_NAME byArtistName:ARTIST3_NAME partOfAlbumNamed:nil youtubeID:SONG3_YTID];
}

+ (void)createSongWithName:(NSString *)songName byArtistName:(NSString *)artistName partOfAlbumNamed:(NSString *)albumName youtubeID:(NSString *)ytID
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:albumName
                      byNewOrExistingArtist:artistName
                                    inGenre:[GenreConstants noGenreSelectedGenreCode]
                           inManagedContext:[CoreDataManager context]];
    myNewSong.youtube_id = ytID;
    [[CoreDataManager sharedInstance] saveContext];
}

@end