//
//  SongPlayerCoordinator.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicPlaybackController.h"
#import "SongPlayerViewDisplayUtility.h"
#import "PlayerView.h"
#import "MRProgress.h"  //loading spinner

@interface SongPlayerCoordinator : NSObject

+ (instancetype)sharedInstance;

+ (BOOL)isVideoPlayerExpanded;
- (void)beginShrinkingVideoPlayer;
- (void)begingExpandingVideoPlayer;
- (void)beginAnimatingPlayerIntoMinimzedStateIfNotExpanded;
- (void)shrunkenVideoPlayerNeedsToBeRotated;
- (void)shrunkenVideoPlayerShouldRespectToolbar;
- (void)shrunkenVideoPlayerCanIgnoreToolbar;

- (void)temporarilyDisablePlayer;
- (void)enablePlayerAgain;
+ (BOOL)isPlayerEnabled;
+ (float)alphaValueForDisabledPlayer;
+ (BOOL)isPlayerOnScreen;  //takes into account player being killed, etc.
+ (void)playerWasKilled:(BOOL)killed;

- (CGRect)currentPlayerViewFrame;
/* This does NOT actually change the frame. simply a way to log the latest changes if the 
  frame was changed via code other than the methods in the SongPlayerCoordinator class. */
- (void)recordCurrentPlayerViewFrame:(CGRect)newFrame;

//for disabling playback in response to particular events (losing wifi connection, etc)
+ (void)placePlayerInDisabledState:(BOOL)disabled;
+ (BOOL)isPlayerInDisabledState;
+ (BOOL)wasPlayerInPlayStateBeforeGUIDisabled;

//This is mainly exposed for the PlayerView class
- (CGRect)smallPlayerFrameInLandscape;
- (CGRect)smallPlayerFrameInPortrait;

//for figuring out how much to compensate the tableviews
+ (int)heightOfMinimizedPlayer;

@end
