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
static NSString * const SONG1_YTID = @"Vzo-EL_62fQ";
static NSString * const ARTIST1_NAME = @"Leona Lewis";
static NSInteger const SONG1_DURATION = 278;

static NSString * const SONG2_NAME = @"Summer of 69";
static NSString * const SONG2_YTID = @"9f06QZCVUHg";
static NSString * const ARTIST2_NAME = @"Bryan Adams";
static NSString * const ALBUM2_NAME = @"Reckless";
static NSInteger const SONG2_DURATION = 221;

static NSString * const SONG3_NAME = @"Let It Be";
static NSString * const SONG3_YTID = @"WcBnJw-H2wQ";
static NSString * const ARTIST3_NAME = @"The Beatles";
static NSInteger const SONG3_DURATION = 223;

static NSString * const SONG4_NAME = @"Christmas Songs 2014 (1hr Mix Playlist)";
static NSString * const SONG4_YTID = @"mVp0brA3Hpk";
static NSInteger const SONG4_DURATION = 3757;

+ (void)createCoreDataSampleMusicData
{
    [PreloadedCoreDataModelUtility createSongWithName:SONG1_NAME
                                         byArtistName:ARTIST1_NAME
                                     partOfAlbumNamed:nil
                                            youtubeID:SONG1_YTID
                                        videoDuration:SONG1_DURATION];
    
    [PreloadedCoreDataModelUtility createSongWithName:SONG2_NAME
                                         byArtistName:ARTIST2_NAME
                                     partOfAlbumNamed:ALBUM2_NAME
                                            youtubeID:SONG2_YTID
                                        videoDuration:SONG2_DURATION];
    
    [PreloadedCoreDataModelUtility createSongWithName:SONG3_NAME
                                         byArtistName:ARTIST3_NAME
                                     partOfAlbumNamed:nil
                                            youtubeID:SONG3_YTID
                                        videoDuration:SONG3_DURATION];
    
    [PreloadedCoreDataModelUtility createSongWithName:SONG4_NAME
                                         byArtistName:nil
                                     partOfAlbumNamed:nil
                                            youtubeID:SONG4_YTID
                                        videoDuration:SONG4_DURATION];
}

+ (void)createSongWithName:(NSString *)songName
              byArtistName:(NSString *)artistName
          partOfAlbumNamed:(NSString *)albumName
                 youtubeID:(NSString *)ytID videoDuration:(NSUInteger)durationInSecs
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:albumName
                      byNewOrExistingArtist:artistName
                                    inGenre:[GenreConstants noGenreSelectedGenreCode]
                           inManagedContext:[CoreDataManager context]
                               withDuration:durationInSecs];
    myNewSong.youtube_id = ytID;
    [[CoreDataManager sharedInstance] saveContext];
}

@end
