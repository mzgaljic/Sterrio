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
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        //[reachability startNotifier];
        
        if (video)
        {
            [MusicPlaybackController declareInternetProblemWhenLoadingSong:NO];
            BOOL usingWifi = NO;
            NetworkStatus status = [reachability currentReachabilityStatus];
            if (status == ReachableViaWiFi){
                //WiFi
                allowedToPlayVideo = YES;
                usingWifi = YES;
            }
            else if (status == ReachableViaWWAN)
            {
                //3G
                if(video.duration >= 600)  //user cant watch video longer than 10 minutes without wifi
                    allowedToPlayVideo = NO;
                else
                    allowedToPlayVideo = YES;
            }
            if(allowedToPlayVideo){
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
            else{
                NSLog(@"Skipping song since it is > 10 min (on Cellular network)");
                
                [MusicPlaybackController skipToNextTrack];
#warning handle error better
                // Handle error in a nicer way, maybe with a notification banner when the user re-enters the app
                //NSString *title = @"Long Video Without Wifi";
                //NSString *msg = @"Sorry, playback of long videos (ie: more than 10 minutes) is restricted to Wifi.";
                //[self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            }
        }
        else
        {
            NetworkStatus internetStatus = [reachability currentReachabilityStatus];
            if (internetStatus == NotReachable){
                [MyAlerts displayAlertWithAlertType:CannotConnectToYouTube];
                [MusicPlaybackController declareInternetProblemWhenLoadingSong:YES];
                [MusicPlaybackController playbackExplicitlyPaused];
                [MusicPlaybackController pausePlayback];
            } else{
                [MusicPlaybackController declareInternetProblemWhenLoadingSong:NO];
                //we know for sure that the video no longer exists, notify user.
                NSLog(@"Your music video is no longer on YouTube.");
                
                [MusicPlaybackController skipToNextTrack];
#warning handle error better
                // Handle error in a nicer way, maybe with a notification banner when the user re-enters the app
                //NSString *title = @"Trouble finding your video";
                //NSString *msg = @"Sorry, it appears your music video is no longer on YouTube.";
                //[self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            }
        }
        
        if(allowedToPlayVideo && video != nil){
            playerItem = [AVPlayerItem playerItemWithURL: currentItemLink];
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
            [MusicPlaybackController simpleSpinnerOnScreen:YES];
            [self play];
            
        } else{
            if([MusicPlaybackController didPlaybackStopDueToInternetProblemLoadingSong])  //if so, don't do anything...
                return;
            
            currentItemLink = nil;
            playerItem = nil;
#warning mention "fatal error when trying to play this video"
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
    
    __block typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if(secondsSinceWeCheckedInternet < 4){
            secondsSinceWeCheckedInternet++;
            return;
        }
        else
            secondsSinceWeCheckedInternet = 0;
        
        if([weakSelf isInternetReachable]){
            [weakSelf showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
        } else{
           [weakSelf showSpinnerForInternetConnectionIssueOnView:[MusicPlaybackController obtainRawPlayerView]];
        }
    });
}

#pragma mark - Spinner convenience methods 
//these methods are also in SongPlayerViewController
- (void)showSpinnerForInternetConnectionIssueOnView:(UIView *)displaySpinnerOnMe
{
    if(![MusicPlaybackController isInternetProblemSpinnerOnScreen]){
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

- (void)showSpinnerForBasicLoadingOnView:(UIView *)displaySpinnerOnMe
{
    if(![MusicPlaybackController isSimpleSpinnerOnScreen]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
            [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
            [MusicPlaybackController simpleSpinnerOnScreen:YES];
        });
    }
}

- (void)dismissAllSpinnersForView:(UIView *)dismissViewOnMe
{
    [MRProgressOverlayView dismissAllOverlaysForView:dismissViewOnMe animated:YES];
}


#pragma mark -Internet convenience methods
- (BOOL)isInternetReachable
{
    return ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) ? NO : YES;
}

@end
