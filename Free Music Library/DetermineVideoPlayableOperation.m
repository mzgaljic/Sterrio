//
//  DetermineVideoPlayableOperation.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "DetermineVideoPlayableOperation.h"

@interface DetermineVideoPlayableOperation ()
{
    Song *aSong;
    BOOL allowedToPlayVideo;
}
@end
@implementation DetermineVideoPlayableOperation

- (id)initWithSong:(Song *)theSong
{
    if(self = [super init]){
        aSong = theSong;
    }
    return self;
}

- (void)main
{
    //do synchronous work
    NSNumber *duration = aSong.duration;
    allowedToPlayVideo = YES;
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    if([duration integerValue] >= MZLongestCellularPlayableDuration){
        //videos of this length may only be played on wifi. Are we on wifi?
        if(! [reachability isConnectedToWifi])
            allowedToPlayVideo = NO;
    }
    if ([self isCancelled]){
        return;
    }

    //connection problems should take presedence first over the allowedToPlay code further down...
    if([reachability isConnectionCompletelyGone]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
        [player dismissAllSpinners];
#warning rework the error code here.
        //ideally i should just not show any alert like i do above. just have a banner
        //come up under the VC when the internet connection state changes. it will
        //be obvious to user.
        //bad code to kill the player here. if the user taps another song before the player
        //kill code completes, an EXEC_BAD_ACCESS occures.
        //[playerView userKilledPlayer];
        return;
    }
    if ([self isCancelled]){
        return;
    }
    
    if(! allowedToPlayVideo){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        //triggers the next song to play
        [player performSelectorOnMainThread:@selector(songNeedsToBeSkippedDueToIssue)
                               withObject:nil
                            waitUntilDone:NO];
        [self cancel];  //will allow dependant NSOperations to detect that they should also cancel.
        return;
    }
    
    NSLog(@"YAY! can play video!");
}

- (BOOL)allowedToPlayVideo
{
    return allowedToPlayVideo;
}

@end
