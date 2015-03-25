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
    BOOL movingForward;  //identifies which direction the user just went (back/forward) in queue
    BOOL canPostLastSongNotification;
    
    BOOL stallHasOccured;
    
    NSString *CURRENT_SONG_DONE_PLAYING;
    NSString *CURRENT_SONG_STOPPED_PLAYBACK;
    NSString *CURRENT_SONG_RESUMED_PLAYBACK;
    NSString *PlaybackHasBegun;
    
    ReachabilitySingleton *reachability;
}
@end

@implementation MyAVPlayer
static void *mPlaybackBufferEmpty = &mPlaybackBufferEmpty;
static void *mloadedTimeRanges = &mloadedTimeRanges;
static void *mCurrentItem = &mCurrentItem;
static void *mPlaybackRate = &mPlaybackRate;

static void *mPlaybackStarted = &mPlaybackStarted;
static void *airplayStateChanged = &airplayStateChanged;

- (id)init
{
    if(self = [super init]){
        reachability = [ReachabilitySingleton sharedInstance];
        CURRENT_SONG_DONE_PLAYING = @"Current item has finished, update gui please!";
        CURRENT_SONG_STOPPED_PLAYBACK = @"playback has stopped for some unknown reason (stall?)";
        CURRENT_SONG_RESUMED_PLAYBACK = @"playback has resumed from a stall probably";
        PlaybackHasBegun = @"PlaybackStartedNotification";
        movingForward = YES;
        stallHasOccured = NO;
        _secondsLoaded = 0;
        
        [self begingListeningForNotifications];
        [self registerForObservers];
    }
    return self;
}

- (void)dealloc
{
    [self deregisterForObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

- (void)begingListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(songDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStateChanged)
                                                 name:MZReachabilityStateChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentSongPlaybackMustBeDisabled:)
                                                 name:MZInterfaceNeedsToBlockCurrentSongPlayback
                                               object:nil];
}

#pragma mark - Working with the queue to perform player actions (play, skip, etc)
- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)forward oldSong:(Song *)oldSong
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZNewSongLoading
                                                        object:oldSong];
    if(aSong != nil){
        movingForward = forward;
        _playbackStarted = NO;
        [self beginLoadingVideoWithSong:aSong];
        [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
    } else{
        //playback wont ever start...
        [self dismissAllSpinners];
        
        if([MusicPlaybackController numMoreSongsInQueue] == 0)
            canPostLastSongNotification = YES;
        else
            canPostLastSongNotification = NO;
        if(canPostLastSongNotification)
            [self songDidFinishPlaying:nil];
    }
}

//public wrapper for songDidFinishPlaying:
- (void)songNeedsToBeSkippedDueToIssue
{
    if([NSThread mainThread]){
        [self allowSongDidFinishNotificationToProceed:YES];
        [self songDidFinishPlaying:nil];
        [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
    } else{
        __weak MyAVPlayer *weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself songNeedsToBeSkippedDueToIssue];
        });
    }
}

- (void)allowSongDidFinishNotificationToProceed:(BOOL)proceed
{
    _allowSongDidFinishToExecute = proceed;
}

- (BOOL)allowSongDidFinishValue
{
    return _allowSongDidFinishToExecute;
}

//Will be called when MyAVPlayer finishes playing an item
- (void)songDidFinishPlaying:(NSNotification *) notification
{
    //dont want to respond if this was just the preview player.
    if([AppEnvironmentConstants isUserPreviewingAVideo])
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_DONE_PLAYING object:nil];
    [self dismissAllSpinners];
    
    if(! _allowSongDidFinishToExecute)
        return;
    _allowSongDidFinishToExecute = NO;
    
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
}

#pragma mark - initiating playback
- (void)beginLoadingVideoWithSong:(Song *)aSong
{
    //prevents any funny behavior with existing video until the new one loads.
    [MusicPlaybackController explicitlyPausePlayback:NO];
    [SongPlayerCoordinator placePlayerInDisabledState:NO];
    
    _secondsLoaded = 0;
    stallHasOccured = NO;
    NSOperationQueue *operationQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
    [operationQueue cancelAllOperations];
    [self showSpinnerForBasicLoading];
    
    NSOperation *determineVideoPlayableOperation, *fetchVideoInfoOperation;
    
    determineVideoPlayableOperation = [[DetermineVideoPlayableOperation alloc] initWithSong:aSong];
    fetchVideoInfoOperation = [[FetchVideoInfoOperation alloc] initWithSong:aSong];
    
    [fetchVideoInfoOperation addDependency:determineVideoPlayableOperation];
    [operationQueue addOperation:determineVideoPlayableOperation];
    [operationQueue addOperation:fetchVideoInfoOperation];
    
    //if player was disabled, see if we can re-enable it
    if([SongPlayerCoordinator isPlayerInDisabledState]){
        if([aSong.duration integerValue] <= MZLongestCellularPlayableDuration){
            //enable GUI again, this song is short enough to play on cellular
            [MusicPlaybackController explicitlyPausePlayback:NO];
            [SongPlayerCoordinator placePlayerInDisabledState:NO];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MZInterfaceNeedsToBlockCurrentSongPlayback object:[NSNumber numberWithBool:NO]];
        }
    }
}

- (void)beginPlaybackWithPlayerItem:(AVPlayerItem *)item
{
    if(! [SongPlayerCoordinator isPlayerOnScreen])
        return;
    
    if([NSThread mainThread]){
        NSOperationQueue *operationQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
        [self replaceCurrentItemWithPlayerItem:item];
        [self play];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZNewTimeObserverCanBeAdded
                                                            object:nil];
        [operationQueue cancelAllOperations];
    } else{
        __weak MyAVPlayer *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            NSOperationQueue *operationQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
            [weakSelf replaceCurrentItemWithPlayerItem:item];
            [weakSelf play];
            [[NSNotificationCenter defaultCenter] postNotificationName:MZNewTimeObserverCanBeAdded
                                                                object:nil];
            [operationQueue cancelAllOperations];
        });
    }
}

#pragma mark - responding to current connection state
- (void)connectionStateChanged
{
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    if([reachability isConnectedToInternet])
    {
        if([reachability isConnectedToWifi])
        {
            if([nowPlaying.duration integerValue] >= MZLongestCellularPlayableDuration &&
               [SongPlayerCoordinator isPlayerInDisabledState]){
                //enable GUI again, they are back on wifi, playback can resume
                [[NSNotificationCenter defaultCenter] postNotificationName:MZInterfaceNeedsToBlockCurrentSongPlayback object:[NSNumber numberWithBool:NO]];
            }
            
            if(stallHasOccured)
            {
                [self showSpinnerForBasicLoading];
                return;
            }

            //otherwise no problems could possibly occur at this point...
            [self dismissAllSpinners];
            return;
        }
        else
        {
            if([nowPlaying.duration integerValue] >= MZLongestCellularPlayableDuration){
                //disable GUI, alert user that he/she needs to be on wifi
                [self showSpinnerForWifiNeeded];
                [[NSNotificationCenter defaultCenter] postNotificationName:MZInterfaceNeedsToBlockCurrentSongPlayback object:[NSNumber numberWithBool:YES]];
                return;
            }
            if(stallHasOccured)
            {
                [self showSpinnerForBasicLoading];
                return;
            }
            //otherwise no problems could possibly occur at this point...
            [self dismissAllSpinners];
            return;
        }
    }
    else
    {
        [self showSpinnerForInternetConnectionIssueIfAppropriate];
        return;
    }
}

static CMTime timeAtDisable;
static AVPlayerItem *disabledPlayerItem;
static BOOL valOfAllowSongDidFinishToExecuteBeforeDisabling;
- (void)currentSongPlaybackMustBeDisabled:(NSNotification *)notif
{
    //NOTE: When player is resumed or paused, the rate key observer will fire calls to
    //update the lock screen with the needed info.
    if([notif.name isEqualToString:MZInterfaceNeedsToBlockCurrentSongPlayback]){
        NSNumber *val = (NSNumber *)notif.object;
        BOOL disabled = [val boolValue];
        if(disabled){
            [SongPlayerCoordinator placePlayerInDisabledState:YES];
            [MusicPlaybackController explicitlyPausePlayback:YES];
            _elapsedTimeBeforeDisabling = [NSNumber numberWithInteger:CMTimeGetSeconds(self.currentItem.currentTime)];
            [MusicPlaybackController pausePlayback];
            
            //make copy of AVPlayerItem which will retain buffered data
            disabledPlayerItem = [self.currentItem copy];
            timeAtDisable = self.currentItem.currentTime;
            valOfAllowSongDidFinishToExecuteBeforeDisabling = _allowSongDidFinishToExecute;
            _allowSongDidFinishToExecute = NO;
            //force playback to stop (only way that seems to work)
            [self replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
            
        } else{
            //re-insert the disabled player item, with the loaded buffers intact.
            [self replaceCurrentItemWithPlayerItem:disabledPlayerItem];
            [self seekToTime:timeAtDisable toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            _allowSongDidFinishToExecute = valOfAllowSongDidFinishToExecuteBeforeDisabling;
            if([SongPlayerCoordinator wasPlayerInPlayStateBeforeGUIDisabled]){
                [MusicPlaybackController explicitlyPausePlayback:NO];
                [MusicPlaybackController resumePlayback];
            }
            [SongPlayerCoordinator placePlayerInDisabledState:NO];
            disabledPlayerItem = nil;
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlaying];
        }
    }
}

#pragma mark - Spinner convenience methods
- (void)showSpinnerForInternetConnectionIssueIfAppropriate
{
    if(! stallHasOccured){
        [self dismissAllSpinners];
        return;
    }
    if(![MusicPlaybackController isInternetProblemSpinnerOnScreen]){
        if([NSThread isMainThread]){
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
            [MRProgressOverlayView showOverlayAddedTo:playerView
                                                title:@"Connection lost"
                                                 mode:MRProgressOverlayViewModeIndeterminateSmall
                                             animated:YES];
            [MusicPlaybackController internetProblemSpinnerOnScreen:YES];
        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
                [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
                [MRProgressOverlayView showOverlayAddedTo:playerView
                                                    title:@"Connection lost"
                                                     mode:MRProgressOverlayViewModeIndeterminateSmall
                                                 animated:YES];
                [MusicPlaybackController internetProblemSpinnerOnScreen:YES];
            });
        }
    }
}

- (void)showSpinnerForBasicLoading
{
    if(![MusicPlaybackController isSimpleSpinnerOnScreen]){
        if([NSThread isMainThread]){
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
            [MRProgressOverlayView showOverlayAddedTo:playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
            [MusicPlaybackController simpleSpinnerOnScreen:YES];

        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
                [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
                [MRProgressOverlayView showOverlayAddedTo:playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
                [MusicPlaybackController simpleSpinnerOnScreen:YES];
            });
        }
    }
}

- (void)showSpinnerForWifiNeeded
{
    if(![MusicPlaybackController isSpinnerForWifiNeededOnScreen]){
        if([NSThread isMainThread]){
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
            
            NSString *text;
            if([SongPlayerCoordinator isVideoPlayerExpanded])
                text = @"Song requires WiFi";
            else
                text = @"WiFi";
                
            [MRProgressOverlayView showOverlayAddedTo:playerView title:text
                                                 mode:MRProgressOverlayViewModeIndeterminateSmall
                                             animated:YES];
            [MusicPlaybackController spinnerForWifiNeededOnScreen:YES];
            playerView.userInteractionEnabled = YES;
            [playerView setNeedsDisplay];
            
        } else{
            __weak MyAVPlayer *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showSpinnerForWifiNeeded];
            });
        }
    }
}

- (void)dismissAllSpinnersIfPossible
{
    [self connectionStateChanged];
}

//should NEVER be called directly, except by the connectionStateChanged method
//or after song is done playing.
- (void)dismissAllSpinners
{
    if([NSThread isMainThread]){
        PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
        [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
        [MusicPlaybackController noSpinnersOnScreen];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^{
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:YES];
            [MusicPlaybackController noSpinnersOnScreen];
        });
    }
}

#pragma mark - Key value observing magic here  :D
- (void)registerForObservers
{
    [self addObserver:self
           forKeyPath:@"currentItem.playbackBufferEmpty"
              options:NSKeyValueObservingOptionNew
              context:mPlaybackBufferEmpty];
    [self addObserver:self
           forKeyPath:@"currentItem.loadedTimeRanges"
              options:NSKeyValueObservingOptionNew
              context:mloadedTimeRanges];
    [self addObserver:self
           forKeyPath:@"currentItem"
              options:NSKeyValueObservingOptionNew
              context:mCurrentItem];
    [self addObserver:self
           forKeyPath:@"playbackStarted"
              options:NSKeyValueObservingOptionNew
              context:mPlaybackStarted];
    [self addObserver:self
           forKeyPath:@"rate"
              options:NSKeyValueObservingOptionNew
              context:mPlaybackRate];
    [self addObserver:self
           forKeyPath:@"externalPlaybackActive"
              options:NSKeyValueObservingOptionNew
              context:airplayStateChanged];
}

- (void)deregisterForObservers
{
    Fabric *myFabric = [Fabric sharedSDK];
    myFabric.debug = YES;
    @try{
        [self removeObserver:self
                  forKeyPath:@"currentItem.playbackBufferEmpty"
                     context:mPlaybackBufferEmpty];
        [self removeObserver:self
                  forKeyPath:@"currentItem.loadedTimeRanges"
                     context:mloadedTimeRanges];
        [self removeObserver:self
                  forKeyPath:@"currentItem"
                     context:mCurrentItem];
        [self removeObserver:self
                  forKeyPath:@"playbackStarted"
                     context:mPlaybackStarted];
        [self removeObserver:self
                  forKeyPath:@"rate"
                     context:mPlaybackRate];
        [self removeObserver:self
                  forKeyPath:@"externalPlaybackActive"
                     context:airplayStateChanged];
    }
    //do nothing, obviously it wasn't attached because an exception was thrown
    @catch(id anException){}
    myFabric.debug = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(context == mloadedTimeRanges || context == mPlaybackBufferEmpty){
        NSArray *timeRanges = self.currentItem.loadedTimeRanges;
        if (timeRanges && [timeRanges count]){
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            NSUInteger newSecondsBuff = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
            NSUInteger totalSeconds = [[MusicPlaybackController nowPlayingSong].duration integerValue];
            if(context == mPlaybackBufferEmpty){
                BOOL explicitlyPaused = [MusicPlaybackController playbackExplicitlyPaused];
                if(newSecondsBuff == _secondsLoaded && _secondsLoaded != totalSeconds && !explicitlyPaused && !stallHasOccured){
                    NSLog(@"In stall");
                    stallHasOccured = YES;
                    [MusicPlaybackController setPlayerInStall:YES];
                    if(self.rate > 0)
                        [MusicPlaybackController pausePlayback];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_STOPPED_PLAYBACK
                                                                        object:nil];
                    //let this method figure out which spinner to show
                    [self connectionStateChanged];
                    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
                }
                
            } else if(context == mloadedTimeRanges){
                NSUInteger currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
                CMTimeRange aTimeRange;
                NSUInteger lowBound;
                NSUInteger upperBound;
                BOOL inALoadedRange = NO;
                for(int i = 0; i < timeRanges.count; i++){
                    aTimeRange = [timeRanges[i] CMTimeRangeValue];
                    lowBound = CMTimeGetSeconds(timerange.start);
                    upperBound = CMTimeGetSeconds(CMTimeAdd(timerange.start, aTimeRange.duration));
                    if(currentTime >= lowBound && currentTime < upperBound)
                        inALoadedRange = YES;
                }
                
                if(! inALoadedRange && !stallHasOccured){
                    NSLog(@"In stall");
                    stallHasOccured = YES;
                    [MusicPlaybackController setPlayerInStall:YES];
                    if(self.rate > 0)
                        [MusicPlaybackController pausePlayback];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_STOPPED_PLAYBACK
                                                                        object:nil];
                    //let this method figure out which spinner to show
                    [self connectionStateChanged];
                    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
                    
                } else if(newSecondsBuff > _secondsLoaded && stallHasOccured && [[ReachabilitySingleton sharedInstance] isConnectedToInternet]){
                    NSLog(@"left stall");
                    stallHasOccured = NO;
                    [MusicPlaybackController setPlayerInStall:NO];
                    [self dismissAllSpinnersIfPossible];
                    if(! [MusicPlaybackController playbackExplicitlyPaused])
                        [MusicPlaybackController resumePlayback];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_RESUMED_PLAYBACK object:nil];
                    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
                }
                //check if playback began
                if(newSecondsBuff > _secondsLoaded && self.rate == 1 && !self.playbackStarted){
                    _playbackStarted = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackHasBegun
                                                                        object:nil];
                    //places approprate spinners on player if needed...or dismisses spinner.
                    [self connectionStateChanged];
                    NSLog(@"playback started");
                    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
                }
                _secondsLoaded = newSecondsBuff;
            }
        }
    }else if(context == mCurrentItem){
        if(self.currentItem == nil){
            if([[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue].operationCount > 0){
               //we are loading a new song, user might want to see this info on lock screen.
                [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
            }
        }
    } else if(context == mPlaybackStarted){
        if(self.playbackStarted){
            //we are loading a new song, user might want to see this info on lock screen.
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
        }
    }else if(context == mPlaybackRate){
        if([SongPlayerCoordinator isVideoPlayerExpanded]){
            [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                                object:nil];
        }
    } else if(context == airplayStateChanged){
        BOOL airplayActive = self.externalPlaybackActive;
        
        [[MusicPlaybackController obtainRawPlayerView] showAirPlayInUseMsg:airplayActive];
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
