//
//  MZPlaybackQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "PlaybackContext.h"
#import "CoreDataManager.h"
#import "MZPrivateMainPlaybackQueue.h"
#import "MZPrivateUpNextPlaybackQueue.h"
#import "PreliminaryNowPlaying.h"
#import "SongPlayerCoordinator.h"
#import "VideoPlayerWrapper.h"
@import CoreData;

@interface MZPlaybackQueue : NSObject

//used by private playback queue classes.
extern short const INTERNAL_FETCH_BATCH_SIZE;
extern short const EXTERNAL_FETCH_BATCH_SIZE;


+ (instancetype)sharedInstance;

+ (void)presentQueuedHUD;

#pragma mark - Get info about queue
- (NSUInteger)numSongsInEntireMainQueue;
- (NSUInteger)numMoreSongsInMainQueue;
- (NSUInteger)numMoreSongsInUpNext;

#pragma mark - Info for displaying Queue contexts visually
//These 3 array methods WILL return the now playing song
//if the now playing song is in that particular queue.
//up next queue
- (NSArray *)tableViewOptimizedArrayOfUpNextSongs;
- (NSArray *)tableViewOptimizedArrayOfUpNextSongContexts;
//main queue
- (NSArray *)tableViewOptimizedArrayOfMainQueueSongsComingUp;
- (PlaybackContext *)mainQueuePlaybackContext;

#pragma mark - Performing operations on queue
- (void)clearEntireQueue;
- (void)clearUpNext;
- (void)skipOverThisManyQueueSongsEfficiently:(NSUInteger)numSongsToSkip;

//should be used when a user moves into a different context and wants to destroy their
//current queue. This does not clear the "up next" section.
- (void)setMainQueueWithNewNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext;

//Will initiate playback if no songs were played yet. or if the other queues are finished.
- (void)addSongsToPlayingNextWithContexts:(NSArray *)contexts;

- (Song *)skipToPrevious;
- (Song *)skipForward;

//jumps back to index 0 in the main queue. if shuffle is on, it reshuffles before jumping to index 0.
- (Song *)skipToBeginningOfQueueReshufflingIfNeeded;

#pragma mark - DEBUG
- (void)printQueueContents;

@end
