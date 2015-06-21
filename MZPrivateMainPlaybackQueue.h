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
#import "MZPlaybackQueue.h"  //for imported constants
@import CoreData;

@class PlayableItem;
@interface MZPrivateMainPlaybackQueue : NSObject

- (NSUInteger)numItemsInEntireMainQueue;
- (NSUInteger)numMoreItemsInMainQueue;

//should be used when a user moves into a different context and wants to destroy their
//current queue. This does not clear the "up next" section.
- (void)setMainQueueWithNewNowPlayingItem:(PlayableItem *)item;

//for getting an array of all up next items, without putting all items into memory.
- (NSArray *)tableViewOptimizedArrayOfMainQueuePlayableItemsComingUp;
- (PlaybackContext *)mainQueuePlaybackContext;

- (void)clearMainQueue;
- (PlayableItem *)skipToPrevious;
- (PlayableItem *)skipForward;
- (void)efficientlySkipTheseManyItems:(NSUInteger)numToSkip;

//- (void)skipThisManyItemsInQueue:(NSUInteger)numItemsToSkip;
- (PlayableItem *)skipToBeginningOfQueue;

@end
