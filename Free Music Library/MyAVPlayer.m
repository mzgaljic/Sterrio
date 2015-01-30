//
//  MyAVPlayer.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAVPlayer.h"
#import "MZConstants.h"

@interface MyAVPlayer ()
{
    AVPlayerItem *playerItem;
    NSURL *currentItemLink;
    BOOL movingForward;  //identifies which direction the user just went (back/forward) in queue
    int secondsSinceWeCheckedInternet;
    BOOL allowSongDidFinishToExecute;
    BOOL canPostLastSongNotification;
    
    BOOL stallHasOccured;
    NSUInteger secondsLoaded;
    
    NSString *NEW_SONG_IN_AVPLAYER;
    NSString *AVPLAYER_DONE_PLAYING;  //queue has finished
    NSString *CURRENT_SONG_DONE_PLAYING;
    NSString * CURRENT_SONG_STOPPED_PLAYBACK;
    NSString * CURRENT_SONG_RESUMED_PLAYBACK;
}
@end

@implementation MyAVPlayer

- (id)init
{
    if(self = [super init]){
        NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
        AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";
        CURRENT_SONG_DONE_PLAYING = @"Current item has finished, update gui please!";
        CURRENT_SONG_STOPPED_PLAYBACK = @"playback has stopped for some unknown reason (stall?)";
        CURRENT_SONG_RESUMED_PLAYBACK = @"playback has resumed from a stall probably";
        movingForward = YES;
        stallHasOccured = NO;
        secondsLoaded = 0;
        currentItemLink = nil;
        playerItem = self.currentItem;
        secondsSinceWeCheckedInternet = 0;
        
        [NSTimer scheduledTimerWithTimeInterval:1.0f
                                         target:self
                                       selector:@selector(checkInternetStatus)
                                       userInfo:nil
                                        repeats:YES];
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
    } else{
        if([MusicPlaybackController numMoreSongsInQueue] == 0)
            canPostLastSongNotification = YES;
        else
            canPostLastSongNotification = NO;
        if(canPostLastSongNotification)
            [self songDidFinishPlaying:nil];
    }
}

- (void)begingListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(songDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

//Will be called when MyAVPlayer finishes playing an item
- (void)songDidFinishPlaying:(NSNotification *) notification
{
    //dont want to respond if this was just the preview player.
    if([AppEnvironmentConstants isUserPreviewingAVideo])
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_DONE_PLAYING object:nil];
    [self dismissAllSpinnersForView:[MusicPlaybackController obtainRawPlayerView]];
    
    if(! allowSongDidFinishToExecute)
        return;
    allowSongDidFinishToExecute = NO;
    
    if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more songs in queue
        if(movingForward)
            [MusicPlaybackController skipToNextTrack];
        else{
            if([MusicPlaybackController isSongFirstInQueue:[MusicPlaybackController nowPlayingSong]])
                [MusicPlaybackController skipToNextTrack];
            else
                [MusicPlaybackController returnToPreviousTrack];
        }
    }
    else{  //last song just ended (happens when playback ends by itself, not when tracks are skipped)
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [MusicPlaybackController pausePlayback];
        [[NSNotificationCenter defaultCenter] postNotificationName:AVPLAYER_DONE_PLAYING
                                                            object:nil];
    }
}

- (void)playSong:(Song *)aSong
{
    secondsLoaded = 0;
    stallHasOccured = NO;
    [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
    __weak MyAVPlayer *weakSelf = self;
    __weak PlayerView *weakPlayerView = [MusicPlaybackController obtainRawPlayerView];
    __weak NSString *weakId = aSong.youtube_id;
    __weak NSNumber *weakDuration = aSong.duration;
    __weak Song *weakNowPlaying = [MusicPlaybackController nowPlayingSong];
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    BOOL usingWifi = NO;
    BOOL allowedToPlayVideo = YES;  //not checking if we can physically play, but legally (Apple's 10 minute streaming rule)
    
    [MusicPlaybackController declareInternetProblemWhenLoadingSong:NO];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == ReachableViaWiFi)
        usingWifi = YES;
    
    if(! usingWifi && status != NotReachable){
        if([weakDuration integerValue] >= MZLongestCellularPlayableDuration)
            //user cant watch video longer than 10 minutes without wifi
            allowedToPlayVideo = NO;
    } else if(! usingWifi && status == NotReachable){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        [self dismissAllSpinnersForView:[MusicPlaybackController obtainRawPlayerView]];
        [MusicPlaybackController declareInternetProblemWhenLoadingSong:YES];
        [MusicPlaybackController playbackExplicitlyPaused];
        [MusicPlaybackController pausePlayback];
    }
    
    if(! allowedToPlayVideo){
        if(status != NotReachable){
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
            //triggers the next song to play (for whatever reason/error)
            [self performSelector:@selector(songDidFinishPlaying:) withObject:nil afterDelay:0.01];
            allowSongDidFinishToExecute = YES;
        }
        return;
    }
    __weak SongPlayerCoordinator *weakCoordinator = [SongPlayerCoordinator sharedInstance];
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
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
            allowSongDidFinishToExecute = YES;
            if (internetStatus == NotReachable){
                [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
                [MusicPlaybackController declareInternetProblemWhenLoadingSong:YES];
                [MusicPlaybackController playbackExplicitlyPaused];
                [MusicPlaybackController pausePlayback];
                return;
            } else{
                [MusicPlaybackController declareInternetProblemWhenLoadingSong:NO];
                //video may no longer exist, or some other problem has occured
                [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotLoadVideo];
                [MusicPlaybackController skipToNextTrack];
                return;
            }
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL: currentItemLink];
        
        if(allowedToPlayVideo && video != nil){
            [weakCoordinator enablePlayerAgain];
            playerItem = [AVPlayerItem playerItemWithAsset: asset];
            allowSongDidFinishToExecute = YES;
            [weakSelf replaceCurrentItemWithPlayerItem:playerItem];
            [weakSelf registerForObservers];
            
            // Declare block scope variables to avoid retention cycles from references inside the block
            __block id obs;
            // Setup boundary time observer to trigger when audio really begins (specifically after 1/10 of a second of playback)
            __weak MyAVPlayer *weakSelf = self;
            __weak PlayerView *weakPlayerView = [MusicPlaybackController obtainRawPlayerView];
            obs = [weakSelf addBoundaryTimeObserverForTimes:
                   @[[NSValue valueWithCMTime:CMTimeMake(1, 10)]]
                                                  queue:NULL
                                             usingBlock:^{
                                                 [weakSelf dismissAllSpinnersForView:weakPlayerView];
                                                 // Raise a notificaiton when playback has started
                                                 [[NSNotificationCenter defaultCenter]
                                                  postNotificationName:@"PlaybackStartedNotification"
                                                  object:nil];
                                                 [MusicPlaybackController updateLockScreenInfoAndArtForSong:weakNowPlaying];
                                                 
                                                 // Remove the boundary time observer
                                                 [weakSelf removeTimeObserver:obs];
                                             }];
            [weakSelf play];
            
        } else{
            if([MusicPlaybackController didPlaybackStopDueToInternetProblemLoadingSong])  //if so, don't do anything...
                return;
            
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
            [weakSelf dismissAllSpinnersForView:weakPlayerView];
            [weakSelf songDidFinishPlaying:nil];  //triggers the next song to play (for whatever reason/error) in the correct direction
        }
    }];
}


- (void)checkInternetStatus
{
    if(!stallHasOccured)
        return;
    if(stallHasOccured && [MusicPlaybackController playbackExplicitlyPaused])
        return;
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive){
        return;
    }
    
    if(secondsSinceWeCheckedInternet < 3){
        secondsSinceWeCheckedInternet++;
        return;
    }
    else
        secondsSinceWeCheckedInternet = 0;
    
    if([self isInternetReachable]){
        if(![MusicPlaybackController isSimpleSpinnerOnScreen]){
            [self dismissAllSpinnersForView:[MusicPlaybackController obtainRawPlayerView]];
            [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
        }
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
                                                    title:@"Internet connection lost."
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
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    return ([reachability currentReachabilityStatus] == NotReachable) ? NO : YES;
}

#pragma mark - Key value observing magic here  :D
- (void)registerForObservers
{
    [self addObserver:self
           forKeyPath:@"currentItem.playbackBufferEmpty"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"currentItem.loadedTimeRanges"
              options:NSKeyValueObservingOptionNew
              context:nil];
}

/*Not actually needed now since this class is in existance the entire time, it is never deallocated.
- (void)deregisterForObservers
{
    @try{
        [self removeObserver:self forKeyPath:@"currentItem.playbackBufferEmpty"];
    }
    //do nothing, obviously it wasn't attached because an exception was thrown
    @catch(id anException){}
}
*/

//CURRENT_SONG_STOPPED_PLAYBACK
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSArray * timeRanges = self.currentItem.loadedTimeRanges;
    if (timeRanges && [timeRanges count]){
        CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
        NSUInteger newSecondsBuff = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
        NSUInteger totalSeconds = [[MusicPlaybackController nowPlayingSong].duration integerValue];
        
        if([keyPath isEqualToString:@"currentItem.playbackBufferEmpty"]){
            BOOL explicitlyPaused = [MusicPlaybackController playbackExplicitlyPaused];
            if(newSecondsBuff == secondsLoaded && secondsLoaded != totalSeconds && !explicitlyPaused){
                NSLog(@"In stall");
                stallHasOccured = YES;
                [MusicPlaybackController setPlayerInStall:YES];
                [MusicPlaybackController pausePlayback];
                [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_STOPPED_PLAYBACK
                                                                    object:nil];
                
                if(! [MusicPlaybackController isSpinnerOnScreen]){
                    [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
                }
            }

        } else if([keyPath isEqualToString:@"currentItem.loadedTimeRanges"]){
            NSUInteger currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
            CMTimeRange aTimeRange;
            NSUInteger lowBound;
            NSUInteger upperBound;
            BOOL inALoadedRange = NO;
            for(int i = 0; i < timeRanges.count; i++){
                aTimeRange = [timeRanges[i] CMTimeRangeValue];
                lowBound = CMTimeGetSeconds(timerange.start);
                upperBound = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
                if(currentTime >= lowBound && currentTime < upperBound)
                    inALoadedRange = YES;
            }
            
            if(! inALoadedRange){
                NSLog(@"In stall");
                stallHasOccured = YES;
                [MusicPlaybackController setPlayerInStall:YES];
                [MusicPlaybackController pausePlayback];
                [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_STOPPED_PLAYBACK
                                                                    object:nil];
                
                //user must be skipping ahead with the slider. show the spinner!
                if(! [MusicPlaybackController isSpinnerOnScreen]){
                    [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
                }
            } else if(newSecondsBuff > secondsLoaded && stallHasOccured){
                NSLog(@"left stall");
                stallHasOccured = NO;
                [MusicPlaybackController setPlayerInStall:NO];
                [self dismissAllSpinnersForView:[MusicPlaybackController obtainRawPlayerView]];
                if(! [MusicPlaybackController playbackExplicitlyPaused])
                    [MusicPlaybackController resumePlayback];
                [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_RESUMED_PLAYBACK
                                                                    object:nil];
            }
            secondsLoaded = newSecondsBuff;
        }
    }
}

@end
