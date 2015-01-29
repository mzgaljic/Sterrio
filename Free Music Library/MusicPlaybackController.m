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
static BOOL explicitlyPausePlayback = NO;
static BOOL initialized = NO;
static BOOL internetProblemLoadingSong = NO;
static BOOL simpleSpinnerOnScreen = NO;
static BOOL internetConnectionSpinnerOnScreen = NO;
static int numLongSongsSkipped = 0;

@implementation MusicPlaybackController

+ (void)resumePlayback
{
    [player play];
}

/** Playback will be paused immediately */
+ (void)pausePlayback
{
    [player pause];
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack
{
    Song *nextSong = [[MusicPlaybackController playbackQueue] skipForward];
    [player startPlaybackOfSong:nextSong goingForward:YES];
    //NOTE: YTVideoAvPlayer will automatically skip more songs if they cant be played
}

/* Used to jump ahead or back in a video to an exact point. The player playback state
 (playing or paused) remains unaffected. */
+ (void)seekToVideoSecond:(NSNumber *)numAsSecond
{
    Song *currentSong = [MusicPlaybackController nowPlayingSong];
    if([currentSong.duration integerValue] < [numAsSecond integerValue])
        //setting to second before end to be safe
        numAsSecond = [NSNumber numberWithInteger:[currentSong.duration integerValue] -1];
    
    AVPlayer *player = [self obtainRawAVPlayer];
    Float64 seconds = [numAsSecond floatValue];
    CMTime targetTime = CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC);
    [player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)returnToPreviousTrack
{
    Song *previousSong = [[MusicPlaybackController playbackQueue] skipToPrevious];
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:previousSong];
    
    [player startPlaybackOfSong:previousSong goingForward:NO];
    //NOTE: YTVideoAvPlayer will automatically rewind further back in the queue if some songs cant be played
}

+ (void)songAboutToBeDeleted:(Song *)song;
{
    if([[MusicPlaybackController playbackQueue] isSongInQueue:song]){
        if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more items to play
            if([[MusicPlaybackController nowPlayingSong].song_id isEqual:song.song_id])
                [self skipToNextTrack];
        }
        else{
            if([self isSongLastInQueue:song] && [[self nowPlayingSong].song_id isEqual: song.song_id]){
                [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
                [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
                if([MusicPlaybackController sizeOfEntireQueue] > 0)
                    [[MusicPlaybackController playbackQueue] skipToPrevious];
            }
        }
        
        [[MusicPlaybackController playbackQueue] removeSongFromQueue:song];
        
        [MusicPlaybackController printQueueContents];
    }
}

+ (void)groupOfSongsAboutToBeDeleted:(NSArray *)songs
{
    BOOL willNeedToAdvanceInQueue = NO;
    BOOL shouldMoveBackwardAndPause = NO;
    for(Song *aSong in songs){
        if([[MusicPlaybackController playbackQueue] isSongInQueue:aSong]){
            
            if([MusicPlaybackController numMoreSongsInQueue] > 0){  //more items to play
                if([[MusicPlaybackController nowPlayingSong].song_id isEqual:aSong.song_id]){
                    willNeedToAdvanceInQueue = YES;
                    [MusicPlaybackController pausePlayback];
                    [MusicPlaybackController explicitlyPausePlayback:YES];
                }
            }
            else{
                //both cant be true! lol
                if(willNeedToAdvanceInQueue == NO)
                    shouldMoveBackwardAndPause = YES;
            }
        }
        [[MusicPlaybackController playbackQueue] removeSongFromQueue:aSong];
    }
    //need to advance in queue AND it is save to do so
    if(willNeedToAdvanceInQueue && [MusicPlaybackController sizeOfEntireQueue] > 0)
        [self skipToNextTrack];
    else if(shouldMoveBackwardAndPause){
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
        [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
        if([MusicPlaybackController sizeOfEntireQueue] > 0)
            [[MusicPlaybackController playbackQueue] skipToPrevious];
    } else{
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
        [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
        if([MusicPlaybackController sizeOfEntireQueue] > 0)
            [[MusicPlaybackController playbackQueue] skipToPrevious];
    }
    
    [MusicPlaybackController printQueueContents];
}

+ (void)declareInternetProblemWhenLoadingSong:(BOOL)declare
{
    internetProblemLoadingSong = declare;
}

+ (BOOL)didPlaybackStopDueToInternetProblemLoadingSong
{
    return internetProblemLoadingSong;
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

+ (void)newQueueWithSong:(Song *)song
                   album:(Album *)album
                  artist:(Artist *)artist
                playlist:(Playlist *)playlist
               genreCode:(int)code
         skipCurrentSong:(BOOL)skipNow;
{
    BOOL playerEnabled = [[SongPlayerCoordinator sharedInstance] isPlayerEnabled];
    
    //selected song is already playing...
    if([[MusicPlaybackController nowPlayingSong].song_id isEqual:song.song_id] && playerEnabled){
        //ignore new queue request, SongPlayerViewController will will be unaffected by this...
        return;
    }
    
    if(skipNow){
        [[MusicPlaybackController playbackQueue] clearQueue];
        //current song should be skipped! ...stopping playback
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
        //if the above line crashes, just pause the player instead.
    }
    NSArray *songsForQueue = [MusicPlaybackController songArrayGivenSong:song album:album artist:artist playlist:playlist genreCode:code];
    [[MusicPlaybackController playbackQueue] insertSongsAfterNowPlaying:songsForQueue];
    [playbackQueue setNowPlayingIndexWithSong:song];
    
    //start playback with the song that was tapped
    [player startPlaybackOfSong:song goingForward:YES];
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
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 360:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 720:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            if(url == nil)
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
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter){
        Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        
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
        NSInteger duration = [nowPlayingSong.duration integerValue];
        [songInfo setObject:[NSNumber numberWithInteger:duration]
                     forKey:MPMediaItemPropertyPlaybackDuration];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }

}

#pragma mark - Heavy lifting of figuring out which songs go into a new queue
+ (NSArray *)songArrayGivenSong:(Song *)song
                          album:(Album *)album
                         artist:(Artist *)artist
                       playlist:(Playlist *)playlist
                      genreCode:(int)code
{
    if(song == nil)
        return nil;
    NSArray *songArray = nil;
    
    #warning unfinished
    //song tapped in song tab
    if(!album && !artist && !playlist && code == [GenreConstants noGenreSelectedGenreCode]){
        songArray = [MusicPlaybackController arrayOfAllSongsInSongTab];
        /*
         code in this comment would be useful if i wanted to only add songs after the current one
        NSUInteger songIndex = [allSongs indexOfObject:song];
        songArray = [[MusicPlaybackController arrayOfAllSongsInSongTab] subarrayWithRange:NSMakeRange(songIndex, allSongs.count-songIndex)];
         */
        
    }
    //a standalone song was tapped in the artist tab (song not part of an album but has an artist)
    else if(artist && !album){
        
    }
    //a song was tapped in an album (doesnt matter if its from the album tab or an album from an artist)
    else if(album && !artist){
        //albumSongs is nsset, not nsorderedset
    }
    //a song was tapped in a playlist
    else if(playlist){
        songArray = [NSMutableArray arrayWithArray:[playlist.playlistSongs array]];
    }
    //a song from the genre tab was tapped (in a genre category)
    else if(code != [GenreConstants noGenreSelectedGenreCode]){
        
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
    if(onScreen)
        internetConnectionSpinnerOnScreen = NO;
    else
        [MusicPlaybackController noSpinnersOnScreen];
}
+ (void)internetProblemSpinnerOnScreen:(BOOL)onScreen
{
    internetConnectionSpinnerOnScreen = onScreen;
    if(onScreen)
        simpleSpinnerOnScreen = NO;
    else
        [MusicPlaybackController noSpinnersOnScreen];
}
+ (void)noSpinnersOnScreen
{
    simpleSpinnerOnScreen = NO;
    internetConnectionSpinnerOnScreen = NO;
}
+ (BOOL)isSimpleSpinnerOnScreen
{
    return simpleSpinnerOnScreen;
}

+ (BOOL)isInternetProblemSpinnerOnScreen
{
    return internetConnectionSpinnerOnScreen;
}
+ (BOOL)isSpinnerOnScreen
{
    return (internetConnectionSpinnerOnScreen || simpleSpinnerOnScreen) ? YES : NO;
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