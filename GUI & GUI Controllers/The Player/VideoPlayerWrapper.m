//
//  VideoPlayerWrapper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "VideoPlayerWrapper.h"
#import "PreviousNowPlayingInfo.h"
#import "PlayableItem.h"

@implementation VideoPlayerWrapper

+ (void)startPlaybackOfItem:(PlayableItem *)newItem
               goingForward:(BOOL)forward
            oldPlayableItem:(PlayableItem *)oldItem
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZInitAudioSession
                                                        object:nil];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player replaceCurrentItemWithPlayerItem:nil];  //stop any ongoing playback
    
    [PreviousNowPlayingInfo setPreviousPlayableItem:oldItem];
    [[NowPlaying sharedInstance] setNewPlayableItem:newItem];
    [player startPlaybackOfSong:newItem.songForItem
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
    //this setter sets the appropriate fields on the AVPlayer variable.
    [AppEnvironmentConstants setShouldOnlyAirplayAudio:[AppEnvironmentConstants shouldOnlyAirplayAudio]];
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    if(! [SongPlayerCoordinator isVideoPlayerExpanded]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        //custom logic in PlayerView.m doesn't ever look at the arguments here...so passing nil is fine.
        [playerView touchesCancelled:nil withEvent:nil];
        #pragma clang diagnostic pop
    }
    
    BOOL airplayActive = player.externalPlaybackActive;
    [[MusicPlaybackController obtainRawPlayerView] showAirPlayInUseMsg:airplayActive];
}


@end
