//
//  MusicPlaybackController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Song.h"
#import "PlaybackQueue.h"

@interface MusicPlaybackController : NSObject

#pragma mark + Controling playback
/** Playback will resume immediately */
+ (void)ResumePlayback;

/** Playback will pause immediately */
+ (void)PausePlayback;

/** Playback will continue from the specified seek point, skipping a portion of the track. */
+ (void)SeekToTime;

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)SkipToNextTrack;

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)ReturnToPreviousTrack;

/** Current elapsed playback time (for the current song/track). */
+ (void)currentTime;

#pragma mark - Now Playing Song
+ (Song *)nowPlayingSong;

#pragma mark + Gathering playback info
+ (NSArray *)listOfUpcomingSongsInQueue;

#pragma mark + Changing the Queue
+ (void)newQueueWithSong:(Song *)song
                   album:(Album *)album
                  artist:(Artist *)artist
                playlist:(Playlist *)playlist
               genreCode:(int)code
         skipCurrentSong:(BOOL)skipNow;

#pragma mark - Playback status
+ (BOOL)playbackExplicitlyPaused;
+ (void)explicitlyPausePlayback:(BOOL)pause;

@end
