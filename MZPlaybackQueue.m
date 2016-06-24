//
//  MZPlaybackQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZPlaybackQueue.h"
#import "ProgressHUD.h"
#import "PlayableItem.h"
#import "PlaylistItem.h"
#import "PreviousNowPlayingInfo.h"

@interface MZPlaybackQueue ()
{
    MZPrivateMainPlaybackQueue *mainQueue;
    MZPrivateUpNextPlaybackQueue *upNextQueue;
}
@end
@implementation MZPlaybackQueue

//used by private playback queue classes.
short const INTERNAL_FETCH_BATCH_SIZE = 1;
short const EXTERNAL_FETCH_BATCH_SIZE = 100;


+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

+ (void)presentQueuedHUD
{
    [ProgressHUD showSuccess:@"Queued" Interaction:YES];
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
- (NSUInteger)numItemsInEntireMainQueue
{
    return [mainQueue numItemsInEntireMainQueue];
}

- (NSUInteger)numMoreItemsInMainQueue
{
    return [mainQueue numMoreItemsInMainQueue];
}

- (NSUInteger)numMoreItemsInUpNext
{
    return [upNextQueue numMoreUpNextItemsCount];
}

#pragma mark - Info for displaying Queue contexts visually
- (NSArray *)tableViewOptimizedArrayOfUpNextItems
{
    return [upNextQueue tableViewOptimizedArrayOfUpNextItems];
}
- (NSArray *)tableViewOptimizedArrayOfUpNextItemsContexts
{
    return [upNextQueue tableViewOptimizedArrayOfUpNextItemsContexts];
}
- (NSArray *)tableViewOptimizedArrayOfMainQueueItemsComingUp
{
    return [mainQueue tableViewOptimizedArrayOfMainQueuePlayableItemsComingUp];
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

- (void)skipOverThisManyQueueItemsEfficiently:(NSUInteger)totalItemsWeNeedToSkip
{
    NSUInteger numMoreItemsToSkip = totalItemsWeNeedToSkip;
    NSUInteger numMoreUpNextItems = [upNextQueue numMoreUpNextItemsCount];
    if(numMoreUpNextItems <= numMoreItemsToSkip){
        //even if we clear the entire upNext queue, we'll still have to skip items! so lets do it...
        [upNextQueue clearUpNext];
        numMoreItemsToSkip -= numMoreUpNextItems;
    }else{
        [upNextQueue efficientlySkipTheseManyItems:numMoreItemsToSkip];
        numMoreItemsToSkip = 0;
    }
    
    if(numMoreItemsToSkip > 0)
    {
        [mainQueue efficientlySkipTheseManyItems:numMoreItemsToSkip];
    }
}

//should be used when a user moves into a different context and wants to destroy their
//current queue. This does not clear the "up next" section.
- (void)setMainQueueWithNewNowPlayingItem:(PlayableItem *)item;
{
    PlayableItem *oldItem = [NowPlaying sharedInstance].playableItem;
    [mainQueue setMainQueueWithNewNowPlayingItem:item];
    [[NowPlaying sharedInstance] setNewPlayableItem:item];
    
    //start playback in minimzed state
    [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
    [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                               goingForward:YES
                            oldPlayableItem:oldItem];
    [self printQueueContents];
}

- (void)addItemsToPlayingNextWithContexts:(NSArray *)contexts
{
    PlayableItem *oldItem = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading];
    
    if(! [SongPlayerCoordinator isPlayerOnScreen]){
        //no songs currently playing, set defaults...
        [upNextQueue addItemsToUpNextWithContexts:contexts];
        PlayableItem *item = [upNextQueue obtainAndRemoveNextItem];
        
        [[NowPlaying sharedInstance] setNewPlayableItem:item];
        
        //start playback in minimzed state
        [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
        [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                                   goingForward:YES
                                oldPlayableItem:oldItem];
        [self printQueueContents];
        return;
    } else{
        //items were already played, player on screen. is playback of queue finished?
        if([mainQueue numMoreItemsInMainQueue] == 0
           && [upNextQueue numMoreUpNextItemsCount] == 0)
        {
            //no more items in queue! is the current item completely finished playing?
            //if so, we can start playback of the new up next items right now!
            
            MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
            Song *nowPlayingSong = [NowPlaying sharedInstance].playableItem.songForItem;
            NSUInteger elapsedSeconds = ceil(CMTimeGetSeconds(player.currentItem.currentTime));
            
            //comparing if song is either done or VERY VERY VERY close to the end.
            if(elapsedSeconds == [nowPlayingSong.duration integerValue]
               || elapsedSeconds +1 == [nowPlayingSong.duration integerValue]){
                //we can start playing the new queue
                [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
                [upNextQueue addItemsToUpNextWithContexts:contexts];
                PlayableItem *item = [upNextQueue obtainAndRemoveNextItem];
                [[NowPlaying sharedInstance] setNewPlayableItem:item];

                [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                                           goingForward:YES
                                        oldPlayableItem:oldItem];
                [self printQueueContents];
                return;
            }
        }
        //dont mess with the current item...queue not finished. Just insert new items.
        [upNextQueue addItemsToUpNextWithContexts:contexts];
        [self printQueueContents];
    }
}

- (PlayableItem *)skipToPrevious
{
    PlayableItem *item = [mainQueue skipToPrevious];
    
    //code commented out makes NO sense lmfao.
    /*
    //user cant go backwards
    if(item.songForItem == nil){
        //see if there is a up next queued item
        
        item = [upNextQueue obtainAndRemoveNextItem];
    }
     */
    
    [self printQueueContents];
    [[NowPlaying sharedInstance] setNewPlayableItem:item];
    
    return item;
}
- (PlayableItem *)skipForward
{
    PlayableItem *item = [upNextQueue obtainAndRemoveNextItem];
    
    BOOL upNextQueueIsEmpty = (item.songForItem == nil);
    if(upNextQueueIsEmpty){
        item = [mainQueue skipForward];
    }
    
    [[NowPlaying sharedInstance] setNewPlayableItem:item];
    
    [self printQueueContents];
    return item;
}

//jumps back to index 0 in the main queue. if shuffle is on, it reshuffles before jumping to index 0.
- (PlayableItem *)skipToBeginningOfQueueReshufflingIfNeeded
{
#warning Missing shuffle implementation.
    //dont take into account shuffle mode here
    
    PlayableItem *item = [mainQueue skipToBeginningOfQueue];
    [[NowPlaying sharedInstance] setNewPlayableItem:item];
    return item;
}

#pragma mark - DEBUG
//crashes when queuing up an entire playlist for some reason, dont use it that way!
- (void)printQueueContents
{
    NSArray *upNextSongs = [upNextQueue tableViewOptimizedArrayOfUpNextItems];
    NSArray *mainQueueSongs = [mainQueue tableViewOptimizedArrayOfMainQueuePlayableItemsComingUp];
    
    NSMutableString *output = [NSMutableString stringWithString:@"\n\nNow Playing: ["];
    [output appendFormat:@"%@", [NowPlaying sharedInstance].playableItem.songForItem.songName];
    [output appendString:@"]\n"];
    
    [output appendString:@"---Queued songs coming up---\n"];
    
    //concatenate all Queued upNextItems
    [upNextSongs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PlayableItem *item = [self dummyPlayableItemForObject:obj];
        if(idx == 0)
            [output appendFormat:@"%@", item.songForItem.songName];
        else
            [output appendFormat:@",%@", item.songForItem.songName];
    }];
    
    [output appendString:@"\n---Main queue songs coming up---\n"];
    
    //concatenate all main queue songs coming up (not yet played)
    [mainQueueSongs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PlayableItem *item = [self dummyPlayableItemForObject:obj];
        if(idx == 0)
            [output appendFormat:@"%@", item.songForItem.songName];
        else
            [output appendFormat:@", %@", item.songForItem.songName];
    }];
    
    [output appendString:@"\n\n"];
    printf("%s", [output UTF8String]); //print entire queue contents
}

- (PlayableItem *)dummyPlayableItemForObject:(id)object
{
    if([object isMemberOfClass:[Song class]]){
        return [[PlayableItem alloc] initWithSong:(Song *)object context:nil fromUpNextSongs:NO];
    }
    else if([object isMemberOfClass:[PlaylistItem class]])
        return [[PlayableItem alloc] initWithPlaylistItem:(PlaylistItem *)object context:nil fromUpNextSongs:NO];
    else
        return nil;

}

@end