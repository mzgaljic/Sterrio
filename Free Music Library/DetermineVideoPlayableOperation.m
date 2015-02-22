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
}
@end
@implementation DetermineVideoPlayableOperation

- (id)initWithSong:(Song *)theSong
{
    if([super init]){
        aSong = theSong;
    }
    return self;
}

- (void)main
{
    //do synchronous work
    NSNumber *duration = aSong.duration;
    BOOL allowedToPlayVideo = YES;
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    if([duration integerValue] >= MZLongestCellularPlayableDuration){
        //videos of this length may only be played on wifi. Are we on wifi?
        if(! [reachability isConnectedToWifi])
            allowedToPlayVideo = NO;
    }

    //connection problems should take presedence first
    if([reachability isConnectionCompletelyGone]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player dismissAllSpinners];
        [MusicPlaybackController playbackExplicitlyPaused];
        [MusicPlaybackController pausePlayback];
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

@end
