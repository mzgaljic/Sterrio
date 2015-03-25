//
//  VideoPlayerWrapper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "VideoPlayerWrapper.h"

@implementation VideoPlayerWrapper

+ (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)forward oldSong:(Song *)oldSong
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
    
    MyAVPlayer *newPlayer = [[MyAVPlayer  alloc] init];
    [newPlayer allowSongDidFinishNotificationToProceed:allowSongDidFinishToExecute];
    [MusicPlaybackController setRawAVPlayer:newPlayer];
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
    
    [playerView reattachLayerToPlayer];
    [newPlayer beginPlaybackWithPlayerItem:item];
    [VideoPlayerWrapper setupAvPlayerViewAgain];
}

+ (void)setupAvPlayerViewAgain
{
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    NSUInteger playerIndex = [[appWindow subviews] indexOfObject:playerView];
    [playerView removeFromSuperview];
    [appWindow addSubview:playerView];
    [appWindow insertSubview:playerView atIndex:playerIndex];
    [playerView setNeedsDisplay];
}

@end
