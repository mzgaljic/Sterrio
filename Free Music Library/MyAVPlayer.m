//
//  MyAVPlayer.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAVPlayer.h"


@interface MyAVPlayer ()
{
    AVPlayerItem *playerItem;
    NSURL *currentItemLink;
    BOOL movingForward;  //identifies which direction the user just went (back/forward) in queue
    int secondsSinceWeCheckedInternet;
    
    NSString * NEW_SONG_IN_AVPLAYER;
    NSString * AVPLAYER_DONE_PLAYING;
}
@end

@implementation MyAVPlayer


- (id)init
{
    if(self = [super init]){
        NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
        AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";
        movingForward = YES;
        currentItemLink = nil;
        playerItem = self.currentItem;
        secondsSinceWeCheckedInternet = 0;
        
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(checkInternetStatus) userInfo:nil repeats:YES];
        [self begingListeningForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)forward
{
    [MusicPlaybackController printQueueContents];
    if(aSong != nil){
        movingForward = forward;
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_SONG_IN_AVPLAYER
                                                            object:[MusicPlaybackController nowPlayingSong]];
        [self playSong:aSong];
        [MusicPlaybackController updateLockScreenInfoAndArtForSong:aSong];
    }
}

- (void)begingListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(songDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

//Will be called when YTVideoAvPlayer finishes playing a YTVideoPlayerItem
- (void)songDidFinishPlaying:(NSNotification *) notification
{
    if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more songs in queue
        if(movingForward)
            [MusicPlaybackController skipToNextTrack];
        else
            [MusicPlaybackController returnToPreviousTrack];
    }
    else{  //last song just ended
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [MusicPlaybackController pausePlayback];
        [[NSNotificationCenter defaultCenter] postNotificationName:AVPLAYER_DONE_PLAYING
                                                            object:nil];
    }
}

- (void)playSong:(Song *)aSong
{
    __weak NSString *weakId = aSong.youtube_id;
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        BOOL allowedToPlayVideo = NO;  //not checking if we can physically play, but legally (Apple's 10 minute streaming rule)
        BOOL usingWifi = NO;
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        //[reachability startNotifier];
        
        if (video)
        {
            
            [MusicPlaybackController declareInternetProblemWhenLoadingSong:NO];
            NetworkStatus status = [reachability currentReachabilityStatus];
            if (status == ReachableViaWiFi)
                usingWifi = YES;
            
            //find video quality closest to setting preferences
            NSDictionary *vidQualityDict = video.streamURLs;
            NSURL *url;
            if(usingWifi){
                short maxDesiredQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
                url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
            }else{
                short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
            }
            currentItemLink = url;
        }
        else
        {
            NetworkStatus internetStatus = [reachability currentReachabilityStatus];
            if (internetStatus == NotReachable){
                [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
                [MusicPlaybackController declareInternetProblemWhenLoadingSong:YES];
                [MusicPlaybackController playbackExplicitlyPaused];
                [MusicPlaybackController pausePlayback];
                return;
            } else{
                [MusicPlaybackController declareInternetProblemWhenLoadingSong:NO];
                //we know for sure that the video no longer exists, notify user.
                NSLog(@"Your music video is no longer on YouTube.");
                
                [MusicPlaybackController skipToNextTrack];
                return;
#warning handle error better
                // Handle error in a nicer way, maybe with a notification banner when the user re-enters the app
                //NSString *title = @"Trouble finding your video";
                //NSString *msg = @"Sorry, it appears your music video is no longer on YouTube.";
                //[self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            }
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL: currentItemLink];
        Float64 duration = CMTimeGetSeconds(asset.duration);
        int otherDuration = video.duration;
        allowedToPlayVideo = YES;  //temp functionality
        if(! usingWifi){
            /*
            if(duration >= 600)  //user cant watch video longer than 10 minutes without wifi
                allowedToPlayVideo = NO;
            else
                allowedToPlayVideo = YES;
             */
        }
        if(allowedToPlayVideo && video != nil){
            playerItem = [AVPlayerItem playerItemWithAsset: asset];
            [self replaceCurrentItemWithPlayerItem:playerItem];
            
            // Declare block scope variables to avoid retention cycles from references inside the block
            __block AVPlayer* weakSelf = self;
            __block id obs;
            // Setup boundary time observer to trigger when audio really begins (specifically after 1/10 of a second of playback)
            obs = [self addBoundaryTimeObserverForTimes:
                   @[[NSValue valueWithCMTime:CMTimeMake(1, 10)]]
                                                  queue:NULL
                                             usingBlock:^{
                                                 // Raise a notificaiton when playback has started
                                                 [[NSNotificationCenter defaultCenter]
                                                  postNotificationName:@"PlaybackStartedNotification"
                                                  object:nil];
                                                 
                                                 // Remove the boundary time observer
                                                 [weakSelf removeTimeObserver:obs];
                                             }];
            [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
            [self play];
            
        } else{
            if([MusicPlaybackController didPlaybackStopDueToInternetProblemLoadingSong])  //if so, don't do anything...
                return;
            
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
            [MusicPlaybackController skipToNextTrack];
            
            [self songDidFinishPlaying:nil];  //triggers the next song to play (for whatever reason/error)
        }
    }];
}

- (void)launchAlertViewWithDialogUsingTitle:(NSString *)title andMessage:(NSString *)msg
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:title
                                                      message:msg
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

- (void)checkInternetStatus
{
    if(self.rate == 1)
        return;
    if(self.rate == 0 && [MusicPlaybackController playbackExplicitlyPaused])
        return;
    
    if(secondsSinceWeCheckedInternet < 2){
        secondsSinceWeCheckedInternet++;
        return;
    }
    else
        secondsSinceWeCheckedInternet = 0;
    
    if([self isInternetReachable]){
        [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
    } else{
        [self showSpinnerForInternetConnectionIssueOnView:[MusicPlaybackController obtainRawPlayerView]];
    }
}

#pragma mark - Spinner convenience methods
//these methods are also in SongPlayerViewController
- (void)showSpinnerForInternetConnectionIssueOnView:(UIView *)displaySpinnerOnMe
{
    if(![MusicPlaybackController isInternetProblemSpinnerOnScreen]){
        if([NSThread isMainThread]){
            [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
            [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe
                                                title:@"Internet connection lost..."
                                                 mode:MRProgressOverlayViewModeIndeterminateSmall
                                             animated:YES];
            [MusicPlaybackController internetProblemSpinnerOnScreen:YES];
        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
                [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe
                                                    title:@"Internet connection lost..."
                                                     mode:MRProgressOverlayViewModeIndeterminateSmall
                                                 animated:YES];
                [MusicPlaybackController internetProblemSpinnerOnScreen:YES];
            });

        }
    }
}

- (void)showSpinnerForBasicLoadingOnView:(UIView *)displaySpinnerOnMe
{
    if(![MusicPlaybackController isSimpleSpinnerOnScreen]){
        if([NSThread isMainThread]){
            [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
            [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
            [MusicPlaybackController simpleSpinnerOnScreen:YES];

        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
                [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
                [MusicPlaybackController simpleSpinnerOnScreen:YES];
            });
        }
    }
}

- (void)dismissAllSpinnersForView:(UIView *)dismissViewOnMe
{
    if([NSThread isMainThread]){
        [MRProgressOverlayView dismissAllOverlaysForView:dismissViewOnMe animated:YES];
        [MusicPlaybackController noSpinnersOnScreen];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [MRProgressOverlayView dismissAllOverlaysForView:dismissViewOnMe animated:YES];
            [MusicPlaybackController noSpinnersOnScreen];
        });
    }
}


#pragma mark -Internet convenience methods
- (BOOL)isInternetReachable
{
    return ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) ? NO : YES;
}

@end
