//
//  MZPrivateUpNextPlaybackQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/9/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

//IMPORTANT: should improve an issue in this class. i am only saving the song index. if a context changes
//a lot (lots of songs added or removed), then the place where we left off from is corrupt...since the index
//may be completely misleading in such a scenario. should instead save the index AND the last song played in
//a specific context. then, we can make sure the index and song match, and if they dont we can choose to
//continue from the songs new index and update the saved index. and if the song is no longer in the context,
//then we can just choose a song after the saved index...if its valid.

#import "MZPrivateUpNextPlaybackQueue.h"
#import "PlayableItem.h"
#import "PlaylistItem.h"

@interface MZPrivateUpNextPlaybackQueue ()
{
    NSMutableArray *playbackContexts;
    NSMutableArray *fetchRequestIndexes;  //keeping track where we left off within a fetchrequest
}
@end
@implementation MZPrivateUpNextPlaybackQueue

- (instancetype)init
{
    if(self = [super init]){
        playbackContexts = [NSMutableArray arrayWithCapacity:10];
        fetchRequestIndexes = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)addItemsToUpNextWithContexts:(NSArray *)contexts
{
    [playbackContexts addObjectsFromArray:contexts];
    NSNumber *index = [NSNumber numberWithInt:0];
    NSMutableArray *tempNSNumsArray = [NSMutableArray array];
    for(int i = 0; i < contexts.count; i++){
        [tempNSNumsArray addObject:index];
    }
    [fetchRequestIndexes addObjectsFromArray:tempNSNumsArray];
}

- (NSUInteger)numMoreUpNextItemsCount
{
    NSArray *array = [self minimallyFaultedArrayOfUpNextItemsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE_OLD];
    if(array.count > 0){
        return array.count;
    } else
        return 0;
}

- (NSArray *)tableViewOptimizedArrayOfUpNextItems
{
    //dont need to insert a fake item in the front to represent now playing like we
    //needed to in the private main queue (implementation detail...)
    return [self minimallyFaultedArrayOfUpNextItemsWithBatchSize:EXTERNAL_FETCH_BATCH_SIZE_OLD];
}

- (NSArray *)tableViewOptimizedArrayOfUpNextItemsContexts
{
    //dont need to insert a fake item in the front to represent now playing like we
    //needed to in the private main queue (implementation detail...)
    return [NSMutableArray arrayWithArray:playbackContexts];
}

- (PlayableItem *)obtainAndRemoveNextItem
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    int numContextsToDelete = 0;
    PlayableItem *desiredItem;
    
    //iterate until we find the next item
    for(NSInteger i = 0; i < playbackContexts.count; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        [aRequest setFetchBatchSize:INTERNAL_FETCH_BATCH_SIZE_OLD];
        
        NSUInteger itemIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        
        NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
        itemIndex = [indexNumObj integerValue];
        if(itemIndex <= array.count-1 && array.count != 0)
            desiredItem = [self itemAtIndex:itemIndex inArray:&array withContext:aContext];
        else
            desiredItem = nil;  //index was out of bounds
        
        //advance
        itemIndex++;
        
        //this context is empty, or we have just pulled the very last item from this context.
        if(desiredItem == nil || itemIndex == array.count)
        {
            numContextsToDelete++;
        }
        else
        {
            NSNumber *newIndexObj = [NSNumber numberWithInteger:itemIndex];
            [fetchRequestIndexes replaceObjectAtIndex:i withObject:newIndexObj];
            break;
        }
    }
    
    //delete the contexts no longer needed
    for(int i = 0; i < numContextsToDelete; i++){
        if(playbackContexts.count-1 >= i){
            [playbackContexts removeObjectAtIndex:i];
            [fetchRequestIndexes removeObjectAtIndex:i];
        }
    }
    
    return desiredItem;
}

- (void)efficientlySkipTheseManyItems:(NSUInteger)numToSkip
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    int numContextsToDelete = 0;
    NSUInteger numItemsSkipped = 0;
    
    //iterate until we skip the desired amount of items...
    for(NSInteger i = 0; i < playbackContexts.count && numItemsSkipped != numToSkip; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        NSUInteger reasonableBatchSize = numToSkip + 10;
        [aRequest setFetchBatchSize:reasonableBatchSize];
        
        NSUInteger itemIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        
        NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
        itemIndex = [indexNumObj integerValue];
        BOOL indexWasOutOfBounds;
        if(itemIndex <= array.count-1 && array.count != 0)
            indexWasOutOfBounds = NO;
        else
            indexWasOutOfBounds = YES;
        
        //advance
        itemIndex++;
        numItemsSkipped++;
        
        //this context is empty, or we have just pulled the very last item from this context.
        if(indexWasOutOfBounds || itemIndex == array.count)
        {
            numContextsToDelete++;
        }
        else
        {
            NSNumber *newIndexObj = [NSNumber numberWithInteger:itemIndex];
            [fetchRequestIndexes replaceObjectAtIndex:i withObject:newIndexObj];
            break;
        }

        //now continue looping until the bool condition in the loop breaks the statement...
    }
    
    //delete the contexts no longer needed
    for(int i = 0; i < numContextsToDelete; i++){
        if(playbackContexts.count-1 >= i){
            [playbackContexts removeObjectAtIndex:i];
            [fetchRequestIndexes removeObjectAtIndex:i];
        }
    }
}

- (PlayableItem *)peekAtNextItem
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    PlayableItem *desiredItem;
    //iterate until we find a next song
    for(int i = 0; i < playbackContexts.count; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        [aRequest setFetchBatchSize:INTERNAL_FETCH_BATCH_SIZE_OLD];
        
        NSUInteger songIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        
        NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
        songIndex = [indexNumObj integerValue];
        desiredItem = [self itemAtIndex:songIndex inArray:&array withContext:aContext];
    }
    return desiredItem;
}

- (void)skipThisManySongsInQueue:(NSUInteger)numSongsToSkip
{
    //no implementation yet.
}

- (void)clearUpNext
{
    [playbackContexts removeAllObjects];
    [fetchRequestIndexes removeAllObjects];
}



//--------------private helpers--------------

//for getting an array of all up next items, without putting all items into memory.
- (NSMutableArray *)minimallyFaultedArrayOfUpNextItemsWithBatchSize:(int)batchSize
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    NSMutableArray *compiledItems = [NSMutableArray array];
    
    //iterate until we compile all items coming up
    for(int i = 0; i < playbackContexts.count; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        [aRequest setFetchBatchSize:batchSize];
        
        NSUInteger songIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        BOOL isContextRepresentingASingleItem = (array.count == 1);
        if(isContextRepresentingASingleItem)
        {
            PlayableItem *item = [self itemAtIndex:0 inArray:&array withContext:aContext];
            if(item)
                [compiledItems addObject:item];
        }
        else
        {
            NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
            songIndex = [indexNumObj integerValue];
            NSArray *itemsToAdd = [self itemsInArray:&array
                                 fromThisIndexOnward:songIndex
                                         withContext:aContext];
            [compiledItems addObjectsFromArray:itemsToAdd];
        }
    }
    
    return compiledItems;
}

- (PlayableItem *)itemAtIndex:(NSUInteger)index
                      inArray:(NSArray **)array
                  withContext:(PlaybackContext *)context
{
    if((*array).count -1 >= index)
    {
        id obj = [*array objectAtIndex:index];
        if([obj isMemberOfClass:[PlayableItem class]])
            return (PlayableItem *)obj;
        else if([obj isMemberOfClass:[Song class]]){
            return [[PlayableItem alloc] initWithSong:(Song *)obj
                                              context:context
                                      fromUpNextSongs:YES];
        }
        else if([obj isMemberOfClass:[PlaylistItem class]])
            return [[PlayableItem alloc] initWithPlaylistItem:(PlaylistItem *)obj
                                                      context:context
                                              fromUpNextSongs:YES];
    }

    return nil;
}

//guranteed to return at least a 0 sized array (as opposed to nil)
- (NSArray *)itemsInArray:(NSArray **)items
      fromThisIndexOnward:(NSUInteger)index
              withContext:(PlaybackContext *)context
{
    NSMutableArray *array = [NSMutableArray array];
    if((*items).count -1 >= index){
        for(int i = (int)index; i  < (*items).count; i++){
            [array addObject:[self itemAtIndex:i inArray:items withContext:context]];
        }
    }
    return array;
}

@end
