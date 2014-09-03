

//
//  YouTubeMoviePlayerSingleton.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/6/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <ALMoviePlayerController/ALMoviePlayerController.h>
#import "Song+Utilities.h"

//used by youtube link extractor
#import <XCDYouTubeKit/XCDYouTubeClient.h>

@interface YouTubeMoviePlayerSingleton : NSObject

+ (instancetype)createSingleton;

#pragma mark - Custom AVPlayer powered video player for library
- (void)setAVPlayerInstance:(AVPlayer *)AVPlayerInstance;
- (AVPlayer *)AVPlayer;

- (void)setAVPlayerLayerInstance:(AVPlayerLayer *)AVPlayerInstance;
- (AVPlayerLayer *)AVPlayerLayer;

#pragma mark - YouTube video player for previewing songs when adding to library
- (void)setPreviewMusicYouTubePlayerInstance:(ALMoviePlayerController *)ALMoviePlayerControllerInstance;

- (ALMoviePlayerController *)previewMusicYoutubePlayer;

#pragma mark - YouTube Link Extraction Helper
+ (NSURL *)closestUrlQualityMatchForSetting:(short)aQualitySetting usingStreamsDictionary:(NSDictionary *)aDictionary;

#pragma mark - Helper variables for view controllers
+ (void)setNeedsToDisplayNewVideo:(BOOL)displayNewVideo;
+ (BOOL)needsToDisplayNewVideo;

#pragma mark - Core Data Fetching/Queries
+ (Song *)nowPlayingSong;

@end
