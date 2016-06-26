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

@interface MZNewPlaybackQueue ()
@property (nonatomic, strong) PlaybackContext *mainContext;
@property (nonatomic, strong) MZEnumerator *mainEnumerator;
@property (nonatomic, strong) MZEnumerator *shuffledMainEnumerator;

//helps when the shuffle state changes.
@property (nonatomic, strong) MZEnumerator *lastUsedEnumerator;

@property (nonatomic, strong) PlayableItem *mostRecentItem;
@property (nonatomic, assign) SHUFFLE_STATE shuffleState;
@end
@implementation MZNewPlaybackQueue

short const INTERNAL_FETCH_BATCH_SIZE = 5;
short const EXTERNAL_FETCH_BATCH_SIZE = 150;

typedef NS_ENUM(NSInteger, SeekDirection) { SeekForward, SeekBackwards };

- (id)initWithNewNowPlayingPlayableItem:(PlayableItem *)item
{
    if(self = [super init]) {
        _mainContext = item.contextForItem;
        _mostRecentItem = nil;
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
#warning need to also add logic for shuffled enumerator here.
    //can no longer trust that the array in memory is reflecting what the user saved into the library.
    //Re-fetch & get current index.
    NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request batchSize:INTERNAL_FETCH_BATCH_SIZE];
    if(results == nil) {
        //not much we can do at this point. Continue using existing enumerator (not perfect but will do.)
        return;
    }
    
    NSUInteger nowPlayingIndex = NSNotFound;  //should point to now playing within the new results
    if(![NowPlaying sharedInstance].playableItem.isFromUpNextSongs) {
        //we can directly get the now-playing-item from the NowPlaying class (more robust approach.)
        nowPlayingIndex = [self indexOfItem:[NowPlaying sharedInstance].playableItem inArray:&results];
    } else {
        //as fallback, use the 'mostRecentItem' to attempt finding the now-playing-item.
        nowPlayingIndex = [self indexOfItem:_mostRecentItem inArray:&results];
    }
    
    if(nowPlayingIndex != NSNotFound) {
        _mainEnumerator = [results biDirectionalEnumeratorAtIndex:nowPlayingIndex];
    }
}

- (MZPlaybackQueueSnapshot *)snapshotOfPlaybackQueue
{
#warning no implementation.
    return nil;
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

- (void)setShuffleState:(SHUFFLE_STATE)state
{
    SHUFFLE_STATE prevShuffleState = _shuffleState;
    if(state == prevShuffleState) {
        return;
    }
    _shuffleState = prevShuffleState;
    if(_shuffleState == SHUFFLE_STATE_Enabled) {
        if(_shuffledMainEnumerator == nil) {
            NSMutableArray *shallowCopy = [[_mainEnumerator underlyingArray] mutableCopy];
            [MZArrayShuffler shuffleArray:&shallowCopy];
            _shuffledMainEnumerator = [shallowCopy biDirectionalEnumerator];
        }
    } else if(_shuffleState == SHUFFLE_STATE_Disabled) {
        _shuffledMainEnumerator = nil;
#warning need logic to get the same item in the unshuffled array now (I think.) See how Apple music and itunes do it.
    }
}

#pragma mark - DEBUG
+ (void)printQueueContents:(MZNewPlaybackQueue *)queue
{
#warning no implementation.
}



//---- Utils ----
// Grabs the next item in the direction specified. Item will be taken from the shuffled enumerator if
//it exists. Otherwise, from the main-enumerator.
- (PlayableItem *)seekNextItemInDirection:(enum SeekDirection)direction
{
    if(_mainContext == nil || _mainContext.request == nil) {
        return nil;
    }
    if(_mainEnumerator == nil) {
        NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request
                                                         batchSize:INTERNAL_FETCH_BATCH_SIZE];
        if(results != nil) {
            _mainEnumerator = [results biDirectionalEnumerator];
        }
    }
    MZEnumerator *enumerator = nil;
    if(_shuffledMainEnumerator != nil) { enumerator = _shuffledMainEnumerator; }
    if(_mainEnumerator != nil) { enumerator = _mainEnumerator; }
    
    if(enumerator != nil) {
        return (direction == SeekForward) ? [enumerator nextObject] : [enumerator previousObject];
    }
    return nil;
}

//Determine the location of the PlayableItem in the core data array, returns index or NSNotFound.
- (NSUInteger)indexOfItem:(PlayableItem *)item inArray:(NSArray **)array
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

@end
