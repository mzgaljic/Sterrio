//
//  MZNewPlaybackQueue.h
//  Sterrio
//
//  Created by Mark Zgaljic on 6/23/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZPlaybackQueueSnapshot.h"
#import "AppEnvironmentConstants.h"
@import CoreData;

//NOT thread safe and NOT a singleton. It is a global scoped class though.
@interface MZNewPlaybackQueue : NSObject
typedef NS_ENUM(NSInteger, SeekDirection) { SeekForward, SeekBackwards };

@property (nonatomic, assign, readonly) SHUFFLE_STATE shuffleState;

+ (instancetype)sharedInstance;
+ (void)discardInstance;
//user will just be able to have queued songs (happens if the player was killed and then stuff started
//being queued on the fly, causing the player to be created on the screen.)
+ (instancetype)newInstanceWithSongsQueuedOnTheFly:(PlaybackContext *)context;
//user will be able to have a main queue AND queue songs on the fly (see method below.) This typically
//gets called when a song is tapped in the gui, creating the player...
+ (instancetype)newInstanceWithNewNowPlayingPlayableItem:(PlayableItem *)item;

- (MZPlaybackQueueSnapshot *)snapshotOfPlaybackQueue;

- (PlayableItem *)currentItem;
- (PlayableItem *)seekBackOneItem;
- (PlayableItem *)seekForwardOneItem;
- (PlayableItem *)seekBy:(NSUInteger)value inDirection:(SeekDirection)direction;
- (PlayableItem *)seekToFirstItemInMainQueueAndReshuffleIfNeeded;

//Queues the stuff described by PlaybackContext to the playback queue.
- (void)queueSongsOnTheFlyWithContext:(PlaybackContext *)context;

//# of PlayableItem's that still need to play (includes main context and stuff queued by user on the fly.)
- (NSUInteger)forwardItemsCount;
- (NSUInteger)totalItemsCount;

- (void)setShuffleState:(SHUFFLE_STATE)state;

#pragma mark - DEBUG
- (NSString *)description;  //prints the queue contents and class info.

@end
