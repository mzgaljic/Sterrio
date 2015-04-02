//
//  MusicPlaybackController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//
//This class is the go-to way of controlling and communicating with MyAVPlayer, outside
//of the MyAVPlayer class itself.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>  //needed for placing info/media on lock screen
#import "Song.h"
#import "Playlist.h"
//#import "PlaybackQueue.h"
#import "MZPlaybackQueue.h"
#import "MyAVPlayer.h"  //custom AVPlayer class
#import "GenreConstants.h"
#import "NowPlayingSong.h"
#import "PlaybackContext.h"
#import "VideoPlayerWrapper.h"
@class PlayerView;  //import doesnt work here

@interface MusicPlaybackController : NSObject

#pragma mark - Controling playback
/** Playback will resume immediately */
+ (void)resumePlayback;

/** Playback will pause immediately */
+ (void)pausePlayback;

/** Stops playback if the song (x) to be deleted is the now playing song. If x is in the playback queue,
 it is removed. All deletions (of songs, artists, etc) taking place ANYWHERE in the application should
 call this method as a "heads up" to avoid potential problems. */
+ (void)songAboutToBeDeleted:(Song *)song deletionContext:(PlaybackContext *)context;

/** Stops playback if any of the songs in the group (x) to be deleted is the now playing song. Any songs
 from group x within the queue are removed. All deletions (of songs, artists, etc) taking place ANYWHERE 
 in the application should call this method as a "heads up" to avoid potential problems. **/
+ (void)groupOfSongsAboutToBeDeleted:(NSArray *)songs deletionContext:(PlaybackContext *)context;

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack;

/* Used to jump ahead or back in a video to an exact point. The player playback state
 (playing or paused) remains unaffected. */
+ (void)seekToVideoSecond:(NSNumber *)second;

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)returnToPreviousTrack;

+ (BOOL)shouldSeekToStartOnBackPress;

+ (NSURL *)closestUrlQualityMatchForSetting:(short)aQualitySetting usingStreamsDictionary:(NSDictionary *)aDictionary;

#pragma mark - Now Playing Song
+ (Song *)nowPlayingSong;
+ (NowPlayingSong *)nowPlayingSongObject;

#pragma mark + Gathering playback info
+ (NSUInteger)numMoreSongsInQueue;

//does NOT perform a context comparison.
+ (BOOL)isSongLastInQueue:(Song *)song;
//does NOT perform a context comparison.
+ (BOOL)isSongFirstInQueue:(Song *)song;
+ (NSString *)prettyPrintNavBarTitle;

#pragma mark + Changing the Queue
+ (void)newQueueWithSong:(Song *)song
             withContext:(PlaybackContext *)context;
+ (void)queueUpNextSongsWithContexts:(NSArray *)contexts;
+ (void)repeatEntireMainQueue;

#pragma mark - Playback status
+ (BOOL)playbackExplicitlyPaused;
+ (void)explicitlyPausePlayback:(BOOL)pause;

#pragma mark - getters/setters for avplayer and the playerview
+ (void)setRawAVPlayer:(AVPlayer *)myAvPlayer;
+ (AVPlayer *)obtainRawAVPlayer;
+ (void)setAVPlayerTimeObserver:(id)observer;
+ (id)avplayerTimeObserver;

+ (void)setRawPlayerView:(PlayerView *)myPlayerView;
+ (PlayerView *)obtainRawPlayerView;

#pragma mark - Lock Screen Song Info & Art
+ (void)updateLockScreenInfoAndArtForSong:(Song *)song;

#pragma mark - loading spinner status
+ (void)simpleSpinnerOnScreen:(BOOL)onScreen;
+ (void)internetProblemSpinnerOnScreen:(BOOL)onScreen;
+ (void)spinnerForWifiNeededOnScreen:(BOOL)onScreen;
+ (void)noSpinnersOnScreen;

+ (BOOL)isSpinnerForWifiNeededOnScreen;
+ (BOOL)isSimpleSpinnerOnScreen;
+ (BOOL)isInternetProblemSpinnerOnScreen;
+ (BOOL)isSpinnerOnScreen;
+ (NSString *)messageForCurrentSpinner;

#pragma mark - Dealing with problems
+ (void)longVideoSkippedOnCellularConnection;
+ (int)numLongVideosSkippedOnCellularConnection;
+ (void)resetNumberOfLongVideosSkippedOnCellularConnection;

+ (BOOL)isPlayerStalled;
+ (void)setPlayerInStall:(BOOL)stalled;

@end
