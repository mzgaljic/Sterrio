//
//  MZPrivateUpNextPlaybackQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/9/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//IMPORTANT: this private "up next" queue class has NO NOTION or understanding of going
//backwards. it is meant to literally let the user add songs to play next. once they are
//played and/or removed from the queue, the songs are gone forever. The main
//MZPlaybackQueue class is the only one that supports the notion of going backwards (on purpose).

#import <Foundation/Foundation.h>
#import "Song.h"
#import "PlaybackContext.h"
#import "CoreDataManager.h"
#import "PreliminaryNowPlaying.h"
#import "MZPlaybackQueue.h"  //for imported constants
@import CoreData;

@interface MZPrivateUpNextPlaybackQueue : NSObject

//appended to existing ones contexts
- (void)addSongsToUpNextWithContexts:(NSArray *)contexts;
- (NSUInteger)numMoreUpNextSongsCount;
//for getting an array of all up next songs, without putting all songs into memory.
- (NSArray *)tableViewOptimizedArrayOfUpNextSongs;
- (NSArray *)tableViewOptimizedArrayOfUpNextSongContexts;

//skipping forward
- (PreliminaryNowPlaying *)obtainAndRemoveNextSong;
- (PreliminaryNowPlaying *)peekAtNextSong;  //not used but maybe useful at some point?

- (void)skipThisManySongsInQueue:(NSUInteger)numSongsToSkip;
- (void)clearUpNext;

@end
