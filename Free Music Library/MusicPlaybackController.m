//
//  MusicPlaybackController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicPlaybackController.h"
static MyAVPlayer *player = nil;
static PlaybackQueue *playbackQueue = nil;  //DO NOT access directly! getter below
static BOOL explicitlyPausePlayback = NO;
static BOOL initialized = NO;

@implementation MusicPlaybackController

+ (void)resumePlayback
{
    [player play];
}

/** Playback will be paused immediately */
+ (void)pausePlayback
{
    [player pause];
}

+ (void)songAboutToBeDeleted
{
    [player pause];
    
    if(playbackQueue.listOfPlayedSongsNowPlayingExclusive.count > 0){  //more items to play
        [self skipToNextTrack];
    } else{
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
    }
}

/** Playback will continue from the specified seek point, skipping a portion of the track. */
+ (void)seekToTime
{
    #warning no implementation
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack
{
    Song *nextSong = [[MusicPlaybackController playbackQueue] skipForward];
    [player startPlaybackOfSong:nextSong goingForward:YES];
    //NOTE: YTVideoAvPlayer will automatically skip more songs if they cant be played
}

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)returnToPreviousTrack
{
    Song *previousSong = [[MusicPlaybackController playbackQueue] skipToPrevious];
    [player startPlaybackOfSong:previousSong goingForward:NO];
    //NOTE: YTVideoAvPlayer will automatically rewind further back in the queue if some songs cant be played
}

/** Current elapsed playback time (for the current song/track). */
+ (void)currentTime
{
    #warning no implementation
}

#pragma mark - Gathering playback info
+ (NSArray *)listOfUpcomingSongsInQueue
{
    return [[MusicPlaybackController playbackQueue] listOfUpcomingSongsNowPlayingExclusive];
}

#pragma mark - Now Playing Song
+ (Song *)nowPlayingSong
{
    return [[MusicPlaybackController playbackQueue] nowPlaying];
}

+ (void)newQueueWithSong:(Song *)song
                   album:(Album *)album
                  artist:(Artist *)artist
                playlist:(Playlist *)playlist
               genreCode:(int)code
         skipCurrentSong:(BOOL)skipNow;
{
    if(skipNow){
        [playbackQueue clearQueue];
    }
    [playbackQueue insertSongsAfterNowPlaying:@[song]];
#warning missing implementation
}

#pragma mark - Playback status
+ (BOOL)playbackExplicitlyPaused
{
    return explicitlyPausePlayback;
}

+ (void)explicitlyPausePlayback:(BOOL)pause
{
    explicitlyPausePlayback = pause;
}

#pragma mark - Public helper
+ (NSURL *)closestUrlQualityMatchForSetting:(short)aQualitySetting usingStreamsDictionary:(NSDictionary *)aDictionary
{
    short maxDesiredQuality = aQualitySetting;
    NSDictionary *vidQualityDict = aDictionary;
    NSURL *url;
    switch (maxDesiredQuality) {
        case 240:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 360:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 720:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            break;
        }
        default:
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            break;
    }
    return url;
}

#pragma mark - Helper methods
+ (PlaybackQueue *)playbackQueue
{
    if(!initialized){
        playbackQueue = [[PlaybackQueue alloc] init];
    }
    return playbackQueue;
}

+ (void)setRawAVPlayer:(MyAVPlayer *)myAvPlayer
{
    player = myAvPlayer;
}
+ (AVPlayer *)obtainRawAVPlayer
{
    return player;
}

@end