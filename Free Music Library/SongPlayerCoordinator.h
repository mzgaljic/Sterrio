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
+ (BOOL)isVideoPlayerExpanded;
- (void)beginShrinkingVideoPlayer;
- (void)begingExpandingVideoPlayer;
- (void)shrunkenVideoPlayerNeedsToBeRotated;
- (void)shrunkenVideoPlayerShouldRespectToolbar;
- (void)shrunkenVideoPlayerCanIgnoreToolbar;

- (void)temporarilyDisablePlayer;
- (void)enablePlayerAgain;
+ (BOOL)isPlayerEnabled;
+ (BOOL)isPlayerOnScreen;
+ (void)playerWasKilled:(BOOL)killed;

- (CGRect)currentPlayerViewFrame;
/* This does NOT actually change the frame. simply a way to log the latest changes if the 
  frame was changed via code other than the methods in the SongPlayerCoordinator class. */
- (void)recordCurrentPlayerViewFrame:(CGRect)newFrame;


//This is mainly exposed for the PlayerView class
- (CGRect)smallPlayerFrameInLandscape;
- (CGRect)smallPlayerFrameInPortrait;

@end
