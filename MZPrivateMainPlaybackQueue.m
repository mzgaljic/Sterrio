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
    BOOL userWentBeyondStartOfQueue;
    BOOL userWentBeyondEndOfQueue;
}
@end
@implementation MZPrivateMainPlaybackQueue

- (instancetype)init
{
    if([super init]){
        playbackContext = nil;
        fetchRequestIndex = 0;
        atEndOfQueue = NO;
        userWentBeyondStartOfQueue = NO;
        userWentBeyondEndOfQueue = NO;
    }
    return self;
}

- (NSUInteger)numSongsInEntireMainQueue
{
    //no fault at all here  :)
    if(playbackContext.request != nil){
        return [[CoreDataManager context] countForFetchRequest:playbackContext.request error:nil];
    } else{
        return 0;
    }
}

- (NSUInteger)numMoreSongsInMainQueue
{
    
    return [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                nowPlayingInclusive:YES
                                                 onlyUnplayedTracks:YES].count;
}

- (void)setMainQueueWithNewNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext
{
    playbackContext = nil;
    playbackContext = aContext;
    atEndOfQueue = NO;
    userWentBeyondStartOfQueue = NO;
    userWentBeyondEndOfQueue = NO;
    
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
    mostRecentSong = nil;
    fetchRequestIndex = 0;
}

- (NSArray *)tableViewOptimizedArrayOfMainQueueSongsComingUp
{
    return [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:EXTERNAL_FETCH_BATCH_SIZE
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
    mostRecentSong = nil;
    fetchRequestIndex = 0;
    atEndOfQueue = NO;
    userWentBeyondStartOfQueue = NO;
    userWentBeyondEndOfQueue = NO;
}

- (PreliminaryNowPlaying *)skipToPrevious
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
            
            if(fetchRequestIndex == 0){
                //value is 0 before decrementing
                if(songs.count == 1)
                    atEndOfQueue = YES;
                if(userWentBeyondEndOfQueue){
                    //dont actually decrement the index, just return the last song since the
                    //user previously skipped "past" the last index in the array.
                    userWentBeyondEndOfQueue = NO;
                    mostRecentSong = [songs objectAtIndex:index];
                    PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
                    newNowPlaying.aNewSong = mostRecentSong;
                    newNowPlaying.aNewContext = playbackContext;
                    return newNowPlaying;
                }else
                    userWentBeyondStartOfQueue = YES;
                return nil;  //no songs before index 0.
            }
            if(userWentBeyondEndOfQueue){
                //dont actually decrement the index, just return the last song since the
                //user previously skipped "past" the last index in the array.
                userWentBeyondEndOfQueue = NO;
                mostRecentSong = [songs objectAtIndex:index];
                PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
                newNowPlaying.aNewSong = mostRecentSong;
                newNowPlaying.aNewContext = playbackContext;
                return newNowPlaying;
            }
            
            
            //fetchRequestIndex is unsigned, will only be decremented here if the previous value
            //was greater than 0 (avoiding accidentally setting it to a negative value).
            index = --fetchRequestIndex;
            
            if(fetchRequestIndex == songs.count-1 || fetchRequestIndex > songs.count-1){
                atEndOfQueue = YES;
            } else
                atEndOfQueue = NO;
            
            //simply grabbing the next song
            mostRecentSong = [songs objectAtIndex:index];
            PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
            newNowPlaying.aNewSong = mostRecentSong;
            newNowPlaying.aNewContext = playbackContext;
            return newNowPlaying;
        } else{
            return nil;
        }
    }
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
            if(userWentBeyondStartOfQueue){
                //user is just going to play song at index 0 now, since they previously went
                //"behind" the bounds of index 0.
                userWentBeyondStartOfQueue = NO;
                mostRecentSong = [songs objectAtIndex:index];
                PreliminaryNowPlaying *newNowPlaying = [[PreliminaryNowPlaying alloc] init];
                newNowPlaying.aNewSong = mostRecentSong;
                newNowPlaying.aNewContext = playbackContext;
                return newNowPlaying;
            } else if(userWentBeyondEndOfQueue)
                return nil;
            else if(fetchRequestIndex == songs.count-1){
                //dont let user beyond end of array.
                userWentBeyondEndOfQueue = YES;
                return nil;
            }
            
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

- (Song *)skipToBeginningOfQueue
{
    //fetchRequestIndex
    if(playbackContext == nil)
        return nil;
    else{
        NSArray *songs = [self minimallyFaultedArrayOfMainQueueSongsWithBatchSize:INTERNAL_FETCH_BATCH_SIZE
                                                              nowPlayingInclusive:YES
                                                               onlyUnplayedTracks:NO];
        if(songs.count > 0){
            Song *firstSongInMainQueue = [songs objectAtIndex:0];
            fetchRequestIndex = 0;
            mostRecentSong = firstSongInMainQueue;
            if(songs.count == 1)
                atEndOfQueue = YES;
            else
                atEndOfQueue = NO;
            userWentBeyondStartOfQueue = NO;
            userWentBeyondEndOfQueue = NO;
            return firstSongInMainQueue;
        }
        else{
            return nil;
        }
    }
}


//--------------private helpers--------------

//for getting an array of all up next songs, without putting all songs into memory.
- (NSMutableArray *)minimallyFaultedArrayOfMainQueueSongsWithBatchSize:(int)batchSize
                                            nowPlayingInclusive:(BOOL)inclusive
                                             onlyUnplayedTracks:(BOOL)unplayed
{
    NSMutableArray *compiledSongs = [NSMutableArray array];
    NSFetchRequest *request = playbackContext.request;
    if(request == nil)
        return compiledSongs;
    [request setFetchBatchSize:INTERNAL_FETCH_BATCH_SIZE];
    NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:nil];
    NSUInteger nowPlayingIndex;
    if([NowPlayingSong sharedInstance].isFromPlayNextSongs)
        nowPlayingIndex = [array indexOfObject:mostRecentSong];
    else
        nowPlayingIndex = [array indexOfObject:[NowPlayingSong sharedInstance].nowPlaying];
    NSArray *desiredSubArray;
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
                return [NSMutableArray array];
        }
        desiredSubArray = [array subarrayWithRange:NSMakeRange(nowPlayingIndex+1, (array.count-1) - nowPlayingIndex)];
    }
    if((atEndOfQueue && !unplayed) || (desiredSubArray == nil && !unplayed))
        desiredSubArray = array;
    
    [compiledSongs addObjectsFromArray:desiredSubArray];
    return compiledSongs;
}

@end