//
//  MusicPlaybackController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicPlaybackController.h"
#import "SongAlbumArt+Utilities.h"
#import "PlayableItem.h"
#import "PlaylistItem.h"
#import "PreviousNowPlayingInfo.h"
#import "MZNewPlaybackQueue.h"

static MyAVPlayer *player = nil;
static PlayerView *playerView = nil;
static NowPlaying *nowPlayingObject;
static BOOL explicitlyPausePlayback = NO;
static BOOL simpleSpinnerOnScreen = NO;
static BOOL spinnerForWifiNeededOnScreen = NO;
static BOOL internetConnectionSpinnerOnScreen = NO;
static BOOL isPlayerStalled = NO;
static id timeObserver;  //watching AVPlayer...for SongPlayerVC

@implementation MusicPlaybackController

+ (void)resumePlayback
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        //Run UI Updates
        [MusicPlaybackController internalResumePlayaback];
    });
}

+ (void)internalResumePlayaback
{
    [player play];
    [playerView playCalled];
}

/** Playback will be paused immediately */
+ (void)pausePlayback
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        //Run UI Updates
        [MusicPlaybackController internalPausePlayback];
    });
}

+ (void)internalPausePlayback
{
    [player pause];
    [playerView pauseCalled];
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack
{
    safeSynchronousDispatchToMainQueue(^{
        //Run UI Updates
        [MusicPlaybackController internalSkipToNextTrack];
    });
}

+ (void)internalSkipToNextTrack
{
    NSString *playerVcNotifString = @"PlaybackStartedNotification";
    if([AppEnvironmentConstants playbackRepeatType] == PLABACK_REPEAT_MODE_Song){
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
        [MusicPlaybackController resumePlayback];
        [[NSNotificationCenter defaultCenter] postNotificationName:playerVcNotifString
                                                            object:nil];
        return;
    }
    
    NSUInteger numMoreSongsInQueue = [MusicPlaybackController numMoreSongsInQueue];
    BOOL allowSongDidFinishNotifToProceed;
    if(numMoreSongsInQueue == 0 && [AppEnvironmentConstants playbackRepeatType] == PLABACK_REPEAT_MODE_All){
        //last song in queue reached.
        [MusicPlaybackController repeatEntireMainQueue];
        return;
    } else if(numMoreSongsInQueue == 0 && [AppEnvironmentConstants playbackRepeatType] == PLABACK_REPEAT_MODE_disabled){
        allowSongDidFinishNotifToProceed = NO;
    } else {
        allowSongDidFinishNotifToProceed = YES;
    }
    
    [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player allowSongDidFinishNotificationToProceed:allowSongDidFinishNotifToProceed];
    PlayableItem *oldItem = [NowPlaying sharedInstance].playableItem;
    Song *nextSong = [[MZNewPlaybackQueue sharedInstance] seekForwardOneItem].songForItem;
    
    [VideoPlayerWrapper startPlaybackOfSong:nextSong
                               goingForward:YES
                            oldPlayableItem:oldItem];
}

//used primarily when killing the player (to override the repeat mode settings)
+ (void)forcefullySkipToNextTrack
{
    safeSynchronousDispatchToMainQueue(^{
        //Run UI Updates
        [MusicPlaybackController internalForcefullySkipToNextTrack];
    });
}

+ (void)internalForcefullySkipToNextTrack
{
    [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player allowSongDidFinishNotificationToProceed:YES];
    PlayableItem *oldItem = [NowPlaying sharedInstance].playableItem;
    Song *nextSong = [[MZNewPlaybackQueue sharedInstance] seekForwardOneItem].songForItem;
    
    [VideoPlayerWrapper startPlaybackOfSong:nextSong
                               goingForward:YES
                            oldPlayableItem:oldItem];
}

/* Used to jump ahead or back in a video to an exact point. The player playback state
 (playing or paused) remains unaffected. */
+ (void)seekToVideoSecond:(NSNumber *)numAsSecond
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(player.secondsLoaded == 0)
        return;
    
    if([NSThread mainThread]){
        Song *currentSong = [MusicPlaybackController nowPlayingSong];
        if([currentSong.duration integerValue] < [numAsSecond integerValue])
            //setting to second before end to be safe
            numAsSecond = [NSNumber numberWithInteger:[currentSong.duration integerValue] -1];
        
        Float64 seconds = [numAsSecond floatValue];
        CMTime targetTime = CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC);
        [player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    } else{
        __block NSNumber* numAsSecondBlock = numAsSecond;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [MusicPlaybackController seekToVideoSecond:numAsSecondBlock];
        });
    }
}

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)returnToPreviousTrack
{
    safeSynchronousDispatchToMainQueue(^{
        //Run UI Updates
        [MusicPlaybackController internalReturnToPreviousTrack];
    });
}

+ (void)internalReturnToPreviousTrack
{
    if([MusicPlaybackController shouldSeekToStartOnBackPress]){
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
        [MusicPlaybackController resumePlayback];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                            object:nil];
        
        //update lock screen with small delay so the avplayer has a chance to correct its internal state.
        double delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //code to be executed on the main queue after delay
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlaying sharedInstance].playableItem.songForItem];
        });
    } else{
        [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
        PlayableItem *oldItem = [NowPlaying sharedInstance].playableItem;
        Song *previousSong = [[MZNewPlaybackQueue sharedInstance] seekBackOneItem].songForItem;
        
        [VideoPlayerWrapper startPlaybackOfSong:previousSong
                                   goingForward:NO
                                oldPlayableItem:oldItem];
    }
}

+ (BOOL)shouldSeekToStartOnBackPress
{
    short boundary = MZSkipToSongBeginningIfBackBtnTappedBoundary;
    if(nowPlayingObject.playableItem == nil) {
        //impossible to seek if the current item is null (end of queue?). Go back to prev song.
        return NO;
    } else if(player.secondsLoaded == 0) {
        //don't seek back to start if video didn't start fully streaming yet!
        return NO;
    } else if([self playerElapsedTime] <= boundary) {
        //we only seek back to start if the elapsed time is > boundary.
        return NO;
    } else {
        //otherwise, the playerItem isn't nil, the video began streaming, and we're past the
        //boudnary. Definitely makes sense to seek back to the beginning.
        return YES;
    }
}

+ (NSUInteger)playerElapsedTime
{
    return CMTimeGetSeconds(player.currentItem.currentTime);
}

+ (void)playlistItemAboutToBeDeleted:(PlaylistItem *)item
{
    if([nowPlayingObject.playableItem.playlistItemForItem.uniqueId isEqualToString:item.uniqueId]){
        if([[MZNewPlaybackQueue sharedInstance] forwardItemsCount] == 0){
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [playerView userKilledPlayer];
        } else {
            [MusicPlaybackController forcefullySkipToNextTrack];
        }
    }
}

+ (void)songAboutToBeDeleted:(Song *)song deletionContext:(PlaybackContext *)aContext;
{
    if([nowPlayingObject.playableItem isEqualToSong:song withContext:aContext]){
        if([[MZNewPlaybackQueue sharedInstance] forwardItemsCount] == 0){
            PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
            [playerView userKilledPlayer];
        } else {
            [MusicPlaybackController forcefullySkipToNextTrack];
        }
    }
}

+ (void)groupOfSongsAboutToBeDeleted:(NSArray *)songs deletionContext:(PlaybackContext *)context;
{
    [songs enumerateObjectsUsingBlock:^(Song *someSong, NSUInteger idx, BOOL *stop) {
        if([nowPlayingObject.playableItem isEqualToSong:someSong withContext:context]) {
            if([[MZNewPlaybackQueue sharedInstance] forwardItemsCount] == 0){
                PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
                [playerView userKilledPlayer];
            } else {
                [MusicPlaybackController forcefullySkipToNextTrack];
            }
        }
    }];
}

#pragma mark - Gathering playback info
+ (NSUInteger)numMoreSongsInQueue
{
    return [[MZNewPlaybackQueue sharedInstance] forwardItemsCount];
}

//does NOT perform a context comparison.
+ (BOOL)isSongLastInQueue:(Song *)song
{
    BOOL songIdsMatch = [nowPlayingObject.playableItem.songForItem.uniqueId isEqualToString:song.uniqueId];
    return (songIdsMatch && [[MZNewPlaybackQueue sharedInstance] forwardItemsCount] == 0);
}

//only need to worry about main queue...can never go backwards in upnext songs anyway.
+ (BOOL)isSongFirstInQueue:(Song *)song
{
    BOOL songIdsMatch = [nowPlayingObject.playableItem.songForItem.uniqueId isEqualToString:song.uniqueId];
    MZNewPlaybackQueue *playbackQueue = [MZNewPlaybackQueue sharedInstance];
    return (songIdsMatch && playbackQueue.totalItemsCount == playbackQueue.forwardItemsCount+1);
}


+ (NSString *)prettyPrintNavBarTitle
{
    PlayableItem *currentItem = [MZNewPlaybackQueue sharedInstance].currentItem;
    if(currentItem != nil) {
    }
    return (currentItem == nil) ? @"" : currentItem.contextForItem.queueName;
}

#pragma mark - Now Playing Song
+ (Song *)nowPlayingSong
{
    return [NowPlaying sharedInstance].playableItem.songForItem;
}

+ (NowPlaying *)nowPlayingSongObject
{
    return nowPlayingObject;
}

+ (void)newQueueWithPlaylistItem:(PlaylistItem *)playlistItem withContext:(PlaybackContext *)aContext
{
    BOOL playerEnabled = [SongPlayerCoordinator isPlayerEnabled];
    BOOL playerOnScreen = [SongPlayerCoordinator isPlayerOnScreen];
    
    //selected song is already playing...
    if([nowPlayingObject.playableItem isEqualToPlaylistItem:playlistItem withContext:aContext]
       && playerEnabled
       && playerOnScreen){
        //ignore new queue request. (SongPlayerViewController will will be unaffected by this...)
        return;
    }
    
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    if([playlistItem.song.duration integerValue] >= MZLongestCellularPlayableDuration && [AppEnvironmentConstants limitVideoLengthOnCellular]){
        //videos of this length may only be played on wifi. Are we on wifi?
        if(! [reachability isConnectedToWifi]){
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_Chosen_Song_Too_Long_For_Cellular];
            return;
        }
    }
    
    NowPlaying *nowPlayingObj = [NowPlaying sharedInstance];
    if(nowPlayingObject == nil)
        nowPlayingObject = nowPlayingObj;
    
    PlayableItem *item = [[PlayableItem alloc] initWithPlaylistItem:playlistItem
                                                            context:aContext
                                                    fromUpNextSongs:NO];
    [MZNewPlaybackQueue newInstanceWithNewNowPlayingPlayableItem:item];
    
    PlayableItem *oldItem = [NowPlaying sharedInstance].playableItem;
    [[NowPlaying sharedInstance] setNewPlayableItem:item];
    //start playback in minimzed state
    [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
    [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                               goingForward:YES
                            oldPlayableItem:oldItem];
}

+ (void)newQueueWithSong:(Song *)song
             withContext:(PlaybackContext *)aContext;
{
    BOOL playerEnabled = [SongPlayerCoordinator isPlayerEnabled];
    BOOL playerOnScreen = [SongPlayerCoordinator isPlayerOnScreen];
    
    //selected song is already playing...
    if([nowPlayingObject.playableItem isEqualToSong:song withContext:aContext]
       && playerEnabled
       && playerOnScreen){
        //ignore new queue request. (SongPlayerViewController will will be unaffected by this...)
        return;
    }
    
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    if([song.duration integerValue] >= MZLongestCellularPlayableDuration && [AppEnvironmentConstants limitVideoLengthOnCellular]){
        //videos of this length may only be played on wifi. Are we on wifi?
        if(! [reachability isConnectedToWifi]){
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_Chosen_Song_Too_Long_For_Cellular];
            return;
        }
    }
    
    NowPlaying *nowPlayingObj = [NowPlaying sharedInstance];
    if(nowPlayingObject == nil)
        nowPlayingObject = nowPlayingObj;
    
    PlayableItem *item = [[PlayableItem alloc] initWithSong:song context:aContext fromUpNextSongs:NO];
    [MZNewPlaybackQueue newInstanceWithNewNowPlayingPlayableItem:item];
    
    PlayableItem *oldItem = [NowPlaying sharedInstance].playableItem;
    [[NowPlaying sharedInstance] setNewPlayableItem:item];
    //start playback in minimzed state
    [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
    [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                               goingForward:YES
                            oldPlayableItem:oldItem];
}

+ (void)queueSongsOnTheFlyWithContext:(PlaybackContext *)context
{
    NowPlaying *nowPlaying = [NowPlaying sharedInstance];
    if(nowPlayingObject == nil) {
        nowPlayingObject = nowPlaying;
    }
    
    PlayableItem *oldItem = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading];
    MZNewPlaybackQueue *playbackQueue = [MZNewPlaybackQueue sharedInstance];
    if(! [SongPlayerCoordinator isPlayerOnScreen]){
        //no songs currently playing, set defaults...
        playbackQueue = [MZNewPlaybackQueue newInstanceWithSongsQueuedOnTheFly:context];
        PlayableItem *item = [playbackQueue currentItem];
        
        [[NowPlaying sharedInstance] setNewPlayableItem:item];
        
        //start playback in minimzed state
        [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
        [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                                   goingForward:YES
                                oldPlayableItem:oldItem];
        NSLog(@"%@", playbackQueue);
        return;
    } else {
        //items were already played, player on screen. is playback of queue finished?
        if([playbackQueue forwardItemsCount] == 0) {
            //no more items in queue! is the current item completely finished playing?
            //if so, we can start playback of the new up next items right now!
            
            MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
            Song *nowPlayingSong = [NowPlaying sharedInstance].playableItem.songForItem;
            NSUInteger elapsedSeconds = ceil(CMTimeGetSeconds(player.currentItem.currentTime));
            
            //comparing if song is either done or VERY VERY VERY close to the end.
            if(elapsedSeconds == [nowPlayingSong.duration integerValue]
               || elapsedSeconds +1 == [nowPlayingSong.duration integerValue]){
                //we can start playing the new queue
                [SongPlayerViewDisplayUtility animatePlayerIntoMinimzedModeInPrepForPlayback];
                [playbackQueue queueSongsOnTheFlyWithContext:context];
                PlayableItem *item = [playbackQueue seekForwardOneItem];
                [[NowPlaying sharedInstance] setNewPlayableItem:item];
                
                [VideoPlayerWrapper startPlaybackOfSong:item.songForItem
                                           goingForward:YES
                                        oldPlayableItem:oldItem];
                NSLog(@"%@", playbackQueue);
                return;
            }
        }
        //dont mess with the current item...queue not finished. Just insert new items.
        [playbackQueue queueSongsOnTheFlyWithContext:context];
        NSLog(@"%@", playbackQueue);
    }
}

+ (void)repeatEntireMainQueue
{
    MZNewPlaybackQueue *playbackQueue = [MZNewPlaybackQueue sharedInstance];
    PlayableItem *firstItem = [playbackQueue seekToFirstItemInMainQueueAndReshuffleIfNeeded];
    Song *firstSong = firstItem.songForItem;
    [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
    
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player allowSongDidFinishNotificationToProceed:YES];

    PlayableItem *oldItem = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading];
    [VideoPlayerWrapper startPlaybackOfSong:firstSong
                               goingForward:YES
                            oldPlayableItem:oldItem];
}

#pragma mark - Playback status
+ (BOOL)playbackExplicitlyPaused
{
    return explicitlyPausePlayback;
}

+ (void)explicitlyPausePlayback:(BOOL)pause
{
    explicitlyPausePlayback = pause;
}

#pragma mark - Public helper
+ (NSURL *)closestUrlQualityMatchForSetting:(short)aQualitySetting usingStreamsDictionary:(NSDictionary *)aDictionary
{
    short maxDesiredQuality = aQualitySetting;
    NSDictionary *vidQualityDict = aDictionary;
    NSURL *url;
    NSArray *arrayOfValidQualities = nil;
    
    switch (maxDesiredQuality) {
        case 240:
        {
            arrayOfValidQualities = @[
                                      [NSNumber numberWithInt:36]
                                      ];
            
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            break;
        }
        case 360:
        {
            arrayOfValidQualities = @[
                                      [NSNumber numberWithInt:36],
                                      [NSNumber numberWithInt:18],
                                      [NSNumber numberWithInt:34],
                                      [NSNumber numberWithInt:82],
                                      [NSNumber numberWithInt:133],
                                      [NSNumber numberWithInt:134],
                                      ];
            
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            break;
        }
        case 720:
        {
            arrayOfValidQualities = @[
                                      [NSNumber numberWithInt:18],
                                      [NSNumber numberWithInt:22],
                                      [NSNumber numberWithInt:34],
                                      [NSNumber numberWithInt:35],
                                      [NSNumber numberWithInt:36],
                                      [NSNumber numberWithInt:43],
                                      [NSNumber numberWithInt:44],
                                      [NSNumber numberWithInt:45],
                                      [NSNumber numberWithInt:82],
                                      [NSNumber numberWithInt:83],
                                      [NSNumber numberWithInt:84],
                                      [NSNumber numberWithInt:133],
                                      [NSNumber numberWithInt:134],
                                      [NSNumber numberWithInt:135],
                                      [NSNumber numberWithInt:136],
                                      [NSNumber numberWithInt:298],
                                      ];
            
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            break;
        }
        default:
        {
            break;
        }
    }
    //in case no valid URL was found by this point.
    if(url == nil){
        url = [MusicPlaybackController grabAnyValidUrlFromDict:vidQualityDict arrayOfMaxItagValues:arrayOfValidQualities];
    }
    
    return url;
}

+ (NSURL *)grabAnyValidUrlFromDict:(NSDictionary *)aDictionary arrayOfMaxItagValues:(NSArray *)arrayOfValues
{
    for(int i = 0; i < arrayOfValues.count; i++){
        if(aDictionary[arrayOfValues[i]] != nil)
            return aDictionary[arrayOfValues[i]];
    }
    
    return nil;
}

#pragma mark - Helper methods
+ (void)setRawAVPlayer:(AVPlayer *)myAvPlayer
{
    player = (MyAVPlayer *)myAvPlayer;
}
+ (AVPlayer *)obtainRawAVPlayer
{
    return player;
}

+ (void)setAVPlayerTimeObserver:(id)observer
{
    timeObserver = observer;
}
+ (id)avplayerTimeObserver
{
    return timeObserver;
}

#pragma mark - getters/setters for avplayer and the playerview
+ (void)setRawPlayerView:(PlayerView *)myPlayerView
{
    playerView = myPlayerView;
}

+ (PlayerView *)obtainRawPlayerView
{
    return playerView;
}

#pragma mark - Lock Screen Song Info & Art
+ (void)updateLockScreenInfoAndArtForSong:(Song *)nowPlayingSong
{
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter){
        if(nowPlayingSong == nil){
            //this happens when a new queue has to be built and the MyAVPlayer class detects a change in
            // players currentItem...
            NSDictionary *emptyDict = [NSDictionary dictionary];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:emptyDict];
            return;
        }
        
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        
        UIImage *albumArtImage;
        if(nowPlayingSong.albumArt){
            albumArtImage = [nowPlayingSong.albumArt imageFromImageData];
        }
        
        if(albumArtImage != nil){
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: albumArtImage];
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        }
        
        if(nowPlayingSong.songName)
            [songInfo setObject:nowPlayingSong.songName forKey:MPMediaItemPropertyTitle];
        
        if(nowPlayingSong.artist.artistName != nil)
            [songInfo setObject:nowPlayingSong.artist.artistName forKey:MPMediaItemPropertyArtist];
        if(nowPlayingSong.album.albumName != nil)
            [songInfo setObject:nowPlayingSong.album.albumName forKey:MPMediaItemPropertyAlbumTitle];
        
        float playerRate = player.rate;
        //giving hints to user if song stopped due to wifi being lost
        if(playerRate == 0 && [SongPlayerCoordinator isPlayerInDisabledState]){
            [songInfo setObject:[songInfo objectForKey:MPMediaItemPropertyTitle]
                         forKey:MPMediaItemPropertyAlbumTitle];
            NSString *msg = @"WiFi required for playback...";
            [songInfo setObject:msg forKey:MPMediaItemPropertyTitle];
        } else if([[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue].operationCount > 0
                  && !player.playbackStarted && ![MusicPlaybackController playbackExplicitlyPaused]){
            //mention that new song is buffering to user
            NSString *titleAndMsg =[NSString stringWithFormat:@"Loading: %@", nowPlayingSong.songName];
            [songInfo setObject:titleAndMsg
                         forKey:MPMediaItemPropertyTitle];
        } else if([MusicPlaybackController isPlayerStalled]){
            //mention that new song is buffering to user
            NSString *titleAndMsg =[NSString stringWithFormat:@"Buffering: %@", nowPlayingSong.songName];
            [songInfo setObject:titleAndMsg
                         forKey:MPMediaItemPropertyTitle];
        }
        
        NSInteger duration = [nowPlayingSong.duration integerValue];
        [songInfo setObject:[NSNumber numberWithInteger:duration]
                     forKey:MPMediaItemPropertyPlaybackDuration];
        NSNumber *currentTime;
        if(player.rate == 1 && [SongPlayerCoordinator isPlayerInDisabledState])
            currentTime = player.elapsedTimeBeforeDisabling;
         else
            currentTime =[NSNumber numberWithInteger:CMTimeGetSeconds(player.currentItem.currentTime)];
        
        [songInfo setObject:currentTime
                     forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [songInfo setObject:[NSNumber numberWithFloat:player.rate]
                     forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
}

#pragma mark - loading spinner status
+ (void)simpleSpinnerOnScreen:(BOOL)onScreen
{
    simpleSpinnerOnScreen = onScreen;
    if(onScreen){
        internetConnectionSpinnerOnScreen = NO;
        spinnerForWifiNeededOnScreen = NO;
    }
}
+ (void)internetProblemSpinnerOnScreen:(BOOL)onScreen
{
    internetConnectionSpinnerOnScreen = onScreen;
    if(onScreen){
        simpleSpinnerOnScreen = NO;
        spinnerForWifiNeededOnScreen = NO;
    }
}
+ (void)spinnerForWifiNeededOnScreen:(BOOL)onScreen
{
    spinnerForWifiNeededOnScreen = onScreen;
    if(onScreen){
        simpleSpinnerOnScreen = NO;
        internetConnectionSpinnerOnScreen = NO;
    }
}
+ (void)noSpinnersOnScreen
{
    simpleSpinnerOnScreen = NO;
    internetConnectionSpinnerOnScreen = NO;
    spinnerForWifiNeededOnScreen = NO;
}

+ (BOOL)isSimpleSpinnerOnScreen
{
    return simpleSpinnerOnScreen;
}
+ (BOOL)isSpinnerForWifiNeededOnScreen
{
    return spinnerForWifiNeededOnScreen;
}
+ (BOOL)isInternetProblemSpinnerOnScreen
{
    return internetConnectionSpinnerOnScreen;
}
+ (BOOL)isSpinnerOnScreen
{
    return (internetConnectionSpinnerOnScreen
            || simpleSpinnerOnScreen
            || spinnerForWifiNeededOnScreen) ? YES : NO;
}

+ (NSString *)messageForCurrentSpinner
{
    if(internetConnectionSpinnerOnScreen)
        return @"Connection lost";
    if(simpleSpinnerOnScreen)
        return @"";
    if(spinnerForWifiNeededOnScreen)
        return @"Song requires WiFi";
    return @"";
}

#pragma mark - Dealing with problems
+ (BOOL)isPlayerStalled
{
    return isPlayerStalled;
}

+ (void)setPlayerInStall:(BOOL)stalled
{
    isPlayerStalled = stalled;
    if([SongPlayerCoordinator isVideoPlayerExpanded]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                            object:nil];
    }
}

@end