//
//  MZPrivateMainPlaybackQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/10/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZPrivateMainPlaybackQueue.h"
#import "PlayableItem.h"
#import "PlaylistItem.h"

@interface MZPrivateMainPlaybackQueue ()
{
    PlaybackContext *playbackContext;
    NSUInteger fetchRequestIndex;  //keeping track where we left off within a fetchrequest
    PlayableItem *mostRecentItem;
    BOOL atEndOfQueue;
    BOOL userWentBeyondStartOfQueue;
    BOOL userWentBeyondEndOfQueue;
}
@end
@implementation MZPrivateMainPlaybackQueue

- (instancetype)init
{
    if(self = [super init]){
        playbackContext = nil;
        fetchRequestIndex = 0;
        atEndOfQueue = NO;
        userWentBeyondStartOfQueue = NO;
        userWentBeyondEndOfQueue = NO;
    }
    return self;
}

- (NSUInteger)numItemsInEntireMainQueue
{
    //no fault at all here  :)
    if(playbackContext.request != nil){
        return [[CoreDataManager context] countForFetchRequest:playbackContext.request error:nil];
    } else{
        return 0;
    }
}

- (NSUInteger)numMoreItemsInMainQueue
{
    return [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                nowPlayingInclusive:NO
                                                 onlyUnplayedTracks:YES].count;
}

- (void)setMainQueueWithNewNowPlayingItem:(PlayableItem *)item
{
    playbackContext = nil;
    playbackContext = item.contextForItem;
    atEndOfQueue = NO;
    userWentBeyondStartOfQueue = NO;
    userWentBeyondEndOfQueue = NO;
    
    NSArray *items = [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                          nowPlayingInclusive:YES
                                                           onlyUnplayedTracks:NO];
    if(items > 0){
        NSUInteger index = [self indexOfItem:item inArray:&items];
        if(index != NSNotFound){
            mostRecentItem = [self itemAtIndex:index inArray:&items];
            fetchRequestIndex = index;
            if(items.count > 1)
                atEndOfQueue = NO;
            else
                atEndOfQueue = YES;
            return;
        }
    }
    fetchRequestIndex = 0;
}

- (NSArray *)tableViewOptimizedArrayOfMainQueuePlayableItemsComingUp
{
    return [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:EXTERNAL_FETCH_BATCH_SIZE
                                                nowPlayingInclusive:YES
                                                 onlyUnplayedTracks:YES];
}

- (PlaybackContext *)mainQueuePlaybackContext
{
    return playbackContext;
}

- (void)clearMainQueue
{
    playbackContext = nil;
    mostRecentItem = nil;
    fetchRequestIndex = 0;
    atEndOfQueue = NO;
    userWentBeyondStartOfQueue = NO;
    userWentBeyondEndOfQueue = NO;
}

- (PlayableItem *)skipToPrevious
{
    if(playbackContext == nil)
        return nil;
    else{
        if([NowPlayingSong sharedInstance].nowPlayingItem.isFromUpNextSongs){
            return mostRecentItem;
        }
        
        NSArray *items = [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                              nowPlayingInclusive:YES
                                                               onlyUnplayedTracks:NO];
        if(items.count > 0){
            NSUInteger index = [self indexOfItem:mostRecentItem inArray:&items];
            if(index != fetchRequestIndex)
                fetchRequestIndex = index;
            
            if(fetchRequestIndex == 0){
                //value is 0 before decrementing
                if(items.count == 1)
                    atEndOfQueue = YES;
                if(userWentBeyondEndOfQueue){
                    //dont actually decrement the index, just return the last item since the
                    //user previously skipped "past" the last index in the array.
                    userWentBeyondEndOfQueue = NO;
                    mostRecentItem = [self itemAtIndex:index inArray:&items];
                    return mostRecentItem;
                }else
                    userWentBeyondStartOfQueue = YES;
                return nil;  //no songs before index 0.
            }
            if(userWentBeyondEndOfQueue){
                //dont actually decrement the index, just return the last item since the
                //user previously skipped "past" the last index in the array.
                userWentBeyondEndOfQueue = NO;
                mostRecentItem = [self itemAtIndex:index inArray:&items];
                return mostRecentItem;
            }
            
            
            //fetchRequestIndex is unsigned, will only be decremented here if the previous value
            //was greater than 0 (avoiding accidentally setting it to a negative value).
            index = --fetchRequestIndex;
            
            if(fetchRequestIndex == items.count-1 || fetchRequestIndex > items.count-1){
                atEndOfQueue = YES;
            } else
                atEndOfQueue = NO;
            
            //simply grabbing the previous item
            mostRecentItem = [self itemAtIndex:index inArray:&items];
            return mostRecentItem;
        } else{
            return nil;
        }
    }
}

- (PlayableItem *)skipForward
{
    if(playbackContext == nil)
        return nil;
    else{
        NSArray *items = [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                              nowPlayingInclusive:YES
                                                               onlyUnplayedTracks:NO];
        if(items.count > 0){
            NSUInteger index = [self indexOfItem:mostRecentItem inArray:&items];
            if(index != fetchRequestIndex)
                fetchRequestIndex = index;
            if(userWentBeyondStartOfQueue){
                //user is just going to play item at index 0 now, since they previously went
                //"behind" the bounds of index 0.
                userWentBeyondStartOfQueue = NO;
                mostRecentItem = [self itemAtIndex:index inArray:&items];
                return mostRecentItem;
            } else if(userWentBeyondEndOfQueue)
                return nil;
            else if(fetchRequestIndex == items.count-1){
                //dont let user beyond end of array.
                userWentBeyondEndOfQueue = YES;
                return nil;
            }
            
            index = ++fetchRequestIndex;
            
            if(fetchRequestIndex > items.count-1){
                atEndOfQueue = YES;
                //no more items, reached the last one
                return nil;
            } else{
                //simply grabbing the next item
                mostRecentItem = [self itemAtIndex:index inArray:&items];
                return mostRecentItem;
            }
        } else{
            return nil;
        }
    }
}

- (PlayableItem *)skipToBeginningOfQueue
{
    //fetchRequestIndex
    if(playbackContext == nil)
        return nil;
    else{
        NSArray *items = [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                              nowPlayingInclusive:YES
                                                               onlyUnplayedTracks:NO];
        if(items.count > 0){
            PlayableItem *firstItemInMainQueue = [self itemAtIndex:0 inArray:&items];
            fetchRequestIndex = 0;
            mostRecentItem = firstItemInMainQueue;
            if(items.count == 1)
                atEndOfQueue = YES;
            else
                atEndOfQueue = NO;
            userWentBeyondStartOfQueue = NO;
            userWentBeyondEndOfQueue = NO;
            return firstItemInMainQueue;
        }
        else{
            return nil;
        }
    }
}

- (void)efficientlySkipTheseManyItems:(NSUInteger)numToSkip
{
    if(playbackContext == nil)
        return;
    else{
        int reasonableBatchSize = 3;
        NSArray *items = [self minimallyFaultedArrayOfMainQueueItemsWithBatchSize:reasonableBatchSize
                                                              nowPlayingInclusive:YES
                                                               onlyUnplayedTracks:NO];
        if(items.count > 0){
            NSUInteger index = [self indexOfItem:mostRecentItem inArray:&items];
            if(index != fetchRequestIndex)
                fetchRequestIndex = index;
            if(userWentBeyondStartOfQueue){
                //user is just going to move toward the item at index 0 now, since they previously went
                //"behind" the bounds of index 0.
                userWentBeyondStartOfQueue = NO;
                index += numToSkip;
                mostRecentItem = [self itemAtIndex:index inArray:&items];
                return;
            } else if(userWentBeyondEndOfQueue)
                return;
            else if(fetchRequestIndex == items.count-1){
                //dont let user beyond end of array.
                userWentBeyondEndOfQueue = YES;
                return;
            }
            
            if(fetchRequestIndex > items.count-1){
                atEndOfQueue = YES;
                //no more items can possibly be skipped...reached the last one.
                return;
            } else{
                index += numToSkip;
                mostRecentItem = [self itemAtIndex:index inArray:&items];
                return;
            }
        } else{
            return;
        }
    }
}

//--------------private helpers--------------

//for getting an array of all up next items, without putting all items into memory.
- (NSMutableArray *)minimallyFaultedArrayOfMainQueueItemsWithBatchSize:(int)batchSize
                                            nowPlayingInclusive:(BOOL)inclusive
                                             onlyUnplayedTracks:(BOOL)unplayed
{
    if(userWentBeyondEndOfQueue && unplayed)
        return [NSMutableArray array];
    
    NSMutableArray *compiledItems = [NSMutableArray array];
    NSFetchRequest *request = playbackContext.request;
    if(request == nil)
        return compiledItems;
    [request setFetchBatchSize:INTERNAL_FETCH_BATCH_SIZE];
    NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:nil];
    NSUInteger nowPlayingIndex;
    if(userWentBeyondStartOfQueue){
        if(array.count >= 1)
            nowPlayingIndex = 0;
        else
            nowPlayingIndex = NSNotFound;
    } else{
        if([NowPlayingSong sharedInstance].nowPlayingItem.isFromUpNextSongs)
            nowPlayingIndex = [self indexOfItem:mostRecentItem inArray:&array];
        else
            nowPlayingIndex = [self indexOfItem:[NowPlayingSong sharedInstance].nowPlayingItem inArray:&array];
    }
    
    NSArray *desiredSubArray;
    if(nowPlayingIndex != NSNotFound && unplayed){
        NSRange range;
        if(inclusive)
            range = NSMakeRange(nowPlayingIndex, array.count-1);
        else{
            if(nowPlayingIndex < array.count-1)
                //at least 1 more item in array
                range = NSMakeRange(nowPlayingIndex+1, array.count-1);
            else
                //last item reached, no items to show...return empty array instead of allowing index out of bounds.
                return [NSMutableArray array];
        }
        desiredSubArray = [array subarrayWithRange:NSMakeRange(nowPlayingIndex+1, (array.count-1) - nowPlayingIndex)];
    }
    if((atEndOfQueue && !unplayed) || (desiredSubArray == nil && !unplayed))
        desiredSubArray = array;
    
    [compiledItems addObjectsFromArray:desiredSubArray];
    return compiledItems;
}

- (NSUInteger)indexOfItem:(PlayableItem *)item inArray:(NSArray **)array
{
    NSUInteger index = [*array indexOfObject:item.songForItem];
    if(index == NSNotFound)
        index = [*array indexOfObject:item.playlistItemForItem];
    return index;
}

//this is used to make sure we always work with PlayableItem objects.
- (PlayableItem *)itemAtIndex:(NSUInteger)index inArray:(NSArray **)array
{
    if(index >= (*array).count)
        return nil;
    
    id obj = [*array objectAtIndex:index];
    if([obj isMemberOfClass:[PlayableItem class]])
        return (PlayableItem *)obj;
    else if([obj isMemberOfClass:[Song class]]){
        return [[PlayableItem alloc] initWithSong:(Song *)obj context:playbackContext fromUpNextSongs:NO];
    }
    else if([obj isMemberOfClass:[PlaylistItem class]])
        return [[PlayableItem alloc] initWithPlaylistItem:(PlaylistItem *)obj context:playbackContext fromUpNextSongs:NO];
    else
        return nil;
}

@end