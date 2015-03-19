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
    MZPrivateMainPlaybackQueue *mainQueue;
    MZPrivateUpNextPlaybackQueue *upNextQueue;
}
@end
@implementation MZPlaybackQueue

//used by private playback queue classes.
short const INTERNAL_FETCH_BATCH_SIZE = 1;
short const EXTERNAL_FETCH_BATCH_SIZE = 50;


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
    if(self = [super init]){
        upNextQueue = [[MZPrivateUpNextPlaybackQueue alloc] init];
        mainQueue = [[MZPrivateMainPlaybackQueue alloc] init];
    }
    return self;
}

#pragma mark - Get info about queue
- (NSUInteger)numSongsInEntireMainQueue
{
    return [mainQueue numSongsInEntireMainQueue];
}

- (NSUInteger)numMoreSongsInMainQueue
{
    return [mainQueue numMoreSongsInMainQueue];
}

- (NSUInteger)numMoreSongsInUpNext
{
    return [upNextQueue numMoreUpNextSongsCount];
}

#pragma mark - Info for displaying Queue contexts visually
- (NSArray *)tableViewOptimizedArrayOfUpNextSongs
{
    return [upNextQueue tableViewOptimizedArrayOfUpNextSongs];
}
- (NSArray *)tableViewOptimizedArrayOfUpNextSongContexts
{
    return [upNextQueue tableViewOptimizedArrayOfUpNextSongContexts];
}
- (NSArray *)tableViewOptimizedArrayOfMainQueueSongsComingUp
{
    return [mainQueue tableViewOptimizedArrayOfMainQueueSongsComingUp];
}
- (PlaybackContext *)mainQueuePlaybackContext
{
    return [mainQueue mainQueuePlaybackContext];
}


#pragma mark - Performing operations on queue
- (void)clearEntireQueue
{
    [upNextQueue clearUpNext];
    [mainQueue clearMainQueue];
    [self printQueueContents];
}
- (void)clearUpNext
{
    [upNextQueue clearUpNext];
    [self printQueueContents];
}

//should be used when a user moves into a different context and wants to destroy their
//current queue. This does not clear the "up next" section.
- (void)setMainQueueWithNewNowPlayingSong:(Song *)aSong inContext:(PlaybackContext *)aContext
{
    [mainQueue setMainQueueWithNewNowPlayingSong:aSong inContext:aContext];
    [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:NO];
    [[NowPlayingSong sharedInstance] setNewNowPlayingSong:aSong context:aContext];
    [self printQueueContents];
}

- (void)addSongsToPlayingNextWithContexts:(NSArray *)contexts
{
    if(! [SongPlayerCoordinator isPlayerOnScreen]){
        //no songs currently playing, set defaults...
        [upNextQueue addSongsToUpNextWithContexts:contexts];
        PreliminaryNowPlaying *newSong = [upNextQueue obtainAndRemoveNextSong];
        
        [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:YES];
        [[NowPlayingSong sharedInstance] setNewNowPlayingSong:newSong.aNewSong
                                                      context:newSong.aNewContext];
        //start playback in minimzed state
        [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
        [VideoPlayerWrapper startPlaybackOfSong:newSong.aNewSong
                                   goingForward:YES
                                        oldSong:nil];
        [self printQueueContents];
        return;
    } else{
        //songs were already played, player on screen. is playback of queue finished?
        if([mainQueue numMoreSongsInMainQueue] == 0
           && [upNextQueue numMoreUpNextSongsCount] == 0){
            //no more songs in queue! is the current song completely finished playing?
            //if so, we can start playback of the new up next songs right now!
            
            MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
            Song *nowPlayingSong = [NowPlayingSong sharedInstance].nowPlaying;
            NSUInteger elapsedSeconds = ceil(CMTimeGetSeconds(player.currentItem.currentTime));
            
            //comparing if song is either done or VERY VERY VERY close to the end.
            if(elapsedSeconds == [nowPlayingSong.duration integerValue]
               || elapsedSeconds +1 == [nowPlayingSong.duration integerValue]){
                //we can start playing the new queue
                [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
                [upNextQueue addSongsToUpNextWithContexts:contexts];
                PreliminaryNowPlaying *newSong = [upNextQueue obtainAndRemoveNextSong];
                [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:YES];
                [[NowPlayingSong sharedInstance] setNewNowPlayingSong:newSong.aNewSong
                                                              context:newSong.aNewContext];
                [VideoPlayerWrapper startPlaybackOfSong:newSong.aNewSong
                                           goingForward:YES
                                                oldSong:nowPlayingSong];
                [self printQueueContents];
                return;
            }
        }
        //dont mess with the current song...queue not finished. Just insert new songs.
        [upNextQueue addSongsToUpNextWithContexts:contexts];
        [self printQueueContents];
    }
}

- (Song *)skipToPrevious
{
    PreliminaryNowPlaying *newNowPlaying = [mainQueue skipToPrevious];
    
    //user cant go backwards
    if(newNowPlaying.aNewSong == nil){
        //see if there is a up next queued song
        
        newNowPlaying = [upNextQueue obtainAndRemoveNextSong];
        BOOL upNextQueueNotEmptyYet = (newNowPlaying.aNewSong != nil);
        if(upNextQueueNotEmptyYet){
            [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:YES];
        } else{
            //just update this var. Dont skip forward, let user be in control of that.
            [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:NO];
        }
    } else
        [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:NO];
    
    [self printQueueContents];
    [[NowPlayingSong sharedInstance] setNewNowPlayingSong:newNowPlaying.aNewSong
                                                  context:newNowPlaying.aNewContext];
    return newNowPlaying.aNewSong;
}
- (Song *)skipForward
{
    PreliminaryNowPlaying *newNowPlaying = [upNextQueue obtainAndRemoveNextSong];
    BOOL upNextQueueNotEmptyYet = (newNowPlaying.aNewSong != nil);
    if(upNextQueueNotEmptyYet){
        [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:YES];
    } else{
        newNowPlaying = [mainQueue skipForward];
        [[NowPlayingSong sharedInstance] setPlayingBackFromPlayNextSongs:NO];
    }
    
    [[NowPlayingSong sharedInstance] setNewNowPlayingSong:newNowPlaying.aNewSong
                                                  context:newNowPlaying.aNewContext];
    [self printQueueContents];
    return newNowPlaying.aNewSong;
}

#pragma mark - DEBUG
//crashes when queuing up an entire playlist for some reason, dont use it that way!
- (void)printQueueContents
{
    
    NSArray *upNextSongs = [upNextQueue tableViewOptimizedArrayOfUpNextSongs];
    NSArray *mainQueueSongs = [mainQueue tableViewOptimizedArrayOfMainQueueSongsComingUp];
    
    NSMutableString *output = [NSMutableString stringWithString:@"\n\nNow Playing: ["];
    [output appendFormat:@"%@", [[NowPlayingSong sharedInstance] nowPlaying].songName];
    [output appendString:@"]\n"];
    
    [output appendString:@"---Queued songs coming up---\n"];
    //concatenate all Queued upNextSongs
    Song *aSong = nil;
    for(int i = 0; i < upNextSongs.count; i++){
        aSong = upNextSongs[i];
        if(i == 0)
            [output appendFormat:@"%@", aSong.songName];
        else
            [output appendFormat:@",%@", aSong.songName];
    }
    
    [output appendString:@"\n---Main queue songs coming up---\n"];
    //concatenate all main queue songs coming up (not yet played)
    for(int i = 0; i < mainQueueSongs.count; i++){
        aSong = mainQueueSongs[i];
        if(i == 0)
            [output appendFormat:@"%@", aSong.songName];
        else
            [output appendFormat:@", %@", aSong.songName];
    }
    [output appendString:@"\n\n"];
    printf("%s", [output UTF8String]); //print entire queue contents
     
}

@end