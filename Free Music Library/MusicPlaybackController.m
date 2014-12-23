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

+ (void)songAboutToBeDeleted
{
    [player pause];
    
    if([MusicPlaybackController playbackQueue].listOfPlayedSongsNowPlayingExclusive.count > 0){  //more items to play
        [self skipToNextTrack];
    } else{
        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
    }
}

/** Playback will continue from the specified seek point, skipping a portion of the track. */
+ (void)seekToTime
{
    #warning no implementation
}

/** Stop playback of current song/track, and begin playback of the next track */
+ (void)skipToNextTrack
{
    Song *nextSong = [[MusicPlaybackController playbackQueue] skipForward];
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:nextSong];
    [player startPlaybackOfSong:nextSong goingForward:YES];
    //NOTE: YTVideoAvPlayer will automatically skip more songs if they cant be played
}

/** Stop playback of current song/track, and begin playback of previous track */
+ (void)returnToPreviousTrack
{
    Song *previousSong = [[MusicPlaybackController playbackQueue] skipToPrevious];
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:previousSong];
    [player startPlaybackOfSong:previousSong goingForward:NO];
    //NOTE: YTVideoAvPlayer will automatically rewind further back in the queue if some songs cant be played
}

/** Current elapsed playback time (for the current song/track). */
+ (void)currentTime
{
    #warning no implementation
}

#pragma mark - Gathering playback info
+ (NSArray *)listOfUpcomingSongsInQueue
{
    return [[MusicPlaybackController playbackQueue] listOfUpcomingSongsNowPlayingExclusive];
}

+ (NSUInteger)numSongsInQueue
{
    return [[MusicPlaybackController playbackQueue] numSongsInQueue];
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
    if(skipNow){
        [[MusicPlaybackController playbackQueue] clearQueue];
        [MusicPlaybackController pausePlayback];  //current song should be skipped! ...stop playback
    }
    NSArray *songsForQueue = [MusicPlaybackController songArrayGivenSong:song album:album artist:artist playlist:playlist genreCode:code];
    [playbackQueue setNowPlayingIndexWithSong:song];
    [[MusicPlaybackController playbackQueue] insertSongsAfterNowPlaying:songsForQueue];
    
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
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
        NSURL *url = [AlbumArtUtilities albumArtFileNameToNSURL:nowPlayingSong.albumArtFileName];
        
        // do something with image
        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
        if (playingInfoCenter) {
            NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
            
            UIImage *albumArtImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            if(albumArtImage != nil){
                MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: albumArtImage];
                [songInfo setObject:nowPlayingSong.songName forKey:MPMediaItemPropertyTitle];
                if(nowPlayingSong.artist.artistName != nil)
                    [songInfo setObject:nowPlayingSong.artist.artistName forKey:MPMediaItemPropertyArtist];
                if(nowPlayingSong.album.albumName != nil)
                    [songInfo setObject:nowPlayingSong.album.albumName forKey:MPMediaItemPropertyAlbumTitle];
                [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
            }
        }
        
    });
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
    NSMutableArray *songArray = nil;
    
    #warning unfinished
    //song tapped in song tab
    if(!album && !artist && !playlist && [GenreConstants noGenreSelectedGenreCode]){
        //add all songs from song tab, set now playing
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

@end