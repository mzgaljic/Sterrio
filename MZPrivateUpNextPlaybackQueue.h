//
//  MZPrivateUpNextPlaybackQueue.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/9/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//IMPORTANT: this private "up next" queue class has NO NOTION or understanding of going
//backwards. it is meant to literally let the user add items to play next. once they are
//played and/or removed from the queue, the items are gone from the queue forever. The main
//MZPlaybackQueue class is the only one that supports the notion of going backwards.

#import <Foundation/Foundation.h>
#import "Song.h"
#import "PlaybackContext.h"
#import "CoreDataManager.h"
#import "MZPlaybackQueue.h"  //for imported constants
@import CoreData;
@class PlayableItem;
@interface MZPrivateUpNextPlaybackQueue : NSObject

//appended to existing contexts
- (void)addItemsToUpNextWithContexts:(NSArray *)contexts;
- (NSUInteger)numMoreUpNextItemsCount;
//for getting an array of all up next items, without putting all items into memory.
- (NSArray *)tableViewOptimizedArrayOfUpNextItems;
- (NSArray *)tableViewOptimizedArrayOfUpNextItemsContexts;

//skipping forward
- (PlayableItem *)obtainAndRemoveNextItem;
- (PlayableItem *)peekAtNextItem;  //not used but maybe useful at some point?

//- (void)skipThisManyItemsInQueue:(NSUInteger)numItemsToSkip;
- (void)clearUpNext;

@end
