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

- (Song *)nowPlaying;
- (Song *)peekAtNextSong;
- (Song *)peekAtPreviousSong;

- (Song *)skipForward;
- (Song *)skipToPrevious;

- (NSArray *)listOfUpcomingSongsNowPlayingExclusive;
- (NSArray *)listOfUpcomingSongsNowPlayingInclusive;
- (NSArray *)listOfPlayedSongsNowPlayingExclusive;
- (NSArray *)listOfPlayedSongsNowPlayingInclusive;

/* Inserts songs after the currently playing song. If 
   the queue is empty, all songs are added to the queue. */
- (void)insertSongsAfterNowPlaying:(NSArray *)songs;

@end
