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
#import "NowPlayingSong.h"
#import "CoreDataManager.h"
#import "MZPrivateMainPlaybackQueue.h"
#import "MZPrivateUpNextPlaybackQueue.h"
#import "PreliminaryNowPlaying.h"
#import "SongPlayerCoordinator.h"
@import CoreData;

@interface MZPlaybackQueue : NSObject

+ (instancetype)sharedInstance;

#pragma mark - Get info about queue
- (NSUInteger)numSongsInEntireMainQueue;
- (NSUInteger)numMoreSongsInMainQueue;
- (NSUInteger)numMoreSongsInUpNext;

#pragma mark - Performing operations on queue
- (void)clearEntireQueue;
- (void)clearUpNext;

//should be used when a user moves into a different context and wants to destroy their
//current queue. This does not clear the "up next" section.
- (void)setMainQueueWithNewNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext;

//Will initiate playback if no songs were played yet. or if the other queues are finished.
- (void)addSongsToPlayingNextWithContexts:(NSArray *)contexts;

- (Song *)skipToPrevious;
- (Song *)skipForward;

@end
