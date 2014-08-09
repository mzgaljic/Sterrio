

//
//  YouTubeMoviePlayerSingleton.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/6/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <ALMoviePlayerController/ALMoviePlayerController.h>

@interface YouTubeMoviePlayerSingleton : NSObject

+ (instancetype)createSingleton;

+ (void)setYouTubePlayerInstance:(MPMoviePlayerController *)MPMoviePlayerControllerInstance;

/**Returns the current XCDYouTubeVideoPlayerViewController instance, or nil if no video player was launched at all.*/
- (MPMoviePlayerController *)youtubePlayer;


+ (void)setPreviewMusicYouTubePlayerInstance:(ALMoviePlayerController *)ALMoviePlayerControllerInstance;

- (ALMoviePlayerController *)previewMusicYoutubePlayer;
@end
