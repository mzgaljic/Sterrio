//
//  MusicPlaybackController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicPlaybackController.h"
static MyAVPlayer *player = nil;
static PlayerView *playerView = nil;
static MZPlaybackQueue *playbackQueue = nil;
static NowPlayingSong *nowPlayingObject;
static BOOL explicitlyPausePlayback = NO;
static BOOL simpleSpinnerOnScreen = NO;
static BOOL spinnerForWifiNeededOnScreen = NO;
static BOOL internetConnectionSpinnerOnScreen = NO;
static BOOL isPlayerStalled = NO;
static int numLongSongsSkipped = 0;
static id timeObserver;  //watching AVPlayer...for SongPlayerVC

@implementation MusicPlaybackController

+ (void)resumePlayback
{
    if([NSThread mainThread]){
        [player play];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [MusicPlaybackController resumePlayback];
        });
    }
}

/** Playback will be paused immediately */
+ (void)pausePlayback
{
    if([NSThread mainThread]){
        [player pause];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [MusicPlaybackController pausePlayback];
        });
    }
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack
{
    if([NSThread mainThread]){
        
        NSString *playerVcNotifString = @"PlaybackStartedNotification";
        if([AppEnvironmentConstants playbackRepeatType] == PLABACK_REPEAT_MODE_Song){
            [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
            [MusicPlaybackController resumePlayback];
            [[NSNotificationCenter defaultCenter] postNotificationName:playerVcNotifString
                                                                object:nil];
            return;
        }
        
        if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more songs in queue
            [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
            Song *skippedSong = [MusicPlaybackController nowPlayingSong];
            MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
            [player allowSongDidFinishNotificationToProceed:YES];
            Song *nextSong = [playbackQueue skipForward];
            [VideoPlayerWrapper startPlaybackOfSong:nextSong goingForward:YES oldSong:skippedSong];
        } else{
            //last song in queue reached
            if([AppEnvironmentConstants playbackRepeatType] == PLABACK_REPEAT_MODE_All)
                [MusicPlaybackController repeatEntireMainQueue];
        }
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [MusicPlaybackController skipToNextTrack];
        });
    }
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
    if([NSThread mainThread]){
        if(! [MusicPlaybackController shouldSeekToStartOnBackPress]){
            [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
            Song *oldNowPlaying = [MusicPlaybackController nowPlayingSong];
            Song *previousSong = [playbackQueue skipToPrevious];
            [VideoPlayerWrapper startPlaybackOfSong:previousSong
                                       goingForward:NO
                                            oldSong:oldNowPlaying];
        } else{
            [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
            [MusicPlaybackController resumePlayback];
            [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                                object:nil];
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlaying];
        }
        
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [MusicPlaybackController returnToPreviousTrack];
        });
    }
}

+ (BOOL)shouldSeekToStartOnBackPress
{
    short boundary = MZSkipToSongBeginningIfBackBtnTappedBoundary;
    if(player.secondsLoaded == 0
       || ([self playerElapsedTime] <= boundary && [[NowPlayingSong sharedInstance] nowPlaying] != nil)
       || (isnan([self playerElapsedTime]) && [[NowPlayingSong sharedInstance] nowPlaying] == nil)){
        return NO;
    } else
        return YES;
}

+ (NSUInteger)playerElapsedTime
{
    return CMTimeGetSeconds(player.currentItem.currentTime);
}

+ (void)songAboutToBeDeleted:(Song *)song deletionContext:(PlaybackContext *)aContext;
{
    if([nowPlayingObject isEqualToSong:song compareWithContext:aContext])
        [MusicPlaybackController skipToNextTrack];
}

+ (void)groupOfSongsAboutToBeDeleted:(NSArray *)songs deletionContext:(PlaybackContext *)context;
{
    
    for(Song *someSong in songs){
        if([nowPlayingObject isEqualToSong:someSong compareWithContext:context]){
            [MusicPlaybackController skipToNextTrack];
            return;
        }
    }
}

#pragma mark - Gathering playback info
+ (NSUInteger)numMoreSongsInQueue
{
    NSUInteger upNextSongCount = [[MZPlaybackQueue sharedInstance] numMoreSongsInUpNext];
    NSUInteger mainQueueSongCount = [[MZPlaybackQueue sharedInstance] numMoreSongsInMainQueue];
    return upNextSongCount + mainQueueSongCount;
}

//does NOT perform a context comparison.
+ (BOOL)isSongLastInQueue:(Song *)song
{
    NSUInteger upNextSongCount = [[MZPlaybackQueue sharedInstance] numMoreSongsInUpNext];
    NSUInteger mainQueueSongCount = [[MZPlaybackQueue sharedInstance] numMoreSongsInMainQueue];
    if(upNextSongCount == 0 && mainQueueSongCount == 0){
        if([[nowPlayingObject nowPlaying].song_id isEqualToString:song.song_id])
            return YES;
    }
    return NO;
}

//only need to worry about main queue...can never go backwards in upnext songs anyway.
+ (BOOL)isSongFirstInQueue:(Song *)song
{
    if([playbackQueue numSongsInEntireMainQueue] == [playbackQueue numMoreSongsInMainQueue]+1){
        if([[nowPlayingObject nowPlaying].song_id isEqualToString:song.song_id])
            return YES;
    }
    return NO;
}


+ (NSString *)prettyPrintNavBarTitle
{
    if([nowPlayingObject nowPlaying] == nil)
        return @"";
    if([nowPlayingObject isFromPlayNextSongs]){
        NSUInteger numMoreSongs = [playbackQueue numMoreSongsInUpNext];
        if(numMoreSongs == 0)
            return @"Last Queued Song";
        else if(numMoreSongs == 1)
            return @"1 Song Queued";
        else
            return [NSString stringWithFormat:@"%lu Songs Queued", (unsigned long)numMoreSongs];
    }
    else{
        NSUInteger mainQueueSongsPlayed = [playbackQueue numSongsInEntireMainQueue] - [playbackQueue numMoreSongsInMainQueue];
        return [NSString stringWithFormat:@"%lu of %lu", (unsigned long)mainQueueSongsPlayed,
                                                        (unsigned long)[playbackQueue numSongsInEntireMainQueue]];
    }
}

#pragma mark - Now Playing Song
+ (Song *)nowPlayingSong
{
    return [[NowPlayingSong sharedInstance] nowPlaying];
}

+ (NowPlayingSong *)nowPlayingSongObject
{
    return nowPlayingObject;
}

+ (void)newQueueWithSong:(Song *)song
             withContext:(PlaybackContext *)aContext;
{
    Song *originalSong = [MusicPlaybackController nowPlayingSong];
    BOOL playerEnabled = [SongPlayerCoordinator isPlayerEnabled];
    BOOL playerOnScreen = [SongPlayerCoordinator isPlayerOnScreen];
    
    //selected song is already playing...
    if([nowPlayingObject isEqualToSong:song compareWithContext:aContext]
       && playerEnabled
       && playerOnScreen){
        //ignore new queue request. (SongPlayerViewController will will be unaffected by this...)
        return;
    }
    //purposely not deleting "playing next" here...it should remain intact.
    //queue will update the now playing song
    if(playbackQueue == nil)
        playbackQueue = [MZPlaybackQueue sharedInstance];
    [playbackQueue setMainQueueWithNewNowPlayingSong:song inContext:aContext];
    
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    if(nowPlayingObject == nil)
        nowPlayingObject = nowPlaying;
    
    //start playback with the song that was chosen
    [VideoPlayerWrapper startPlaybackOfSong:song goingForward:YES oldSong:originalSong];
}

+ (void)queueUpNextSongsWithContexts:(NSArray *)contexts
{
    if(contexts.count > 0){
        NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
        if(nowPlayingObject == nil)
            nowPlayingObject = nowPlaying;
        
        if(playbackQueue == nil)
            playbackQueue = [MZPlaybackQueue sharedInstance];
        //playbackQueue will start playback if no songs were playing prior to the songs being queued.
        [playbackQueue addSongsToPlayingNextWithContexts:contexts];
    }
}

+ (void)repeatEntireMainQueue
{
    Song *originalSong = [MusicPlaybackController nowPlayingSong];
    Song *firstSong = [[MZPlaybackQueue sharedInstance] skipToBeginningOfQueueReshufflingIfNeeded];
    [VideoPlayerWrapper startPlaybackOfSong:firstSong goingForward:YES oldSong:originalSong];
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
+ (void)updateLockScreenInfoAndArtForSong:(Song *)song
{
    if(song == nil){
        //this happens when a new queue has to be built and the MyAVPlayer class detects a change in
        // players currentItem...
        return;
    }
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter){
        Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        
        UIImage *albumArtImage = [AlbumArtUtilities albumArtFileNameToUiImage:nowPlayingSong.albumArtFileName];
        if(albumArtImage == nil){
            //song has no album art, check if its album does
            Album *songsAlbum = song.album;
            if(songsAlbum){
                albumArtImage = [AlbumArtUtilities albumArtFileNameToUiImage:songsAlbum.albumArtFileName];
            }
        }
        
        if(albumArtImage != nil){
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: albumArtImage];
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        }
        
        if(nowPlayingSong.songName)
        [   songInfo setObject:nowPlayingSong.songName forKey:MPMediaItemPropertyTitle];
        
        if(nowPlayingSong.artist.artistName != nil)
            [songInfo setObject:nowPlayingSong.artist.artistName forKey:MPMediaItemPropertyArtist];
        if(nowPlayingSong.album.albumName != nil)
            [songInfo setObject:nowPlayingSong.album.albumName forKey:MPMediaItemPropertyAlbumTitle];
        
        //giving hints to user if song stopped due to wifi being lost
        if(player.rate == 0 && [SongPlayerCoordinator isPlayerInDisabledState]){
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

//helper method for songArrayGivenSong: album: artist: playlist: method.
+ (NSArray *)arrayOfAllSongsInSongTab
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [CoreDataManager context];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor;
    if([AppEnvironmentConstants smartAlphabeticalSort])
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    else
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
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
+ (void)longVideoSkippedOnCellularConnection
{
    numLongSongsSkipped++;
}

+ (int)numLongVideosSkippedOnCellularConnection
{
    return numLongSongsSkipped;
}

+ (void)resetNumberOfLongVideosSkippedOnCellularConnection
{
    numLongSongsSkipped = 0;
}

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