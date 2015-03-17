//
//  MZPrivateMainPlaybackQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/10/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZPrivateMainPlaybackQueue.h"

@interface MZPrivateMainPlaybackQueue ()
{
    PlaybackContext *playbackContext;
    NSUInteger fetchRequestIndex;  //keeping track where we left off within a fetchrequest
    Song *mostRecentSong;
    BOOL atEndOfQueue;
}
@end
@implementation MZPrivateMainPlaybackQueue

short const INTERNAL_FETCH_BATCH_SIZE = 3;
short const EXTERNAL_FETCH_BATCH_SIZE = 50;

- (instancetype)init
{
    if([super init]){
        playbackContext = nil;
        fetchRequestIndex = 0;
        atEndOfQueue = NO;
    }
    return self;
}

- (NSUInteger)numSongsInEntireMainQueue
{
    return [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                nowPlayingInclusive:YES
                                                 onlyUnplayedTracks:NO].count;
}

- (NSUInteger)numMoreSongsInMainQueue
{
    
    return [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                nowPlayingInclusive:YES
                                                 onlyUnplayedTracks:YES].count;
}

- (void)setMainQueueWithNewNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext
{
    playbackContext = aContext;
    atEndOfQueue = NO;
    NSArray *songs = [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                          nowPlayingInclusive:YES
                                                           onlyUnplayedTracks:NO];
    if(songs > 0){
        NSUInteger index = [songs indexOfObject:aSong];
        if(index != NSNotFound){
            mostRecentSong = songs[index];
            fetchRequestIndex = index;
            if(songs.count > 1)
                atEndOfQueue = NO;
            else
                atEndOfQueue = YES;
            return;
        }
    }
    aContext = nil;
    mostRecentSong = nil;
    fetchRequestIndex = 0;
}

- (NSArray *)tableViewOptimizedArrayOfMainQueueSongsComingUp
{
    return [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:EXTERNAL_FETCH_BATCH_SIZE
                                                nowPlayingInclusive:YES
                                                 onlyUnplayedTracks:YES];
}

- (void)clearMainQueue
{
    playbackContext = nil;
    mostRecentSong = nil;
    fetchRequestIndex = 0;
    atEndOfQueue = NO;
}

- (PreliminaryNowPlaying *)skipToPrevious
{
    //set atEndOfQueue to NO if an actual song is returned.
#warning broken for now.
    return nil;
}

- (PreliminaryNowPlaying *)skipForward
{
    if(playbackContext == nil)
        return nil;
    else{
        NSArray *songs = [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                              nowPlayingInclusive:YES
                                                               onlyUnplayedTracks:NO];
        if(songs.count > 0){
            NSUInteger index = [songs indexOfObject:mostRecentSong];
            if(index != fetchRequestIndex)
                fetchRequestIndex = index;
            index = ++fetchRequestIndex;
            
            if(fetchRequestIndex > songs.count-1){
                atEndOfQueue = YES;
                //no more songs, reached the last one
                return nil;
            } else{
                //simply grabbing the next song
                mostRecentSong = [songs objectAtIndex:index];
                PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
                newNowPlaying.aNewSong = mostRecentSong;
                newNowPlaying.aNewContext = playbackContext;
                return newNowPlaying;
            }
        } else{
            return nil;
        }
    }
}


//--------------private helpers--------------

//for getting an array of all up next songs, without putting all songs into memory.
- (NSArray *)minimallyFaultedArrayOfMainQueueSongsWithBatchSize:(int)batchSize
                                            nowPlayingInclusive:(BOOL)inclusive
                                             onlyUnplayedTracks:(BOOL)unplayed
{
    NSMutableArray *compiledSongs = [NSMutableArray array];
    NSFetchRequest *request = playbackContext.request;
    if(request == nil)
        return compiledSongs;
    [request setFetchBatchSize:batchSize];
    NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:nil];
    NSUInteger nowPlayingIndex = [array indexOfObject:[NowPlayingSong sharedInstance].nowPlaying];
    NSArray *desiredSubArray = array;
    if(nowPlayingIndex != NSNotFound && unplayed){
        NSRange range;
        if(inclusive)
            range = NSMakeRange(nowPlayingIndex, array.count-1);
        else{
            if(nowPlayingIndex < array.count-1)
                //at least 1 more song in array
                range = NSMakeRange(nowPlayingIndex+1, array.count-1);
            else
                //last song reached, no songs to show...return empty array instead of allowing index out of bounds.
                return [NSArray array];
        }
        desiredSubArray = [array subarrayWithRange:NSMakeRange(nowPlayingIndex+1, (array.count-1) - nowPlayingIndex)];
    }
    if(atEndOfQueue)
        desiredSubArray = [NSArray array];
    [compiledSongs addObjectsFromArray:desiredSubArray];
    return compiledSongs;
}

@end