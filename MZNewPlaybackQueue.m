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

@interface MZNewPlaybackQueue ()
@property (nonatomic, strong) PlaybackContext *mainContext;
@property (nonatomic, strong) MZEnumerator *mainEnumerator;

@property (nonatomic, strong) PlayableItem *mostRecentItem;
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
    _mostRecentItem = nil;
}

/** 
 Attempt to get the new index of the now-playing-song within the results (if they changed after the context 
 was saved.) Then, re-initialize the mainEnumerator so it doesn't get out of sync with the latest changes by 
 the user. */
- (void)managedObjectContextDidSave:(NSNotification *)note
{
    //can no longer trust that the array in memory is reflecting what the user saved into the library.
    //Re-fetch & get current index.
    NSArray *results = [MZNewPlaybackQueue attemptFetchRequest:_mainContext.request batchSize:INTERNAL_FETCH_BATCH_SIZE];
    if(results == nil) {
        return;  //not much we can do at this point. Continue using existing enumerator (not perfect but will do.)
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

- (void)setShuffleState:(SHUFFLE_STATE)state {}
- (void)setRepeatMode:(PLABACK_REPEAT_MODE)mode {}

#pragma mark - DEBUG
+ (void)printQueueContents:(MZNewPlaybackQueue *)queue {}



//---- Utils ----
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
    if(_mainEnumerator != nil) {
        return (direction == SeekForward) ? [_mainEnumerator nextObject] : [_mainEnumerator previousObject];
    }
    return nil;
}

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
- (PlayableItem *)itemAtIndex:(NSUInteger)index inArray:(NSArray **)array withContext:(PlaybackContext *)context queuedSong:(BOOL)queued
{
    if((*array) == nil || index >= (*array).count)
        return nil;
    
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
