//
//  MZPrivateMainPlaybackQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/10/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "PlaybackContext.h"
#import "CoreDataManager.h"
#import "PreliminaryNowPlaying.h"
#import "MZPlaybackQueue.h"  //for imported constants
@import CoreData;

@interface MZPrivateMainPlaybackQueue : NSObject

- (NSUInteger)numSongsInEntireMainQueue;
- (NSUInteger)numMoreSongsInMainQueue;

//should be used when a user moves into a different context and wants to destroy their
//current queue. This does not clear the "up next" section.
- (void)setMainQueueWithNewNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext;

//for getting an array of all up next songs, without putting all songs into memory.
- (NSArray *)tableViewOptimizedArrayOfMainQueueSongsComingUp;
- (PlaybackContext *)mainQueuePlaybackContext;

- (void)clearMainQueue;
- (PreliminaryNowPlaying *)skipToPrevious;
- (PreliminaryNowPlaying *)skipForward;

- (void)skipThisManySongsInQueue:(NSUInteger)numSongsToSkip;

@end
