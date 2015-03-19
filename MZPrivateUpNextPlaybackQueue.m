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
        playbackContexts = [NSMutableArray arrayWithCapacity:1];
        fetchRequestIndexes = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

- (void)addSongsToUpNextWithContexts:(NSArray *)contexts
{
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, contexts.count)];
    [playbackContexts insertObjects:contexts atIndexes:indexes];
    NSNumber *index = [NSNumber numberWithInt:0];
    NSMutableArray *tempNSNumsArray = [NSMutableArray array];
    for(int i = 0; i < contexts.count; i++){
        [tempNSNumsArray addObject:index];
    }
    [fetchRequestIndexes addObjectsFromArray:tempNSNumsArray];
}

- (NSUInteger)numMoreUpNextSongsCount
{
    NSArray *array = [self minimallyFaultedArrayOfUpNextSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE];
    if(array.count > 0){
        if([[NowPlayingSong sharedInstance] isEqualToSong:array[0] compareWithContext:playbackContexts[0]])
            //array contains now playing, dont include in count!
            return array.count -1;
        else
            return array.count;
    } else
        return 0;
}

- (NSArray *)tableViewOptimizedArrayOfUpNextSongs
{
    //dont need to insert a fake item in the front to represent now playing like we
    //needed to in the private main queue (implementation detail...)
    return [self minimallyFaultedArrayOfUpNextSongsWithBatchSize:EXTERNAL_FETCH_BATCH_SIZE];
}

- (NSArray *)tableViewOptimizedArrayOfUpNextSongContexts
{
    //dont need to insert a fake item in the front to represent now playing like we
    //needed to in the private main queue (implementation detail...)
    return [NSMutableArray arrayWithArray:playbackContexts];
}

- (PreliminaryNowPlaying *)obtainAndRemoveNextSong
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    int numContextsToDelete = 0;
    Song *desiredSong;
    PlaybackContext *desiredSongsContext;
    //iterate until we find a next song
    for(NSInteger i = 0; i < playbackContexts.count; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        [aRequest setFetchBatchSize:INTERNAL_FETCH_BATCH_SIZE];
        
        NSUInteger songIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        
        NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
        songIndex = [indexNumObj integerValue];
        desiredSong = [self songInArray:array atIndex:songIndex];
        desiredSongsContext = aContext;
        
        //advance songIndexCount
        songIndex++;
        
        //this context is empty, or we have just pulled the very last song from this context.
        if(desiredSong == nil || songIndex == playbackContexts.count-1)
        {
            numContextsToDelete++;
        }
        else
        {
            NSNumber *newIndexObj = [NSNumber numberWithInteger:songIndex];
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
    PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
    newNowPlaying.aNewSong = desiredSong;
    newNowPlaying.aNewContext = desiredSongsContext;
    return newNowPlaying;
}



//broken!!!! should iterate in the same direction as the "obtainAndRemove" method.
- (PreliminaryNowPlaying *)peekAtNextSong
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    Song *desiredSong;
    PlaybackContext *desiredSongsContext;
    //iterate until we find a next song
    for(int i = 0; i < playbackContexts.count; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        [aRequest setFetchBatchSize:INTERNAL_FETCH_BATCH_SIZE];
        
        NSUInteger songIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        
        NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
        songIndex = [indexNumObj integerValue];
        desiredSong = [self songInArray:array atIndex:songIndex];
        desiredSongsContext = aContext;
    }
    PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
    newNowPlaying.aNewSong = desiredSong;
    newNowPlaying.aNewContext = desiredSongsContext;
    return newNowPlaying;
}

- (void)clearUpNext
{
    [playbackContexts removeAllObjects];
    [fetchRequestIndexes removeAllObjects];
}



//--------------private helpers--------------

//for getting an array of all up next songs, without putting all songs into memory.
- (NSMutableArray *)minimallyFaultedArrayOfUpNextSongsWithBatchSize:(int)batchSize
{
    PlaybackContext *aContext;
    NSFetchRequest *aRequest;
    NSMutableArray *compiledSongs = [NSMutableArray array];
    
    //iterate until we compile all songs coming up
    for(int i = 0; i < playbackContexts.count; i++)
    {
        aContext = playbackContexts[i];
        aRequest = aContext.request;
        [aRequest setFetchBatchSize:batchSize];
        
        NSUInteger songIndex = 0;
        NSArray *array = [[CoreDataManager context] executeFetchRequest:aRequest error:nil];
        BOOL isContextRepresentingASingleSong = (array.count == 1);
        if(isContextRepresentingASingleSong)
        {
            Song *aSong = [self songInArray:array atIndex:0];
            if(aSong)
                [compiledSongs addObject:aSong];
        }
        else
        {
            NSNumber *indexNumObj = [fetchRequestIndexes objectAtIndex:i];
            songIndex = [indexNumObj integerValue];
            NSArray *songsToAdd = [self songsInArray:array fromThisIndexOnward:songIndex];
            [compiledSongs addObjectsFromArray:songsToAdd];
        }
    }
    
    return compiledSongs;
}

- (Song *)songInArray:(NSArray *)arrayOfSongs atIndex:(NSUInteger)index
{
    if(arrayOfSongs.count -1 >= index)
    {
        return [arrayOfSongs objectAtIndex:index];
    }
    else
        return nil;
}

//guranteed to return at least a 0 sized array (as opposed to nil)
- (NSArray *)songsInArray:(NSArray *)songs fromThisIndexOnward:(NSUInteger)index
{
    NSMutableArray *array = [NSMutableArray array];
    if(songs.count -1 >= index){
        for(int i = (int)index; i  < songs.count; i++){
            [array addObject:songs[i]];
        }
    }
    return array;
}

@end
