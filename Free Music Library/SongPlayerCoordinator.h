//
//  SongPlayerCoordinator.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicPlaybackController.h"
#import "VideoPlayerControlInterfaceDelegate.h"
#import "SongPlayerViewDisplayUtility.h"
#import "PlayerView.h"
#import "MRProgress.h"  //loading spinner

@interface SongPlayerCoordinator : NSObject
@property (nonatomic, weak) id<VideoPlayerControlInterfaceDelegate>delegate;
+ (instancetype)sharedInstance;

- (void)setDelegate:(id<VideoPlayerControlInterfaceDelegate>)theDelegate;
- (BOOL)isVideoPlayerExpanded;
- (void)beginShrinkingVideoPlayer;
- (void)begingExpandingVideoPlayer;
- (void)shrunkenVideoPlayerNeedsToBeRotated;

@end
