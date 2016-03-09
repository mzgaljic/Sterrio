//
//  MyAVPlayer.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAVPlayer.h"
#import "PreviousNowPlayingInfo.h"
#import "PlayableItem.h"

@interface MyAVPlayer ()
{
    BOOL movingForward;  //identifies which direction the user just went (back/forward) in queue
    BOOL canPostLastSongNotification;
    
    BOOL stallHasOccured;
    BOOL bufferingBeforeInitialPlayback;
    
    NSString *CURRENT_SONG_DONE_PLAYING;
    NSString *CURRENT_SONG_STOPPED_PLAYBACK;
    NSString *CURRENT_SONG_RESUMED_PLAYBACK;
    NSString *PLAYBACK_HAS_BEGUN_NOTIF;
}
@end

@implementation MyAVPlayer
static void *mPlaybackBufferEmpty = &mPlaybackBufferEmpty;
static void *mloadedTimeRanges = &mloadedTimeRanges;
static void *mCurrentItem = &mCurrentItem;
static void *mPlaybackRate = &mPlaybackRate;

static void *mPlaybackStarted = &mPlaybackStarted;
static void *airplayStateChanged = &airplayStateChanged;

static ReachabilitySingleton *reachability;

- (id)init
{
    if(self = [super init]){
        if(reachability == nil)
            reachability = [ReachabilitySingleton sharedInstance];
        
        CURRENT_SONG_DONE_PLAYING = @"Current item has finished, update gui please!";
        CURRENT_SONG_STOPPED_PLAYBACK = @"playback has stopped for some unknown reason (stall?)";
        CURRENT_SONG_RESUMED_PLAYBACK = @"playback has resumed from a stall probably";
        PLAYBACK_HAS_BEGUN_NOTIF = @"PlaybackStartedNotification";
        movingForward = YES;
        stallHasOccured = NO;
        _secondsLoaded = 0;
        bufferingBeforeInitialPlayback = !_playbackStarted;
        
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
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self
                    selector:@selector(songDidFinishPlaying:)
                        name:AVPlayerItemDidPlayToEndTimeNotification
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(connectionStateChanged)
                        name:MZReachabilityStateChanged
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(connectionStateChanged2)
                        name:MZReachabilityStateChanged
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(currentSongPlaybackMustBeDisabled:)
                        name:MZInterfaceNeedsToBlockCurrentSongPlayback
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(songDidBeginPlayback)
                        name:PLAYBACK_HAS_BEGUN_NOTIF
                      object:nil];
}

#pragma mark - Working with the queue to perform player actions (play, skip, etc)
- (void)startPlaybackOfSong:(Song *)aSong
               goingForward:(BOOL)forward
            oldPlayableItem:(PlayableItem *)oldItem
{
    [PreviousNowPlayingInfo setPreviousPlayableItem:oldItem];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZNewSongLoading
                                                        object:nil];
    if(aSong != nil){
        movingForward = forward;
        _playbackStarted = NO;
        [self beginLoadingVideoWithSong:aSong];
        [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlayingItem.songForItem];
    } else{
        //make sure last song doesnt continue playing...
        [self replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
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
    
    NSUInteger currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
    Song *aSong = [MusicPlaybackController nowPlayingSong];
    if(aSong != nil) {
        NSInteger absVal = ABS([aSong.duration integerValue] - currentTime);
        if(absVal >= 4) {
            //false alarm, songDidFinishPlaying called when it shouldn't have been. Big bug!
            return;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_DONE_PLAYING object:nil];
    [self dismissAllSpinners];
    
    if(! _allowSongDidFinishToExecute)
        return;
    _allowSongDidFinishToExecute = NO;
    
    if(movingForward)
        [MusicPlaybackController skipToNextTrack];
    else{
        if([MusicPlaybackController isSongFirstInQueue:[MusicPlaybackController nowPlayingSong]])
            [MusicPlaybackController skipToNextTrack];
        else
            [MusicPlaybackController returnToPreviousTrack];
    }
    //code dealing with reaching the end of the queue should be placed in the
    //MusicPlaybackControllers "SkipToNextSong" method.
}

- (void)songDidBeginPlayback
{
    [ReachabilitySingleton showCellularStreamingWarningIfApplicable];
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
    
    NSOperation *videoPlayableOp, *fetchVideoInfoOp;
    
    NSUInteger songDuration = [aSong.duration integerValue];
    NSString *artistName = (aSong.artist) ? aSong.artist.artistName : nil;
    NSManagedObjectID *coreDataObjId = aSong.objectID;
    videoPlayableOp = [[DetermineVideoPlayableOperation alloc] initWithSongDuration:songDuration];
    fetchVideoInfoOp = [[FetchVideoInfoOperation alloc] initWithSongsYoutubeId:aSong.youtube_id songName:aSong.songName artistName:artistName managedObjectId:coreDataObjId];
    
    [fetchVideoInfoOp addDependency:videoPlayableOp];
    [operationQueue addOperation:fetchVideoInfoOp];
    [operationQueue addOperation:videoPlayableOp];
    
    //if player was disabled, see if we can re-enable it
    if([SongPlayerCoordinator isPlayerInDisabledState]){
        if([aSong.duration integerValue] <= MZLongestCellularPlayableDuration){
            //enable GUI again, this song is short enough to play on cellular
            if(! [AppEnvironmentConstants isPlaybackTimerActive])
                [MusicPlaybackController explicitlyPausePlayback:NO];
            [SongPlayerCoordinator placePlayerInDisabledState:NO];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MZInterfaceNeedsToBlockCurrentSongPlayback object:[NSNumber numberWithBool:NO]];
        }
    }
}

#pragma mark - responding to current connection state
- (void)connectionStateChanged2
{
    if(bufferingBeforeInitialPlayback && _secondsLoaded == 0) {
        if([reachability isConnectionCompletelyGone]) {
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotLoadVideo];
        }
    }
}

//can also be called directly from the key-value observer method below lol. weird code.
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
                //try to resume playback...
                if(! [MusicPlaybackController playbackExplicitlyPaused]){
                    [MusicPlaybackController resumePlayback];
                }
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
                [[NSNotificationCenter defaultCenter] postNotificationName:MZInterfaceNeedsToBlockCurrentSongPlayback
                                                                    object:[NSNumber numberWithBool:YES]];
                return;
            }
            if(stallHasOccured)
            {
                [self showSpinnerForBasicLoading];
                //try to resume playback...
                if(! [MusicPlaybackController playbackExplicitlyPaused]){
                    [MusicPlaybackController resumePlayback];
                }
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
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlayingItem.songForItem];
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
            __weak MyAVPlayer *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showSpinnerForInternetConnectionIssueIfAppropriate];
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
            __weak MyAVPlayer *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showSpinnerForBasicLoading];
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
        __weak MyAVPlayer *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf dismissAllSpinners];
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

                    [self connectionStateChanged];  //let this method figure out which spinner to show
                    
                    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
                }
                
            } else if(context == mloadedTimeRanges){
                if(!_playbackStarted) {
                    bufferingBeforeInitialPlayback = YES;
                }
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
                    [self connectionStateChanged];  //let this method figure out which spinner to show

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
                    bufferingBeforeInitialPlayback = NO;
                    _playbackStarted = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:PLAYBACK_HAS_BEGUN_NOTIF
                                                                        object:nil];
                    //places approprate spinners on player if needed...or dismisses spinner.
                    [self connectionStateChanged];
                    stallHasOccured = NO;
                    [MusicPlaybackController setPlayerInStall:NO];
                    NSLog(@"playback started");
                    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
                }
                _secondsLoaded = newSecondsBuff;
            }
        }
    }else if(context == mCurrentItem){
        if(self.currentItem == nil){
            if([[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue].operationCount > 0
               && ![SongPlayerCoordinator isPlayerInDisabledState]){
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
        if([SongPlayerCoordinator isPlayerInDisabledState]){
            playerWasInDisabledState = YES;
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
        } else if(playerWasInDisabledState){
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
        }
        
        if([SongPlayerCoordinator isVideoPlayerExpanded]){
            [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                                object:nil];
        }
    } else if(context == airplayStateChanged){
        BOOL airplayActive = self.externalPlaybackActive;
        //there's a weird bug in my code that only happens in a particular scenario.
        //occurs if audio-only airplay is off, and it happens when airplay goes from
        //an enabled state to a disabled state. What happens is Sterrio thinks the app is stalled
        //and a spinner appears, even if the app isn't really stalled. Adding this logic in here
        //to try and compensate.
        if(airplayActive == NO && self.rate > 0) {
            NSLog(@"left stall");
            stallHasOccured = NO;
            [MusicPlaybackController setPlayerInStall:NO];
            [self dismissAllSpinnersIfPossible];
            if(! [MusicPlaybackController playbackExplicitlyPaused])
                [MusicPlaybackController resumePlayback];
            [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_RESUMED_PLAYBACK object:nil];
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
        }
        
        [[MusicPlaybackController obtainRawPlayerView] showAirPlayInUseMsg:airplayActive];
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

static BOOL playerWasInDisabledState = NO;

@end
