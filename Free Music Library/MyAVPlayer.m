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
    BOOL playbackStarted;
    
    BOOL stallHasOccured;
    NSUInteger secondsLoaded;
    
    NSString *AVPLAYER_DONE_PLAYING;  //queue has finished
    NSString *CURRENT_SONG_DONE_PLAYING;
    NSString * CURRENT_SONG_STOPPED_PLAYBACK;
    NSString * CURRENT_SONG_RESUMED_PLAYBACK;
    
    ReachabilitySingleton *reachability;
}
@end

@implementation MyAVPlayer
static void *mPlaybackBufferEmpty = &mPlaybackBufferEmpty;
static void *mloadedTimeRanges = &mloadedTimeRanges;
static NSOperationQueue *operationQueue;

- (id)init
{
    if(self = [super init]){
        operationQueue = [[NSOperationQueue alloc] init];
        reachability = [ReachabilitySingleton sharedInstance];
        
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
        
        [self begingListeningForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)forward oldSong:(Song *)oldSong
{
    [MusicPlaybackController printQueueContents];
    
    if(aSong != nil){
        movingForward = forward;
        playbackStarted = NO;
        //[self playSong:aSong];
        [self beginLoadingVideoWithSong:aSong];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZNewSongLoading
                                                            object:oldSong];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStateChanged)
                                                 name:MZReachabilityStateChanged
                                               object:nil];
}

//public wrapper for songDidFinishPlaying:
- (void)songNeedsToBeSkippedDueToIssue
{
    [self songDidFinishPlaying:nil];
    allowSongDidFinishToExecute = YES;
}

//Will be called when MyAVPlayer finishes playing an item
- (void)songDidFinishPlaying:(NSNotification *) notification
{
    //dont want to respond if this was just the preview player.
    if([AppEnvironmentConstants isUserPreviewingAVideo])
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_DONE_PLAYING object:nil];
    [self dismissAllSpinners];
    
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

- (void)beginLoadingVideoWithSong:(Song *)aSong
{
    secondsLoaded = 0;
    stallHasOccured = NO;
    [operationQueue cancelAllOperations];
    [self showSpinnerForBasicLoading];
    
    NSOperation *determineVideoPlayableOperation, *fetchVideoInfoOperation;
    
    determineVideoPlayableOperation = [[DetermineVideoPlayableOperation alloc] init];
    fetchVideoInfoOperation = [[FetchVideoInfoOperation alloc] initWithSong:aSong];
    
    [fetchVideoInfoOperation addDependency:determineVideoPlayableOperation];
    [operationQueue addOperation:determineVideoPlayableOperation];
    [operationQueue addOperation:fetchVideoInfoOperation];
}

- (void)begingLoadingPlayerWithPlayerItem:(AVPlayerItem *)item
{
    NSLog(@"Setting player item.");
    if([NSThread mainThread]){
        [self replaceCurrentItemWithPlayerItem:item];
        [self play];
    } else{
        __weak MyAVPlayer *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [weakSelf replaceCurrentItemWithPlayerItem:playerItem];
            [weakSelf play];
        });
    }
}


- (void)connectionStateChanged
{
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    if([reachability isConnectedToInternet])
    {
        if([reachability isConnectedToWifi])
        {
            if(stallHasOccured)
            {
                [self showSpinnerForBasicLoading];
            }
            //otherwise no problems could possibly occur at this point...
            [self dismissAllSpinners];
            return;
        }
        else
        {
            if([nowPlaying.duration integerValue] >= MZLongestCellularPlayableDuration){
                //disable GUI, alert user
                [self showSpinnerForWifiNeeded];
#warning need to execute code to lock user from moving around in video or pressing play.
            }
            if(stallHasOccured)
            {
                [self showSpinnerForBasicLoading];
            }
            //otherwise no problems could possibly occur at this point...
            [self dismissAllSpinners];
            return;
        }
    }
    else
    {
        [self showSpinnerForInternetConnectionIssue];
    }
}

#pragma mark - Spinner convenience methods
- (void)showSpinnerForInternetConnectionIssue
{
    if(![MusicPlaybackController isInternetProblemSpinnerOnScreen]){
        if([NSThread isMainThread]){
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:NO];
            [MRProgressOverlayView showOverlayAddedTo:playerView
                                                title:@"Connection lost"
                                                 mode:MRProgressOverlayViewModeIndeterminateSmall
                                             animated:YES];
            [MusicPlaybackController internetProblemSpinnerOnScreen:YES];
        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
                [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:NO];
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
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:NO];
            [MRProgressOverlayView showOverlayAddedTo:playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
            [MusicPlaybackController simpleSpinnerOnScreen:YES];

        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
                [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:NO];
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
            [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:NO];
            [MRProgressOverlayView showOverlayAddedTo:playerView title:@"Song requires WiFi" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
            [MusicPlaybackController spinnerForWifiNeededOnScreen:YES];
            
        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
                [MRProgressOverlayView dismissAllOverlaysForView:playerView animated:NO];
                [MRProgressOverlayView showOverlayAddedTo:playerView title:@"Song requires WiFi" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
                [MusicPlaybackController spinnerForWifiNeededOnScreen:YES];
            });
        }
    }
}

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
}

/*Not actually needed now since this class is in existance the entire time, it is never deallocated.
- (void)deregisterForObservers
{
 //set crashlytics debug mode on
    @try{
        [self removeObserver:self forKeyPath:@"currentItem.playbackBufferEmpty"];
    }
    //do nothing, obviously it wasn't attached because an exception was thrown
    @catch(id anException){}
 //set debug mode off
}
*/

//CURRENT_SONG_STOPPED_PLAYBACK
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(context == mloadedTimeRanges || context == mPlaybackBufferEmpty){
        NSArray * timeRanges = self.currentItem.loadedTimeRanges;
        if (timeRanges && [timeRanges count]){
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            NSUInteger newSecondsBuff = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
            NSUInteger totalSeconds = [[MusicPlaybackController nowPlayingSong].duration integerValue];
            
            if(context == mPlaybackBufferEmpty){
                BOOL explicitlyPaused = [MusicPlaybackController playbackExplicitlyPaused];
                if(newSecondsBuff == secondsLoaded && secondsLoaded != totalSeconds && !explicitlyPaused){
                    NSLog(@"In stall");
                    stallHasOccured = YES;
                    [MusicPlaybackController setPlayerInStall:YES];
                    [MusicPlaybackController pausePlayback];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_STOPPED_PLAYBACK
                                                                        object:nil];
                    //let this method figure out which spinner to show
                    [self connectionStateChanged];
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
                        [self showSpinnerForBasicLoading];
                    }
                    
                } else if(newSecondsBuff > secondsLoaded && stallHasOccured){
                    NSLog(@"left stall");
                    stallHasOccured = NO;
                    [MusicPlaybackController setPlayerInStall:NO];
                    [self dismissAllSpinners];
                    if(! [MusicPlaybackController playbackExplicitlyPaused])
                        [MusicPlaybackController resumePlayback];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_SONG_RESUMED_PLAYBACK
                                                                        object:nil];
                }
                secondsLoaded = newSecondsBuff;
            }
        }
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
