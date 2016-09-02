//
//  MZPlaybackQueueSnapshot.m
//  Sterrio
//
//  Created by Mark Zgaljic on 6/23/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZPlaybackQueueSnapshot.h"

@interface MZPlaybackQueueSnapshot ()
@property (nonatomic, strong) NSArray<Song*> *allSnapshotSongs;
@property (nonatomic, strong) NSIndexSet *historySongsIndexSet;
@property (nonatomic, assign) NSUInteger nowPlayingIndex;
@property (nonatomic, strong) NSIndexSet *manuallyQueuedSongsIndexSet;
@property (nonatomic, strong) NSIndexSet *allFutureSongsIndexSet;
@end
@implementation MZPlaybackQueueSnapshot

/**
 * @brief Creates a snapshot of the queue in such a way that it becomes trivial to display graphically to
 *        the user.
 * @param songs all the songs that are to be displayed (graphically) to the user.
 * @param historySongsIndexSet  identifies which indexes in the 'songs' array are part of the users
 *                              history. Meaning, the user actually played these songs for at least x
 *                              seconds. These songs were previously played (and are not necessarily part of
 *                              the current queue.)
 * @param manuallyQueuedSongsIndexSet  Songs which have been manually queued up by the user.
 * @param index  index of the now playing song (at the time of QueueSnapshot creation.)
 * @param allFutureSongsIndexSet  Songs coming up in the main playback queue (not the temporary queue that
 *                                the user can build on the fly.) These are songs which have not been 
 *                                played.
 */
- (id)initQueueSnapshotWithSongs:(NSArray<Song*> *)songs
             indxSetHistorySongs:(NSIndexSet *)historySongsIndexSet
                 nowPlayingIndex:(NSUInteger)index
      indxSetManuallyQueuedSongs:(NSIndexSet *)manuallyQueuedSongsIndexSet
           indxSetAllFutureSongs:(NSIndexSet *)allFutureSongsIndexSet
{
    if(self = [super init]) {
        NSAssert(songs != nil, @"cannot create queue snapshot with nil songs parameter.");
        NSAssert(historySongsIndexSet != nil, @"cannot create queue snapshot with nil historSongsIndexSet parameter.");
        NSAssert(index != NSNotFound, @"cannot create queue snapshot with nowPlayingIndex == NSNotFound.");
        NSAssert(manuallyQueuedSongsIndexSet != nil, @"cannot create queue snapshot with nil manuallyQueuedSongsIndexSet parameter.");
        NSAssert(allFutureSongsIndexSet != nil, @"cannot create queue snapshot with nil allFutureSongsIndexSet parameter.");
        _allSnapshotSongs = songs;
        _historySongsIndexSet = historySongsIndexSet;
        _nowPlayingIndex = index;
        _manuallyQueuedSongsIndexSet = manuallyQueuedSongsIndexSet;
        _allFutureSongsIndexSet = allFutureSongsIndexSet;
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
#warning somehow respond to the fact that the current song has changed. Update NSIndexSets???
}

/** All the songs in the snapshot. */
- (NSArray<Song*> *)allSongsInSnapshot
{
    return _allSnapshotSongs;
}

/** Songs which were previously played (these songs are not necessarily part of the current queue.) */
- (NSArray<Song*> *)historySongs
{
    return [_allSnapshotSongs objectsAtIndexes:_historySongsIndexSet];
}

/** Songs which have been queued up on the fly. */
- (NSArray<Song*> *)manuallyQueuedSongs
{
    return [_allSnapshotSongs objectsAtIndexes:_manuallyQueuedSongsIndexSet];
}

/** Songs which are coming up in the main queue (NOT the queue that can be made on the fly.) */
- (NSArray<Song*> *)futureSongs
{
    return [_allSnapshotSongs objectsAtIndexes:_allFutureSongsIndexSet];
}

@end
