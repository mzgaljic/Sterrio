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
static NSString * const ALBUM1_NAME = @"Spirit (Deluxe)";
static NSInteger const SONG1_DURATION = 278;

static NSString * const SONG2_NAME = @"Summer of 69";
static NSString * const SONG2_YTID = @"9f06QZCVUHg";
static NSString * const ARTIST2_NAME = @"Bryan Adams";
static NSString * const ALBUM2_NAME = @"Reckless";
static NSInteger const SONG2_DURATION = 221;

static NSString * const SONG3_NAME = @"How to Save a Life";
static NSString * const SONG3_YTID = @"rkBvhnri5s0";
static NSString * const ARTIST3_NAME = @"The Fray";
static NSInteger const SONG3_DURATION = 263;

static NSString * const SONG4_NAME = @"Christmas Songs 2014 (1hr Mix Playlist)";
static NSString * const SONG4_YTID = @"mVp0brA3Hpk";
static NSInteger const SONG4_DURATION = 3757;

static NSString * const SONG5_NAME = @"Geronimo";
static NSString * const ARTIST5_NAME = @"Sheppard";
static NSString * const SONG5_YTID = @"UL_EXAyGCkw";
static NSInteger const SONG5_DURATION = 219;

static NSString * const SONG6_NAME = @"The Days";
static NSString * const ARTIST6_NAME = @"Avicii";
static NSString * const SONG6_YTID = @"JDglMK9sgIQ";
static NSInteger const SONG6_DURATION = 247;

static NSString * const SONG7_NAME = @"Hound Dog";
static NSString * const ARTIST7_NAME = @"Elvis Presley";
static NSString * const SONG7_YTID = @"lzQ8GDBA8Is";
static NSInteger const SONG7_DURATION = 137;

+ (void)createCoreDataSampleMusicData
{
    BOOL importHugeDataSetForTesting = NO;
    
    if(importHugeDataSetForTesting){
        int songCreationCount = 3000;
        Song *someSong;
        //UIImage *art = [UIImage imageNamed:@"testAlbumArt"];
        int stopToPrint = 0;
        for(int i = 0; i < songCreationCount; i++){
            someSong = [PreloadedCoreDataModelUtility createSongWithName:SONG2_NAME
                                                            byArtistName:ARTIST2_NAME
                                                        partOfAlbumNamed:ALBUM2_NAME
                                                               youtubeID:SONG2_YTID
                                                           videoDuration:SONG2_DURATION];
            [someSong setAlbumArt:[UIImage imageNamed:@"testAlbumArt.jpg"]];
            
            if(i == stopToPrint && i != songCreationCount){
                NSLog(@"songsCreated: %i", i);
                stopToPrint += 500;
                [[CoreDataManager sharedInstance] saveContext];
            }
        }
        [[CoreDataManager sharedInstance] saveContext];
    }
    else{
        [PreloadedCoreDataModelUtility createSongWithName:SONG1_NAME
                                             byArtistName:ARTIST1_NAME
                                         partOfAlbumNamed:ALBUM1_NAME
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
        [PreloadedCoreDataModelUtility createSongWithName:SONG5_NAME
                                             byArtistName:ARTIST5_NAME
                                         partOfAlbumNamed:nil
                                                youtubeID:SONG5_YTID
                                            videoDuration:SONG5_DURATION];
        [PreloadedCoreDataModelUtility createSongWithName:SONG6_NAME
                                             byArtistName:ARTIST6_NAME
                                         partOfAlbumNamed:nil
                                                youtubeID:SONG6_YTID
                                            videoDuration:SONG6_DURATION];
        [PreloadedCoreDataModelUtility createSongWithName:SONG7_NAME
                                             byArtistName:ARTIST7_NAME
                                         partOfAlbumNamed:nil
                                                youtubeID:SONG7_YTID
                                            videoDuration:SONG7_DURATION];
        [[CoreDataManager sharedInstance] saveContext];
    }
}

+ (Song *)createSongWithName:(NSString *)songName
              byArtistName:(NSString *)artistName
          partOfAlbumNamed:(NSString *)albumName
                 youtubeID:(NSString *)ytID videoDuration:(NSUInteger)durationInSecs
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:albumName
                      byNewOrExistingArtist:artistName
                           inManagedContext:[CoreDataManager context]
                               withDuration:durationInSecs
                                     songId:ytID];
    return myNewSong;
}

@end
