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


- (void)removeLayerFromPlayer;
- (void)reattachLayerToPlayer;
- (UIImage *)screenshotOfPlayer;

@end
