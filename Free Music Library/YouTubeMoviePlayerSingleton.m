//
//  YouTubeMoviePlayerSingleton.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/6/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YouTubeMoviePlayerSingleton.h"

@implementation YouTubeMoviePlayerSingleton
static MPMoviePlayerController *videoPlayer = nil;
static ALMoviePlayerController *previewMusicYoutubePlayer = nil;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

+ (void)setYouTubePlayerInstance:(MPMoviePlayerController *)MPMoviePlayerControllerInstance
{
    videoPlayer = MPMoviePlayerControllerInstance;
}

- (MPMoviePlayerController *)youtubePlayer
{
    return videoPlayer;
}



+ (void)setPreviewMusicYouTubePlayerInstance:(ALMoviePlayerController *)ALMoviePlayerControllerInstance
{
    previewMusicYoutubePlayer = ALMoviePlayerControllerInstance;
}

- (ALMoviePlayerController *)previewMusicYoutubePlayer
{
    return previewMusicYoutubePlayer;
}

@end
