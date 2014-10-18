//
//  YouTubeMoviePlayerSingleton.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/6/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YouTubeMoviePlayerSingleton.h"

@implementation YouTubeMoviePlayerSingleton
static AVPlayer *player = nil;
static AVPlayerLayer *videoLayer = nil;
static BOOL needsToDisplayNewVideo;

static MPMoviePlayerController *previewMusicYoutubePlayer = nil;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

#pragma mark - Custom AVPlayer powered video player for library
- (void)setAVPlayerInstance:(AVPlayer *)AVPlayerInstance
{
    player = AVPlayerInstance;
}

- (AVPlayer *)AVPlayer;
{
    return player;
}


- (void)setAVPlayerLayerInstance:(AVPlayerLayer *)AVPlayerLayerInstance
{
    videoLayer = AVPlayerLayerInstance;
}

- (AVPlayerLayer *)AVPlayerLayer
{
    return videoLayer;
}


#pragma mark - YouTube video player for previewing songs when adding to library
- (void)setPreviewMusicYouTubePlayerInstance:(MPMoviePlayerController *)MPMoviePlayerControllerInstance
{
    previewMusicYoutubePlayer = MPMoviePlayerControllerInstance;
}

- (MPMoviePlayerController *)previewMusicYoutubePlayer
{
    return previewMusicYoutubePlayer;
}

#pragma mark - YouTube Link Extraction Helper
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

+ (void)setNeedsToDisplayNewVideo:(BOOL)displayNewVideo
{
    needsToDisplayNewVideo = displayNewVideo;
}

+ (BOOL)needsToDisplayNewVideo
{
    return needsToDisplayNewVideo;
}

@end
