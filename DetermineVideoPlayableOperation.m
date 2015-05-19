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
    NSUInteger duration;
    BOOL allowedToPlayVideo;
}
@end
@implementation DetermineVideoPlayableOperation

static BOOL lastSongWasSkipped = NO;

- (id)initWithSongDuration:(NSUInteger)songduration
{
    if(self = [super init]){
        duration = songduration;
    }
    return self;
}

- (void)main
{
    //do synchronous work
    allowedToPlayVideo = YES;
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    if(duration >= MZLongestCellularPlayableDuration){
        //videos of this length may only be played on wifi. Are we on wifi?
        if(! [reachability isConnectedToWifi])
            allowedToPlayVideo = NO;
    }
    if ([self isCancelled]){
        lastSongWasSkipped = NO;
        return;
    }

    //connection problems should take presedence first over the allowedToPlay code further down...
    if([reachability isConnectionCompletelyGone]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player dismissAllSpinners];
        [self cancel];
    }
    
    if ([self isCancelled]){
        lastSongWasSkipped = NO;
        return;
    }
    
    if(! allowedToPlayVideo){
        lastSongWasSkipped = YES;
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        //triggers the next song to play
        [player performSelectorOnMainThread:@selector(songNeedsToBeSkippedDueToIssue)
                               withObject:nil
                            waitUntilDone:NO];
        [self cancel];  //will allow dependant NSOperation to detect that it should also cancel.
        return;
    }
    
    if(lastSongWasSkipped){
        //finally reached a song in the queue that can be played. lets show the banner notif.
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
        lastSongWasSkipped = NO;
    }
    
    NSLog(@"YAY! can play video!");
}

- (BOOL)allowedToPlayVideo
{
    return allowedToPlayVideo;
}

@end
