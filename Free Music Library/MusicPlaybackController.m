//
//  MusicPlaybackController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicPlaybackController.h"
static AVPlayer *player = nil;
static PlaybackQueue *playbackQueue = nil;  //do not access directly! getter below
static BOOL explicitlyPausePlayback = NO;
static BOOL initialized = NO;

@implementation MusicPlaybackController

+ (void)ResumePlayback
{
    [player play];
}

/** Playback will be paused immediately */
+ (void)PausePlayback
{
    [player pause];
}

/** Playback will continue from the specified seek point, skipping a portion of the track. */
+ (void)SeekToTime
{
#warning no implementation
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)SkipToNextTrack
{
    Song *newSong = [[MusicPlaybackController playbackQueue] skipForward];
    
    //actually advance and start playing song....
}

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)ReturnToPreviousTrack
{
    Song *oldSong = [[MusicPlaybackController playbackQueue] skipToPrevious];
    
    //actually rewind and play previous track
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

#pragma mark - Helper methods
//Will be called when YTVideoAvPlayer finishes playing a YTVideoPlayerItem
+ (void)songDidFinishPlaying:(NSNotification *) notification
{
    //try to load the next song in the background
    
}

+ (PlaybackQueue *)playbackQueue
{
    if(!initialized){
        playbackQueue = [[PlaybackQueue alloc] init];
    }
    return playbackQueue;
}

@end