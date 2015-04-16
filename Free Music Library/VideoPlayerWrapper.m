//
//  VideoPlayerWrapper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "VideoPlayerWrapper.h"

@implementation VideoPlayerWrapper
static BOOL updatingPlayerViewDisabled = NO;

+ (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)forward oldSong:(Song *)oldSong
{
    BOOL allowSongDidFinishToExecute;
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player replaceCurrentItemWithPlayerItem:nil];  //stop any ongoing playback
    allowSongDidFinishToExecute = player.allowSongDidFinishToExecute;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [playerView removeLayerFromPlayer];
    
    if([MusicPlaybackController avplayerTimeObserver] != nil)
        [player removeTimeObserver:[MusicPlaybackController avplayerTimeObserver]];
    
    [MusicPlaybackController setRawAVPlayer:nil];
    player = nil;
    
    MyAVPlayer *newPlayer = [[MyAVPlayer  alloc] init];
    [newPlayer allowSongDidFinishNotificationToProceed:allowSongDidFinishToExecute];
    [MusicPlaybackController setRawAVPlayer:newPlayer];
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
    
    [playerView reattachLayerToPlayer];
    [newPlayer startPlaybackOfSong:aSong goingForward:forward oldSong:oldSong];
    [VideoPlayerWrapper setupAvPlayerViewAgain];
}

+ (void)beginPlaybackWithPlayerItem:(AVPlayerItem *)item
{
    BOOL allowSongDidFinishToExecute;
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    allowSongDidFinishToExecute = player.allowSongDidFinishToExecute;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [playerView removeLayerFromPlayer];
    
    if([MusicPlaybackController avplayerTimeObserver] != nil)
        [player removeTimeObserver:[MusicPlaybackController avplayerTimeObserver]];
    
    [MusicPlaybackController setRawAVPlayer:nil];
    player = nil;
    
    MyAVPlayer *newPlayer = [[MyAVPlayer  alloc] initWithPlayerItem:item];
    [newPlayer allowSongDidFinishNotificationToProceed:allowSongDidFinishToExecute];
    [MusicPlaybackController setRawAVPlayer:newPlayer];
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
    
    [playerView reattachLayerToPlayer];
    [VideoPlayerWrapper newPlayerItemAddedCleanup];
    [VideoPlayerWrapper setupAvPlayerViewAgain];
}

+ (void)newPlayerItemAddedCleanup
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    BOOL airplayActive = player.externalPlaybackActive;
    [[MusicPlaybackController obtainRawPlayerView] showAirPlayInUseMsg:airplayActive];
    
    NSOperationQueue *operationQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZNewTimeObserverCanBeAdded
                                                        object:nil];
    [operationQueue cancelAllOperations];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if([MusicPlaybackController playbackExplicitlyPaused])
            [MusicPlaybackController pausePlayback];
        else
            [MusicPlaybackController resumePlayback];
    });
}

+ (void)setupAvPlayerViewAgain
{
    if(updatingPlayerViewDisabled)
        return;
    /*
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    NSUInteger playerIndex = [[appWindow subviews] indexOfObject:playerView];
    [playerView removeFromSuperview];
    [appWindow addSubview:playerView];
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         if(playerIndex != NSNotFound)
                             [appWindow insertSubview:playerView atIndex:playerIndex];
                     }
                     completion:nil];
    [playerView setNeedsDisplay];
     */
}

+ (void)temporarilyDisableUpdatingPlayerView:(BOOL)disable
{
    updatingPlayerViewDisabled = disable;
}

@end
