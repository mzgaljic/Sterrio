//
//  MZPlaybackQueueSnapshot.h
//  Sterrio
//
//  Created by Mark Zgaljic on 6/23/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//
// Note: Represents the entire playback queue at a particular point in time, i.e. a 'snapshot'.
//       It is designed to easily construct a gui that can represent the queue.

#import <Foundation/Foundation.h>
#import "PlayableItem.h"

@interface MZPlaybackQueueSnapshot : NSObject

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
           rangeOfAllFutureItems:(NSRange)allFutureItemsRange;

/** All the songs in the snapshot. */
- (NSArray<PlayableItem*> *)allSongsInSnapshot;
/** Items which were previously played (these items are not necessarily part of the current queue.) */
- (NSArray<PlayableItem*> *)historySongs;
/** Items which have been queued up on the fly. */
- (NSArray<PlayableItem*> *)upNextQueuedSongs;
/** Items which are coming up in the main queue (NOT the queue that can be made on the fly.) */
- (NSArray<PlayableItem*> *)futureSongs;

@end
