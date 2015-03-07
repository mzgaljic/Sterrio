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
@import CoreData;

@interface MZPlaybackQueue : NSObject

+ (instancetype)sharedInstance;

#pragma mark - Get info about queue
- (NowPlayingSong *)nowPlaying;  //just a convenient accessor for the singleton
- (Song *)nextSong;
- (NSUInteger)numMoreSongsInQueue;

//Needed to show where the first sub-queue is in its playback
//through its list of songs...since the now playing song is
//not always in the first sub-queue (ie: it could currently be
//playing back songs from the "playing next" section.)
- (Song *)nextSongScheduledForPlaybackInFirstSubQueue;

//songs in the "playing next" area of the playback queue.
- (NSArray *)playNextSongs;

/**Array containing NSFetchRequest objects (copies). Index 0 maps to the very first "sub-queue"
 within the entire playback queue (excluding the "playing next" section of the queue).
 Array is sorted from "soonest to be played" to "last to be played" order.
 */
- (NSArray *)arrayOfFetchRequestsMappingToSubsetQueues;


#pragma mark - Performing operations on queue
- (void)clearEntireQueue;
- (void)clearPlayingNext;

//index 0 is the first subqueue (the one after "playing next")
- (void)clearSubQueueAtIndex:(NSUInteger)index;

//should be used when a user moves into a different context and wants to destroy their
//current queues from the old contexts. This does not clear the "playing next" section.
- (void)setNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext;

- (void)addSongToPlayingNext:(Song *)aSong;

- (Song *)skipToPrevious;
- (Song *)skipForward;

@end
