//
//  PlaybackQueue.h
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Deque.h"
#import "Song.h"

@interface PlaybackQueue : NSObject

- (void)clearQueue;
- (NSUInteger)numMoreSongsInQueue;

- (Song *)nowPlaying;
- (void)setNowPlayingIndexWithSong:(Song *)song;
- (NSInteger)nowPlayingIndex;  //should be used sparingly! don't abuse...
- (Song *)peekAtNextSong;
- (Song *)peekAtPreviousSong;

- (Song *)skipForward;
- (Song *)skipToPrevious;

- (NSArray *)listOfUpcomingSongsNowPlayingExclusive;
- (NSArray *)listOfUpcomingSongsNowPlayingInclusive;
- (NSArray *)listOfPlayedSongsNowPlayingExclusive;
- (NSArray *)listOfPlayedSongsNowPlayingInclusive;
- (NSArray *)listOfEntireQueueAsArray;

- (NSUInteger)sizeOfEntireQueue;

/* Inserts songs after the currently playing song. If 
   the queue is empty, all songs are added to the queue. */
- (void)insertSongsAfterNowPlaying:(NSArray *)songs;

@end
