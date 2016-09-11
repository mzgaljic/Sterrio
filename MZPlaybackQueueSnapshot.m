//
//  MZPlaybackQueueSnapshot.m
//  Sterrio
//
//  Created by Mark Zgaljic on 6/23/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZPlaybackQueueSnapshot.h"

@interface MZPlaybackQueueSnapshot ()
@property (nonatomic, strong) NSArray<PlayableItem*> *allSnapshotItems;
@property (nonatomic, assign) NSRange historyItemsRange;
@property (nonatomic, assign) NSUInteger nowPlayingIndex;
@property (nonatomic, assign) NSRange upNextQueuedItemsRange;
@property (nonatomic, assign) NSRange allFutureItemsRange;
@property (nonatomic, assign) BOOL didPrepareForDeletion;
@end
@implementation MZPlaybackQueueSnapshot

/**
 * @brief Creates a snapshot of the queue in such a way that it becomes trivial to display graphically to
 *        the user.
 * @param items all the PlayableItems that are to be displayed (graphically) to the user.
 * @param rangeOfHistoryItems   range of the items in the 'songs' array are part of the users
 *                              history. Meaning, the user actually played these songs for at least x
 *                              seconds. These songs were previously played (and are not necessarily part of
 *                              the current queue.)
 * @param rangeOfUpNextQueuedItems  Items which have been manually queued up by the user.
 * @param index  index of the now playing song (at the time of QueueSnapshot creation.)
 * @param rangeOfUpNextQueuedItems Range for the items that were queued on the fly by the user.
 * @param rangeOfAllFutureItems   Range for the items that are coming up in the main playback queue (not the
 *                                temporary queue that the user can build on the fly.) These are songs which
 *                                have not been played.
 */
- (id)initQueueSnapshotWithItems:(NSMutableArray<PlayableItem*> *)items
             rangeOfHistoryItems:(NSRange)historyItemsRange
                 nowPlayingIndex:(NSUInteger)index
        rangeOfUpNextQueuedItems:(NSRange)upNextQueuedItemsRange
           rangeOfAllFutureItems:(NSRange)allFutureItemsRange
{
    if(self = [super init]) {
        NSAssert(items != nil, @"cannot create queue snapshot with nil items parameter.");
        _allSnapshotItems = items;
        _historyItemsRange = historyItemsRange;
        _nowPlayingIndex = index;
        _upNextQueuedItemsRange = upNextQueuedItemsRange;
        _allFutureItemsRange = allFutureItemsRange;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nowPlayingSongChanged)
                                                     name:MZNewSongLoading
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:MZNewSongLoading];
}

- (void)nowPlayingSongChanged
{
    //might be better to actually create an interface and use a delegate to inform the snapshot which
    //index was tapped in the 'all_items' array that is exposed...would make it much easier to update the
    //index, and more reliable if the user can go backwards now as well...with the history section.
#warning somehow respond to the fact that the current song has changed. Update NSIndexSets???
}

/** All the items in the snapshot. */
- (NSArray<PlayableItem*> *)allItemsInSnapshot
{
    NSAssert(!_didPrepareForDeletion, @"Can't access items in snapshot after preparing for deletion!");
    return _allSnapshotItems;
}

/** Items which were previously played (these items are not necessarily part of the current queue.) */
- (NSArray<PlayableItem*> *)historySongs
{
    NSAssert(!_didPrepareForDeletion, @"Can't access items in snapshot after preparing for deletion!");
    if(_historyItemsRange.location == NSNotFound) {
        return @[];
    }
    return [_allSnapshotItems subarrayWithRange:_historyItemsRange];
}

/** Items which have been queued up on the fly. */
- (NSArray<PlayableItem*> *)upNextQueuedSongs
{
    NSAssert(!_didPrepareForDeletion, @"Can't access items in snapshot after preparing for deletion!");
    if(_upNextQueuedItemsRange.location == NSNotFound) {
        return @[];
    }
    return [_allSnapshotItems subarrayWithRange:_upNextQueuedItemsRange];
}

/** Items which are coming up in the main queue (NOT the queue that can be made on the fly.) */
- (NSArray<PlayableItem*> *)futureSongs
{
    NSAssert(!_didPrepareForDeletion, @"Can't access items in snapshot after preparing for deletion!");
    if(_allFutureItemsRange.location == NSNotFound) {
        return @[];
    }
    return [_allSnapshotItems subarrayWithRange:_allFutureItemsRange];
}


- (NSRange)rangeOfHistoryItems
{
    return _historyItemsRange;
}
- (NSUInteger)nowPlayingIndex
{
    return _nowPlayingIndex;
}
- (NSRange)upNextQueuedItemsRange
{
    return _upNextQueuedItemsRange;
}
- (NSRange)futureItemsRange
{
    return _allFutureItemsRange;
}

/** Call this when you no longer need to maintain the actual items from this snapshot in memory,
 and you only want the NSRanges and now playing index. */
- (void)prepareForDeletion
{
    [[NSNotificationCenter defaultCenter] removeObserver:MZNewSongLoading];
    _allSnapshotItems = nil;
    _didPrepareForDeletion = YES;
}

@end
