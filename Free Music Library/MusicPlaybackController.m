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
static PlaybackQueue *playbackQueue = nil;  //DO NOT access directly! getter below
static NowPlaying *nowPlayingObject;
static BOOL explicitlyPausePlayback = NO;
static BOOL initialized = NO;
static BOOL simpleSpinnerOnScreen = NO;
static BOOL spinnerForWifiNeededOnScreen = NO;
static BOOL internetConnectionSpinnerOnScreen = NO;
static BOOL isPlayerStalled = NO;
static int numLongSongsSkipped = 0;

@implementation MusicPlaybackController

+ (void)resumePlayback
{
    if([NSThread mainThread]){
        [player play];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [player play];
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
            [player pause];
        });
    }
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack
{
    if([NSThread mainThread]){
        Song *skippedSong = [MusicPlaybackController nowPlayingSong];
        Song *nextSong = [[MusicPlaybackController playbackQueue] skipForward];
        nowPlayingObject.nowPlaying = nextSong;
        [player startPlaybackOfSong:nextSong goingForward:YES oldSong:skippedSong];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            
            Song *skippedSong = [MusicPlaybackController nowPlayingSong];
            Song *nextSong = [[MusicPlaybackController playbackQueue] skipForward];
            nowPlayingObject.nowPlaying = nextSong;
            [player startPlaybackOfSong:nextSong goingForward:YES oldSong:skippedSong];
        });
    }

    //NOTE: YTVideoAvPlayer will automatically skip more songs if they cant be played
}

/* Used to jump ahead or back in a video to an exact point. The player playback state
 (playing or paused) remains unaffected. */
+ (void)seekToVideoSecond:(NSNumber *)numAsSecond
{
    if([NSThread mainThread]){
        Song *currentSong = [MusicPlaybackController nowPlayingSong];
        if([currentSong.duration integerValue] < [numAsSecond integerValue])
            //setting to second before end to be safe
            numAsSecond = [NSNumber numberWithInteger:[currentSong.duration integerValue] -1];
        
        AVPlayer *player = [self obtainRawAVPlayer];
        Float64 seconds = [numAsSecond floatValue];
        CMTime targetTime = CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC);
        [player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    } else{
        __block NSNumber* numAsSecondBlock = numAsSecond;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            Song *currentSong = [MusicPlaybackController nowPlayingSong];
            if([currentSong.duration integerValue] < [numAsSecond integerValue])
                //setting to second before end to be safe
                numAsSecondBlock = [NSNumber numberWithInteger:[currentSong.duration integerValue] -1];
            
            AVPlayer *player = [self obtainRawAVPlayer];
            Float64 seconds = [numAsSecondBlock floatValue];
            CMTime targetTime = CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC);
            [player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        });
    }
}

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)returnToPreviousTrack
{
    if([NSThread mainThread]){
        Song *skippedSong = [MusicPlaybackController nowPlayingSong];
        Song *previousSong = [[MusicPlaybackController playbackQueue] skipToPrevious];
        nowPlayingObject.nowPlaying = previousSong;
        [player startPlaybackOfSong:previousSong goingForward:NO oldSong:skippedSong];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            Song *skippedSong = [MusicPlaybackController nowPlayingSong];
            Song *previousSong = [[MusicPlaybackController playbackQueue] skipToPrevious];
            nowPlayingObject.nowPlaying = previousSong;
            [player startPlaybackOfSong:previousSong goingForward:NO oldSong:skippedSong];
        });
    }

    //NOTE: YTVideoAvPlayer will automatically rewind further back in the queue if some songs cant be played
}

+ (void)songAboutToBeDeleted:(Song *)song deletionContext:(SongPlaybackContext)context
{
    if([[MusicPlaybackController playbackQueue] isSongInQueue:song]
       && [MusicPlaybackController nowPlayingSongObject].context == context){
        //song is ACTUALLY in the queue
        if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more items to play
            if([[MusicPlaybackController nowPlayingSongObject].nowPlaying.song_id isEqual:song.song_id]
               && [MusicPlaybackController nowPlayingSongObject].context == context)
                [self skipToNextTrack];
        }
        else{
            if([self isSongLastInQueue:song] && [[self nowPlayingSong].song_id isEqual: song.song_id]
               && [MusicPlaybackController nowPlayingSongObject].context == context){
                [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
                [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
                if([MusicPlaybackController sizeOfEntireQueue] > 0)
                    [[MusicPlaybackController playbackQueue] skipToPrevious];
            }
        }
        
        [[MusicPlaybackController playbackQueue] removeSongFromQueue:song];
        
        [MusicPlaybackController printQueueContents];
    } else if([[MusicPlaybackController playbackQueue] isSongInQueue:song]){
        //song isnt actually in the same queue (ie: different contexts)...
        if([[self nowPlayingSong].song_id isEqual: song.song_id]){
            //however it is the same actual song object playing.
            //should kill player if the current playing context is a playlist.
            if([MusicPlaybackController nowPlayingSongObject].context == SongPlaybackContextPlaylists){
                if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more items to play
                    [self skipToNextTrack];
                }
                else if([self isSongLastInQueue:song]){
                    [MusicPlaybackController pausePlayback];
                    [MusicPlaybackController explicitlyPausePlayback:YES];
                    [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
                    [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
                    if([MusicPlaybackController sizeOfEntireQueue] > 0)
                        [[MusicPlaybackController playbackQueue] skipToPrevious];
                }
            }
        }
    }
}

+ (void)groupOfSongsAboutToBeDeleted:(NSArray *)songs deletionContext:(SongPlaybackContext)context
{
    BOOL willNeedToAdvanceInQueue = NO;
    BOOL shouldMoveBackwardAndPause = NO;
    //this becomes true ONLY if the current song shares the same context
    BOOL removedSongsFromQueue = NO;
    for(Song *aSong in songs){
        BOOL songIsInCurrentQueue = [[MusicPlaybackController playbackQueue] isSongInQueue:aSong];
        //song cant really be in the current queue if the contexts arent the same
        if([MusicPlaybackController nowPlayingSongObject].context != context)
            songIsInCurrentQueue = NO;
        if(songIsInCurrentQueue){
            
            if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more items to play
                if([[MusicPlaybackController nowPlayingSong].song_id isEqual:aSong.song_id]
                   && [MusicPlaybackController nowPlayingSongObject].context == context){
                    willNeedToAdvanceInQueue = YES;
                    [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
                }
            }
            else{
                //both cant be true! lol
                if(willNeedToAdvanceInQueue == NO)
                    shouldMoveBackwardAndPause = YES;
            }
            [[MusicPlaybackController playbackQueue] removeSongFromQueue:aSong];
            removedSongsFromQueue = YES;
        }
    }
    
    //need to advance in queue AND it is safe to do so
    if(willNeedToAdvanceInQueue && [MusicPlaybackController sizeOfEntireQueue] > 0)
        [self skipToNextTrack];
    else if(shouldMoveBackwardAndPause){
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
        [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
        if([MusicPlaybackController sizeOfEntireQueue] > 0)
            [[MusicPlaybackController playbackQueue] skipToPrevious];
    } else if(removedSongsFromQueue){
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
        [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
        if([MusicPlaybackController sizeOfEntireQueue] > 0)
            [[MusicPlaybackController playbackQueue] skipToPrevious];
    }
    
    [MusicPlaybackController printQueueContents];
}

#pragma mark - Gathering playback info
+ (NSArray *)listOfUpcomingSongsInQueue
{
    return [[MusicPlaybackController playbackQueue] listOfUpcomingSongsNowPlayingExclusive];
}

+ (NSUInteger)numMoreSongsInQueue
{
    return [[MusicPlaybackController playbackQueue] numMoreSongsInQueue];
}

+ (BOOL)isSongLastInQueue:(Song *)song
{
    NSArray *array = [[MusicPlaybackController playbackQueue] listOfUpcomingSongsNowPlayingInclusive];
    Song *comparisonSong = array[array.count-1];
    return ([comparisonSong.song_id isEqual:song.song_id]) ? YES : NO;
}

+ (BOOL)isSongFirstInQueue:(Song *)song
{
    NSArray *array = [[MusicPlaybackController playbackQueue] listOfPlayedSongsNowPlayingInclusive];
    Song *comparisonSong = array[0];
    return ([comparisonSong.song_id isEqual:song.song_id]) ? YES : NO;
}

//private method
+ (NSUInteger)sizeOfEntireQueue
{
    return [[MusicPlaybackController playbackQueue] sizeOfEntireQueue];
}

//private method
+ (NSUInteger)indexOfNowPlaying
{
    return [[MusicPlaybackController playbackQueue] nowPlayingIndex];
}

+ (NSString *)prettyPrintNavBarTitle
{
    return [NSString stringWithFormat:@"%d of %d", (int)[MusicPlaybackController indexOfNowPlaying]+1,
                                                    (int)[MusicPlaybackController sizeOfEntireQueue]];
}

#pragma mark - Now Playing Song
+ (Song *)nowPlayingSong
{
    return [[MusicPlaybackController playbackQueue] nowPlaying];
}

+ (NowPlaying *)nowPlayingSongObject
{
    return nowPlayingObject;
}

+ (void)newQueueWithSong:(Song *)song
             withContext:(SongPlaybackContext)context
        optionalPlaylist:(Playlist *)playlist
         skipCurrentSong:(BOOL)skipNow
{
    Song *originalSong = [MusicPlaybackController nowPlayingSong];
    BOOL playerEnabled = [SongPlayerCoordinator isPlayerEnabled];
    BOOL playerOnScreen = [SongPlayerCoordinator isPlayerOnScreen];
#warning check player is paused due to connection issue with youtube. if so, try playing again (make new queue)
    //selected song is already playing...
    if([nowPlayingObject isEqual:song context:context] && playerEnabled && playerOnScreen){
        //ignore new queue request, SongPlayerViewController will will be unaffected by this...
        return;
    }
    
    if(skipNow){
        [[MusicPlaybackController playbackQueue] clearQueue];
        //current song should be skipped! ...stopping playback
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
    }
    NSArray *songsForQueue = [MusicPlaybackController songArrayGivenSong:song
                                                        optionalPlaylist:playlist
                                                             withContext:context];
    [[MusicPlaybackController playbackQueue] insertSongsAfterNowPlaying:songsForQueue];
    [playbackQueue setNowPlayingIndexWithSong:song];
    
    NowPlaying *nowPlaying = [NowPlaying sharedInstance];
    if(nowPlayingObject == nil)
        nowPlayingObject = nowPlaying;
    [nowPlaying setNewNowPlayingSong:song WithContext:context];
    
    //start playback with the song that was tapped
    [player startPlaybackOfSong:song goingForward:YES oldSong:originalSong];
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
    switch (maxDesiredQuality) {
        case 240:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            if(url != nil)
                return url;
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 360:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            if(url != nil)
                return url;
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 720:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            if(url != nil)
                return url;
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            break;
        }
        default:
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            break;
    }
    return url;
}

#pragma mark - Helper methods
+ (PlaybackQueue *)playbackQueue
{
    if(!initialized){
        playbackQueue = [[PlaybackQueue alloc] init];
        initialized = YES;
    }
    return playbackQueue;
}

+ (void)setRawAVPlayer:(AVPlayer *)myAvPlayer
{
    player = (MyAVPlayer *)myAvPlayer;
}
+ (AVPlayer *)obtainRawAVPlayer
{
    return player;
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
    NSLog(@"updating lock screen");
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
        
        [songInfo setObject:nowPlayingSong.songName forKey:MPMediaItemPropertyTitle];
        
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
                  && !player.playbackStarted){
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


#pragma mark - Heavy lifting of figuring out which songs go into a new queue
+ (NSArray *)songArrayGivenSong:(Song *)song optionalPlaylist:(Playlist *)playlist withContext:(SongPlaybackContext)context
{
    if(song == nil)
        return nil;
    NSArray *songArray = nil;
    
    #warning unfinished
    if(context == SongPlaybackContextSongs){
        songArray = [MusicPlaybackController arrayOfAllSongsInSongTab];
        /*
         code in this comment would be useful if i wanted to only add songs after the current one
        NSUInteger songIndex = [allSongs indexOfObject:song];
        songArray = [[MusicPlaybackController arrayOfAllSongsInSongTab] subarrayWithRange:NSMakeRange(songIndex, allSongs.count-songIndex)];
         */
    }
    //a standalone song was tapped in the artist tab (song not part of an album but has an artist)
    else if(context == SongPlaybackContextArtists){
        
    }
    //a song was tapped in an album (doesnt matter if its from the album tab or an album from an artist)
    else if(context == SongPlaybackContextAlbums){
        //albumSongs is nsset, not nsorderedset
    }
    //a song was tapped in a playlist
    else if(context == SongPlaybackContextPlaylists){
        songArray = [NSMutableArray arrayWithArray:[playlist.playlistSongs array]];
    }
    
    return songArray;
}

//helper method for songArrayGivenSong: album: artist: playlist: genreCode: method.
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
}

#pragma mark - DEBUG
+ (void)printQueueContents
{
    /*
    NSArray *array = [[MusicPlaybackController playbackQueue] listOfEntireQueueAsArray];
    NSMutableString *output = [NSMutableString stringWithString:@"["];
    Song *aSong = nil;
    for(int i = 0; i < array.count; i++){
        aSong = array[i];
        if(i == 0)
            [output appendFormat:@"%@", aSong.songName];
        else
            [output appendFormat:@",%@", aSong.songName];
    }
    int indexOfNowPlaying = (int)[[MusicPlaybackController playbackQueue] nowPlayingIndex];
    if(indexOfNowPlaying < 0)
        [output appendString:@"]----No song playing\n\n"];
    else
        [output appendFormat:@"]----Now Playing[%i]\n\n", indexOfNowPlaying];
    NSLog(@"%@", output);
     */
}

@end