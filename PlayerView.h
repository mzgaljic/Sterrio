//
//  PlayerView.h
//  Muzic
//
//  Created by Mark Zgaljic on 11/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SongPlayerCoordinator.h"
#import "UIWindow+VisibleVC.h"
#import "UIView+ScreenshotView.h"
#import "OperationQueuesSingeton.h"

@interface PlayerView : UIView

- (void)setPlayer:(AVPlayer *)player;

//used so the player view knows where it was initially before
//a user started dragging it off screen (when they decide to kill it)
- (void)shrunkenFrameHasChanged;

- (void)removeLayerFromPlayer;
- (void)reattachLayerToPlayer;
- (UIImage *)screenshotOfPlayer;

- (void)userKilledPlayer;

- (void)showAirPlayInUseMsg:(BOOL)show;
- (void)newAirplayInUseMsgCenter:(CGPoint)newCenter;

//'proxy' for the methods called in MusicPlaybackController.
//Needed to keep the player 'hud' in sync.
- (void)playCalled;
- (void)pauseCalled;
- (void)updatePlaybackTimeSliderWithTimeValue:(Float64)currentTimeValue;

@end