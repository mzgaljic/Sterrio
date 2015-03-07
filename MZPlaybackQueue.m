//
//  MZPlaybackQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZPlaybackQueue.h"

@interface MZPlaybackQueue ()
{
    Song *nextSong;
    Song *nextSongScheduledForPlaybackInFirstSubQueue;
    NSMutableArray *playNextSongs;  //contains the actual song objects
    NSMutableArray *subQueueFetchRequests;  //we use the saved nsfetchrequest to obtain the songs in that list.
}
@end
@implementation MZPlaybackQueue

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if([super init]){
        playNextSongs = [NSMutableArray array];
        subQueueFetchRequests = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Get info about queue
- (NowPlayingSong *)nowPlaying
{
    return [NowPlayingSong sharedInstance];
}

- (Song *)nextSong
{
    return nextSong;
}

- (NSUInteger)numMoreSongsInQueue
{
#warning this is broken! it should return number of songs LEFT in the queue, not the total queue song count!!!
    //count up # songs in playNextSongs array (exclude nowplaying item if the current song is in this array)
    //+ count up # songs to go in each subqeueue...tally it all up and return the integer.
    
    int playNextSongCount = (int)playNextSongs.count;
    NSUInteger numMoreSongsInQueue = playNextSongCount;
    
    NSFetchRequest *aRequest;
    NSUInteger count;
    for(int i = 0; i < subQueueFetchRequests.count; i++){
        aRequest = subQueueFetchRequests[i];
        count = [[CoreDataManager context] countForFetchRequest:aRequest error:nil];
        if(count != NSNotFound)
            numMoreSongsInQueue += count;
    }
    return numMoreSongsInQueue;
}

- (Song *)nextSongScheduledForPlaybackInFirstSubQueue
{
    return nextSongScheduledForPlaybackInFirstSubQueue;
}

- (NSArray *)playNextSongs
{
    return playNextSongs;
}

- (NSArray *)arrayOfFetchRequestsMappingToSubsetQueues
{
    NSMutableArray *requestedArray = [NSMutableArray array];
    NSFetchRequest *aRequest;
    for(int i = 0; i < subQueueFetchRequests.count; i++){
        aRequest = subQueueFetchRequests[i];
        [requestedArray addObject:[aRequest copy]];
    }
    return requestedArray;
}


#pragma mark - Performing operations on queue
- (void)clearEntireQueue
{
    [playNextSongs removeAllObjects];
    [subQueueFetchRequests removeAllObjects];
}

- (void)clearPlayingNext
{
    [playNextSongs removeAllObjects];
}

- (void)clearSubQueueAtIndex:(NSUInteger)index
{
    [subQueueFetchRequests removeObjectAtIndex:index];
}

- (void)setNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext
{
    [subQueueFetchRequests removeAllObjects];
    [subQueueFetchRequests addObject:aContext.request];
    [[NowPlayingSong sharedInstance] setNewNowPlayingSong:aSong context:aContext];
    NSFetchRequest *request = aContext.request;
    NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:nil];
    if(array.count > 0){
        NSUInteger nowPlayingIndex = [array indexOfObject:aSong];
        
        if(nowPlayingIndex != NSNotFound && array.count > nowPlayingIndex+1){
            //more songs to be played from this source (after the now playing song)
            Song *nextSongInSource = [array objectAtIndex:nowPlayingIndex+1];
            nextSongScheduledForPlaybackInFirstSubQueue = nextSongInSource;
            nextSong = (playNextSongs.count > 0) ? playNextSongs[0] : nextSongScheduledForPlaybackInFirstSubQueue;
        }
        else
        {
            //jump to next subqueue
        }
    }
    array = nil;
}

- (void)addSongToPlayingNext:(Song *)aSong
{
    [playNextSongs insertObject:aSong atIndex:0];
    nextSong = aSong;
}

- (Song *)skipToPrevious
{
#warning incomplete
    return nil;
}

- (Song *)skipForward
{
    Song *newNowPlaying;
    
    if(playNextSongs.count > 0)
    {
        //see if the current song is from here
        Song *firstSongInPlayNext = playNextSongs[0];
        if([firstSongInPlayNext.song_id isEqualToString:[NowPlayingSong sharedInstance].nowPlaying.song_id]
           && [NowPlayingSong sharedInstance].context == nil)
        {
            [playNextSongs removeObjectAtIndex:0];
        }
        //play next song from "play next", if there are still any left
        if(playNextSongs.count > 0)
        {
            firstSongInPlayNext = playNextSongs[0];
            [[NowPlayingSong sharedInstance] setNewNowPlayingSong:firstSongInPlayNext context:nil];
            newNowPlaying = firstSongInPlayNext;
            if(playNextSongs.count > 1)
                nextSong = playNextSongs[1];
            else
            {
                if(subQueueFetchRequests.count > 0){
                    nextSong = nextSongScheduledForPlaybackInFirstSubQueue;
                }
            }
        }
        else
        {
            newNowPlaying = nextSongScheduledForPlaybackInFirstSubQueue;
            if(subQueueFetchRequests.count > 0)
            {
                NSFetchRequest *request = subQueueFetchRequests [0];
                PlaybackContext *context = [[PlaybackContext alloc] initWithFetchRequest:request];
                [[NowPlayingSong sharedInstance] setNewNowPlayingSong:newNowPlaying context:context];
                
                NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:nil];
                if(array.count > 0)
                {
                    NSUInteger indexOfNextSongInFirstSubQueue = [array indexOfObject:nextSongScheduledForPlaybackInFirstSubQueue];
                    if(indexOfNextSongInFirstSubQueue != NSNotFound && array.count > indexOfNextSongInFirstSubQueue+1)
                    {
                        nextSongScheduledForPlaybackInFirstSubQueue = [array objectAtIndex:indexOfNextSongInFirstSubQueue+1];
                        nextSong = nextSongScheduledForPlaybackInFirstSubQueue;
                    }
                    else
                    {
                        //jump to next subqueue.
                    }
                }
                array = nil;
            }
            else
            {
                nextSong = nil;
                nextSongScheduledForPlaybackInFirstSubQueue = nil;
                [[NowPlayingSong sharedInstance] setNewNowPlayingSong:nil context:nil];
            }
        }
    }
    else
    {
        newNowPlaying = nextSongScheduledForPlaybackInFirstSubQueue;
        if(subQueueFetchRequests.count > 0)
        {
            NSFetchRequest *request = subQueueFetchRequests [0];
            NSArray *array = [[CoreDataManager context] executeFetchRequest:request error:nil];
            
            PlaybackContext *context = [[PlaybackContext alloc] initWithFetchRequest:request];
            [[NowPlayingSong sharedInstance] setNewNowPlayingSong:newNowPlaying context:context];
            
            if(array.count > 0)
            {
                NSUInteger indexOfNextSongInFirstSubQueue = [array indexOfObject:nextSongScheduledForPlaybackInFirstSubQueue];
                if(indexOfNextSongInFirstSubQueue != NSNotFound && array.count > indexOfNextSongInFirstSubQueue+1)
                {
                    nextSongScheduledForPlaybackInFirstSubQueue = [array objectAtIndex:indexOfNextSongInFirstSubQueue+1];
                    nextSong = nextSongScheduledForPlaybackInFirstSubQueue;
                }
                else
                {
                    //jump to next subqueue.
                    //set nextSong, etc...
                }
            }
            else
            {
                //since there is only 1 subqueue for now...
                nextSongScheduledForPlaybackInFirstSubQueue = nil;
                nextSong = nil;
                [[NowPlayingSong sharedInstance] setNewNowPlayingSong:nil context:nil];
            }
            array = nil;
        }
        else
        {
            nextSong = nil;
            nextSongScheduledForPlaybackInFirstSubQueue = nil;
            [[NowPlayingSong sharedInstance] setNewNowPlayingSong:nil context:nil];
        }
    }
    return newNowPlaying;
}

@end
