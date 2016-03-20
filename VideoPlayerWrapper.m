//
//  VideoPlayerWrapper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "VideoPlayerWrapper.h"

@implementation VideoPlayerWrapper

+ (void)startPlaybackOfSong:(Song *)aSong
               goingForward:(BOOL)forward
            oldPlayableItem:(PlayableItem *)oldItem
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZInitAudioSession
                                                        object:nil];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player replaceCurrentItemWithPlayerItem:nil];  //stop any ongoing playback
    [player startPlaybackOfSong:aSong
                      goingForward:forward
                   oldPlayableItem:oldItem];
}

+ (void)beginPlaybackWithPlayerItem:(AVPlayerItem *)item
{
    NSOperationQueue *operationQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
    [operationQueue cancelAllOperations];
    
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player replaceCurrentItemWithPlayerItem:item];
    [MusicPlaybackController resumePlayback];
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    if(! [SongPlayerCoordinator isVideoPlayerExpanded])
        [playerView touchesCancelled:nil withEvent:nil];
    
    BOOL airplayActive = player.externalPlaybackActive;
    [[MusicPlaybackController obtainRawPlayerView] showAirPlayInUseMsg:airplayActive];
}


@end
