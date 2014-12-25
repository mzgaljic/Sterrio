//
//  PlaybackQueue.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaybackQueue.h"

@interface PlaybackQueue ()
{
    Deque *deque;
    NSUInteger nowPlayingIndex;
}
@end
@implementation PlaybackQueue

- (id)init
{
    if(self = [super init])
    {
        deque = [[Deque alloc] init];
        nowPlayingIndex = 0;
    }
    return self;
}

- (void)clearQueue
{
    [deque clear];
}

- (NSUInteger)numMoreSongsInQueue
{
    id object = [deque objectAtIndex:nowPlayingIndex];
    NSInteger value = [deque numObjectsAfterThisOne:object];
    if(value < 0)
        return 0;  //should never happen. indicates a problem with the entire queue
    else
        return value;
}

- (Song *)nowPlaying
{
    if(deque.count > 0){
        return [deque objectAtIndex:nowPlayingIndex];
    }
    
    else
        return nil;
}
- (void)setNowPlayingIndexWithSong:(Song *)song
{
    if(deque.count > 0){
        NSUInteger index = [deque indexOfObject:song];
        nowPlayingIndex = index;
    }
}
- (NSInteger)obtainNowPlayingIndex
{
    if(deque.count > 0){
        return nowPlayingIndex;
    }
    return nowPlayingIndex;
}
- (Song *)peekAtNextSong
{
    if(deque.count > 0 && (deque.count-1) != nowPlayingIndex)  //check for out of bounds
        return [deque objectAtIndex:(nowPlayingIndex + 1)];
    else
        return nil;
}
- (Song *)peekAtPreviousSong
{
    if(deque.count > 0 && nowPlayingIndex != 0)
        return [deque objectAtIndex:(nowPlayingIndex - 1)];
    else
        return nil;
}

- (Song *)skipForward
{
    //not pointing to last index of queue yet (or out of bounds), safe to move pointer forward
    if(deque.count > 0 && nowPlayingIndex < (deque.count -1)){
        nowPlayingIndex++;
        return [deque objectAtIndex:nowPlayingIndex];
    }
    return nil;
}
- (Song *)skipToPrevious;
{
    //not pointing to first index of queue yet (or out of bounds), safe to move pointer back
    if(deque.count > 0 && nowPlayingIndex != 0){
        nowPlayingIndex--;
        return [deque objectAtIndex:nowPlayingIndex];
    }
    return nil;
}

- (NSArray *)listOfUpcomingSongsNowPlayingExclusive
{
    short nowPlayingSongIndex = 0;
    NSMutableArray *temp = [NSMutableArray arrayWithArray:[self listOfUpcomingSongsNowPlayingInclusive]];
    [temp removeObjectAtIndex:nowPlayingSongIndex];
    return temp;
}
- (NSArray *)listOfUpcomingSongsNowPlayingInclusive
{
    if(deque.count > 0 && nowPlayingIndex != 0)  //nowPlayingIndex == 0 is an edge case for the range...
        return [[deque allQueueObjectsAsArray] subarrayWithRange:NSMakeRange(nowPlayingIndex, deque.count - nowPlayingIndex)];
    else if(deque.count > 0 && nowPlayingIndex == 0)
        return [[deque allQueueObjectsAsArray] subarrayWithRange:NSMakeRange(0, deque.count)];
    else
        return nil;
}
- (NSArray *)listOfPlayedSongsNowPlayingExclusive
{
    if(deque.count > 0)
        return [[deque allQueueObjectsAsArray] subarrayWithRange:NSMakeRange(0, nowPlayingIndex)];
    else
        return nil;
}
- (NSArray *)listOfPlayedSongsNowPlayingInclusive
{
    if(deque.count > 0)
        return [[deque allQueueObjectsAsArray] subarrayWithRange:NSMakeRange(0, (nowPlayingIndex + 1))];
    else
        return nil;
}
- (NSArray *)listOfEntireQueueAsArray
{
    return [deque allQueueObjectsAsArray];
}

- (void)insertSongsAfterNowPlaying:(NSArray *)songs
{
    //queue non-empty, and now playing song isnt the last song
    if(deque.count > 0 && nowPlayingIndex != (deque.count-1)){
        NSUInteger insertIndex = nowPlayingIndex + 1;
        for(Song *aSong in songs){
            [deque insertItem:aSong atIndex:insertIndex];
            insertIndex++;
        }
    } else{  //now playing song IS the last song in the queue, or queue is empty
        //we can simply enqueue items at the tail (like we would normally do with a queue).
        for(Song *aSong in songs){
            [deque enqueue:aSong];
        }
    }
}

@end
