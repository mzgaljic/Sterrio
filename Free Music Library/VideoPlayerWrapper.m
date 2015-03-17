//
//  VideoPlayerWrapper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "VideoPlayerWrapper.h"

@implementation VideoPlayerWrapper

+ (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)yes oldSong:(Song *)oldSong
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [playerView removeLayerFromPlayer];
    if([MusicPlaybackController avplayerTimeObserver] != nil)
        [player removeTimeObserver:[MusicPlaybackController avplayerTimeObserver]];
    [MusicPlaybackController setRawAVPlayer:nil];
    player = nil;
    MyAVPlayer *newPlayer = [[MyAVPlayer  alloc] init];
    [MusicPlaybackController setRawAVPlayer:newPlayer];
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
    [playerView reattachLayerToPlayer];
    [newPlayer startPlaybackOfSong:aSong goingForward:YES oldSong:oldSong];
    [VideoPlayerWrapper setupAvPlayerViewAgain];
}

+ (void)beginPlaybackWithPlayerItem:(AVPlayerItem *)item
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [playerView removeLayerFromPlayer];
    if([MusicPlaybackController avplayerTimeObserver] != nil)
        [player removeTimeObserver:[MusicPlaybackController avplayerTimeObserver]];
    [MusicPlaybackController setRawAVPlayer:nil];
    player = nil;
    MyAVPlayer *newPlayer = [[MyAVPlayer  alloc] init];
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
    [playerView removeFromSuperview];
    [appWindow addSubview:playerView];
    [playerView setNeedsDisplay];
}

@end
