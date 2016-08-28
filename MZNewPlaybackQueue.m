//
//  MZNewPlaybackQueue.m
//  Sterrio
//
//  Created by Mark Zgaljic on 6/23/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZNewPlaybackQueue.h"
#import "PlaylistItem.h"
#import "CoreDataManager.h"
#import "MZArrayShuffler.h"
#import "Queue.h"

@interface MZNewPlaybackQueue ()
@property (nonatomic, strong) PlaybackContext *mainContext;
@property (nonatomic, strong) MZEnumerator *enumerator;
@property (nonatomic, strong) MZEnumerator *mainEnumerator;
@property (nonatomic, strong) MZEnumerator *shuffledMainEnumerator;

//user can never go 'back'. Tapping 'back' would take you to the previous song in the mainEnumerator
//(or main shuffled enumerator.)
#warning need to change implementation to use the PlaybackContext. See queueSongsOnTheFlyWithContext()
@property (nonatomic, strong) Queue *upNextQueue;

//helps when the shuffle state changes.
@property (nonatomic, strong) MZEnumerator *lastUsedEnumerator;

@property (nonatomic, strong) PlayableItem *mostRecentItem;
@end
@implementation MZNewPlaybackQueue

short const INTERNAL_FETCH_BATCH_SIZE = 5;
short const EXTERNAL_FETCH_BATCH_SIZE = 150;

typedef NS_ENUM(NSInteger, SeekDirection) { SeekForward, SeekBackwards };


static id sharedNewPlaybackQueueInstance = nil;
+ (instancetype)sharedInstance
{
    return sharedNewPlaybackQueueInstance;
}

+ (void)discardInstance
{
    sharedNewPlaybackQueueInstance = nil;
}

+ (instancetype)newInstanceWithSongsQueuedOnTheFly:(PlaybackContext *)context
{
    sharedNewPlaybackQueueInstance = nil;
    sharedNewPlaybackQueueInstance = [[MZNewPlaybackQueue alloc] initWithSongsQueuedOnTheFly:context];
    return sharedNewPlaybackQueueInstance;
}

+ (instancetype)newInstanceWithNewNowPlayingPlayableItem:(PlayableItem *)item
{
    sharedNewPlaybackQueueInstance = nil;
    sharedNewPlaybackQueueInstance = [[MZNewPlaybackQueue alloc] initWithNewNowPlayingPlayableItem:item];
    return sharedNewPlaybackQueueInstance;
}

//private init
- (id)initWithSongsQueuedOnTheFly:(PlaybackContext *)context
{
    if(self = [super init]) {
        _upNextQueue = [[Queue alloc] init];
        _mainContext = context;
#warning some implementation still needed
        //_mostRecentItem = item;
        _shuffleState = SHUFFLE_STATE_Disabled;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:[CoreDataManager context]];
    }
    return self;
}

//private init
- (id)initWithNewNowPlayingPlayableItem:(PlayableItem *)item
{
    if(self = [super init]) {
        _upNextQueue = [[Queue alloc] init];
        _mainContext = item.contextForItem;
        _mostRecentItem = item;
        _shuffleState = SHUFFLE_STATE_Disabled;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:[CoreDataManager context]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _mainContext = nil;
    _mainEnumerator = nil;
    _shuffledMainEnumerator = nil;
    _mostRecentItem = nil;
}

/** 
 Attempt to get the new index of the now-playing-song within the results (if they changed after the context 
 was saved.) Then, re-initialize the mainEnumerator so it doesn't get out of sync with the latest changes by 
 the user. 
 */
- (void)managedObjectContextDidSave:(NSNotification *)note
{
    //can no longer trust that the array in memory is reflecting what the user saved into the library.
    //Re-fetch & get current index.
    NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request batchSize:INTERNAL_FETCH_BATCH_SIZE];
    if(results != nil) {
        //should point to now playing within the new results (or NSNotFound)
        NSUInteger nowPlayingIndex = [self computeNowPlayingIndexInCoreDataArray:&results];
        if(nowPlayingIndex != NSNotFound) {
            _mainEnumerator = [results biDirectionalEnumeratorAtIndex:nowPlayingIndex
                                             withOutOfBoundsTolerance:1];
        }
    }
    
    if(_shuffledMainEnumerator != nil) {
        _shuffledMainEnumerator = nil;
        //shuffle mode is active. Now that the main enumerator has been refetched, lets shuffle it and
        //keep the cursor pointing to the same NowPlayingItem.
        NSMutableArray *shallowCopy = [[_mainEnumerator underlyingArray] mutableCopy];
        [MZArrayShuffler shuffleArray:&shallowCopy];
        
        //logic to get the same item in the new array now...
        NSUInteger nowPlayingIndex = [self computeNowPlayingIndexInCoreDataArray:&shallowCopy];
        if(nowPlayingIndex != NSNotFound) {
            _shuffledMainEnumerator = [shallowCopy biDirectionalEnumeratorAtIndex:nowPlayingIndex
                                                         withOutOfBoundsTolerance:1];
        } else {
            //fallback for when something bad happens lol.
            _shuffledMainEnumerator = [shallowCopy biDirectionalEnumerator];
        }
    }
}

- (MZPlaybackQueueSnapshot *)snapshotOfPlaybackQueue
{
#warning no implementation.
    return nil;
}

- (PlayableItem *)currentItem
{
    return _mostRecentItem;
}

- (PlayableItem *)seekBackOneItem
{
    _mostRecentItem = [self seekNextItemInDirection:SeekBackwards];
    return _mostRecentItem;
}
- (PlayableItem *)seekForwardOneItem
{
    _mostRecentItem = [self seekNextItemInDirection:SeekForward];
    return _mostRecentItem;
}

- (PlayableItem *)seekToFirstItemInMainQueueAndReshuffleIfNeeded
{
    if(_mainContext == nil || _mainContext.request == nil) {
        return nil;
    }
    
    //toggle shuffle state to trigger a re-shuffle (if shuffle was on to begin with)
    if(_shuffleState == SHUFFLE_STATE_Enabled) {
        [self setShuffleState:SHUFFLE_STATE_Disabled];
        [self setShuffleState:SHUFFLE_STATE_Enabled];
    }
    if(_mainEnumerator == nil) {
        NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request
                                                         batchSize:INTERNAL_FETCH_BATCH_SIZE];
        if(results != nil) {
            _mainEnumerator = [MZNewPlaybackQueue buildEnumeratorFromArray:&results
                                                  withCursorPointingToItem:_mostRecentItem];
        }
    }
    if(_mainEnumerator != nil) {
        id firstObj = [_mainEnumerator moveTofirstObject];
        return [MZNewPlaybackQueue wrapAsPlayableItem:firstObj
                                              context:_mainContext
                                           queuedSong:NO];
    }
    return nil;
}

//Queues the stuff described by PlaybackContext to the playback queue.
- (void)queueSongsOnTheFlyWithContext:(PlaybackContext *)context
{
    NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:context.request
                                                     batchSize:INTERNAL_FETCH_BATCH_SIZE];
    if(results != nil) {
        MZEnumerator *enumeratorForContext = [MZNewPlaybackQueue buildEnumeratorFromArray:&results
                                                                 withCursorPointingToItem:_mostRecentItem];
        [_upNextQueue enqueue:enumeratorForContext];
    }
}

//# of PlayableItem's that still need to play (includes main context and stuff queued by user on the fly.
- (NSUInteger)forwardItemsCount
{
    NSUInteger count = 0;
    if(_mainContext.request != nil){
        //gets count from CoreData w/out triggering any 'faults'
        NSUInteger totalContextCount = [[CoreDataManager context] countForFetchRequest:_mainContext.request
                                                                                 error:nil];
        if(_mainEnumerator == nil) {
            NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request
                                                             batchSize:INTERNAL_FETCH_BATCH_SIZE];
            if(results != nil) {
                _mainEnumerator = [MZNewPlaybackQueue buildEnumeratorFromArray:&results
                                                      withCursorPointingToItem:_mostRecentItem];
            }
        }
        NSArray *fetchResults = [_mainEnumerator underlyingArray];
        NSUInteger nowPlayingIndex = [self computeNowPlayingIndexInCoreDataArray:&fetchResults];
        if(totalContextCount > 0 && nowPlayingIndex != NSNotFound) {
            count += (totalContextCount - 1 - nowPlayingIndex);
        }
    }
    count += _upNextQueue.count;
    return count;
}

- (NSUInteger)totalItemsCount
{
    NSUInteger count = 0;
    if(_mainContext.request != nil){
        //gets count from CoreData w/out triggering any 'faults'
        NSUInteger totalContextCount = [[CoreDataManager context] countForFetchRequest:_mainContext.request
                                                                                 error:nil];
        count += totalContextCount;
    }
    count += _upNextQueue.count;
    return count;
}

- (void)setShuffleState:(SHUFFLE_STATE)state
{
    SHUFFLE_STATE prevShuffleState = _shuffleState;
    if(state == prevShuffleState) {
        return;
    }
    _shuffleState = state;
    //some setup since mainEnumerator is used in a few lines...
    if(_mainEnumerator == nil) {
        NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request
                                                         batchSize:INTERNAL_FETCH_BATCH_SIZE];
        if(results != nil) {
            _mainEnumerator = [MZNewPlaybackQueue buildEnumeratorFromArray:&results
                                                  withCursorPointingToItem:_mostRecentItem];
        }
    }
    
    if(_shuffleState == SHUFFLE_STATE_Enabled) {
        if(_shuffledMainEnumerator == nil) {
            NSMutableArray *shallowCopy = [[_mainEnumerator underlyingArray] mutableCopy];
            [MZArrayShuffler shuffleArray:&shallowCopy];
            _shuffledMainEnumerator = [shallowCopy biDirectionalEnumeratorWithOutOfBoundsTolerance:1];
        }
    } else if(_shuffleState == SHUFFLE_STATE_Disabled) {
        //logic to get the same item in the unshuffled array now...
        NSArray *rawArray = [_shuffledMainEnumerator underlyingArray];
        NSUInteger nowPlayingIndex = [self computeNowPlayingIndexInCoreDataArray:&rawArray];
        if(nowPlayingIndex != NSNotFound) {
            _mainEnumerator = [rawArray biDirectionalEnumeratorAtIndex:nowPlayingIndex
                                             withOutOfBoundsTolerance:1];
        } else {
            //fallback for when something bad happens lol.
            _mainEnumerator = [rawArray biDirectionalEnumerator];
        }
        _shuffledMainEnumerator = nil;
    }
}

#pragma mark - DEBUG
//prints the queue contents and class info.
- (NSString *)description;
{
    MZEnumerator *enumeratorCopy = nil;
    //MZEnumerator performs a somewhat shallow copy. Everything is copied except for the underlying array.
    //(so a mod to an object in enumerator A will change it in enumerator B.)
    if(_shuffledMainEnumerator != nil) {
        enumeratorCopy = [_shuffledMainEnumerator copy];
    } else if(_mainEnumerator != nil) {
        enumeratorCopy = [_mainEnumerator copy];
    }
    
    NSMutableString *output = [NSMutableString string];
    if(enumeratorCopy != nil) {
        PlayableItem *nowPlaying = [enumeratorCopy currentObject];
        [output appendFormat:@"-> Now Playing: %@", nowPlaying];
        
        int queuedSongCount = 0;
        if(queuedSongCount) {
            [output appendString:@"-> Queued 'on the fly' songs:"];
            NSArray *queuedObjs = [_upNextQueue allQueueObjectsAsArray];
            for(int i = 0; i < queuedObjs.count; i++) {
                MZEnumerator *enumerator = queuedObjs[i];
                [output appendFormat:@"\nContext %i:\n", i+1];
                [output appendString:[enumerator description]];
            }
        }
        
        PlayableItem *item;
        NSUInteger index = 0;
        while([enumeratorCopy hasNext]) {
            if(index == 0) {
                [output appendString:@"\n-> Main queue songs coming up:"];
            }
            index++;
            item = [MZNewPlaybackQueue wrapIntoDummyPlayableItemObj:[enumeratorCopy nextObject]];
            [output appendFormat:@"\n%100lu - %@", (unsigned long)index, item];
        }
    }
    return output;
}

+ (PlayableItem *)wrapAsPlayableItem:(id)obj context:(PlaybackContext *)cntx queuedSong:(BOOL)isQueuedItem
{
    if([obj isMemberOfClass:[Song class]]) {
        return [[PlayableItem alloc] initWithSong:(Song *)obj context:cntx fromUpNextSongs:isQueuedItem];
    } else if([obj isMemberOfClass:[PlaylistItem class]]) {
        return [[PlayableItem alloc] initWithPlaylistItem:(PlaylistItem *)obj
                                                  context:cntx
                                          fromUpNextSongs:isQueuedItem];
    } else {
        return nil;
    }

}

+ (PlayableItem *)wrapIntoDummyPlayableItemObj:(id)object
{
    return [MZNewPlaybackQueue wrapAsPlayableItem:object context:nil queuedSong:NO];
}


//---- Utils ----
// Grabs the next item in the direction specified. Item will be taken from the shuffled-enumerator if
//it exists. Otherwise, from the main-enumerator.
- (PlayableItem *)seekNextItemInDirection:(enum SeekDirection)direction
{
    if(_upNextQueue.count > 0) {
        MZEnumerator *enumeratorForContext = [_upNextQueue peek];
        if(enumeratorForContext.hasNext) {
            return [enumeratorForContext nextObject];
        } else {
            [_upNextQueue dequeue];
            return [self seekNextItemInDirection:direction];  //recursive
        }
    }
    if(_mainContext == nil || _mainContext.request == nil) {
        return nil;
    }
    if(_mainEnumerator == nil) {
        NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request
                                                         batchSize:INTERNAL_FETCH_BATCH_SIZE];
        if(results != nil) {
            _mainEnumerator = [MZNewPlaybackQueue buildEnumeratorFromArray:&results
                                                  withCursorPointingToItem:_mostRecentItem];
        }
    }
    MZEnumerator *enumerator = nil;
    if(_shuffledMainEnumerator != nil) { enumerator = _shuffledMainEnumerator; }
    if(_shuffledMainEnumerator == nil && _mainEnumerator != nil) { enumerator = _mainEnumerator; }
    
    if(enumerator != nil) {
        id obj = (direction == SeekForward) ? [enumerator nextObject] : [enumerator previousObject];
        return [MZNewPlaybackQueue wrapAsPlayableItem:obj context:_mainContext queuedSong:NO];
    }
    return nil;
}

//Determine the location of the PlayableItem in the core data array, returns index or NSNotFound.
+ (NSUInteger)indexOfItem:(PlayableItem *)item inCoreDataArray:(NSArray **)array
{
    NSUInteger index = NSNotFound;
    //only 1 of the following should be non-nil: playlistItemForItem | songForItem
    if(item.playlistItemForItem == nil && item.songForItem != nil) {
        index = [*array indexOfObject:item.songForItem];
    } else if(item.playlistItemForItem != nil && item.songForItem == nil) {
        index = [*array indexOfObject:item.playlistItemForItem];
    }
    return index;
}

//this is used to make sure we always work with PlayableItem objects.
- (PlayableItem *)itemAtIndex:(NSUInteger)index
                      inArray:(NSArray **)array
                  withContext:(PlaybackContext *)context
                   queuedSong:(BOOL)queued
{
    if((*array) == nil || index >= (*array).count) {
        return nil;
    }
    
    id obj = [*array objectAtIndex:index];
    if([obj isMemberOfClass:[PlayableItem class]]) {
        return (PlayableItem *)obj;
        
    } else if([obj isMemberOfClass:[Song class]]){
        return [[PlayableItem alloc] initWithSong:(Song *)obj context:context fromUpNextSongs:queued];
        
    } else if([obj isMemberOfClass:[PlaylistItem class]]) {
        return [[PlayableItem alloc] initWithPlaylistItem:(PlaylistItem *)obj context:context fromUpNextSongs:queued];
    } else {
        return nil;
    }
}

/** Returns the fetched array, or nil. */
+ (NSArray *)attemptFetchRequest:(NSFetchRequest *)request batchSize:(NSUInteger)size
{
    if(request == nil) {
        //not much we can do to recover! lets continue using the enumerator (even if its not perfect.)
        return nil;
    }
    [request setFetchBatchSize:size];
    NSError *error = NULL;
    NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:&error];
    return (error) ? nil : array;
}

/**
 * Returns the index of the now playing PlayableItem within the array, or NSNotFound if computation fails.
 */
- (NSUInteger)computeNowPlayingIndexInCoreDataArray:(NSArray **)array
{
    NSUInteger nowPlayingIndex = NSNotFound;  //should point to now playing within the main context
    if(![NowPlaying sharedInstance].playableItem.isFromUpNextSongs) {
        //we can directly get the now-playing-item from the NowPlaying class (more robust approach.)
        nowPlayingIndex = [MZNewPlaybackQueue indexOfItem:[NowPlaying sharedInstance].playableItem
                            inCoreDataArray:array];
    } else {
        //as fallback, use the 'mostRecentItem' to attempt finding the now-playing-item.
        nowPlayingIndex = [MZNewPlaybackQueue indexOfItem:_mostRecentItem
                            inCoreDataArray:array];
    }
    return nowPlayingIndex;
}

+ (MZEnumerator *)buildEnumeratorFromArray:(NSArray **)array
                  withCursorPointingToItem:(PlayableItem *)playableItem
{
    if(playableItem == nil) {
        return [(*array) biDirectionalEnumeratorWithOutOfBoundsTolerance:1];
    } else {
        NSUInteger idx = [MZNewPlaybackQueue indexOfItem:playableItem
                                         inCoreDataArray:array];
        return [(*array) biDirectionalEnumeratorAtIndex:idx withOutOfBoundsTolerance:1];
    }
}

@end
