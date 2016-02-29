//
//  MZPreviewPlayer.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/7/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@protocol MZPreviewPlayerStallState <NSObject>
- (void)previewPlayerStallStateChanged;
- (void)previewPlayerNeedsNowPlayingInfoCenterUpdate;
@end

@interface MZPlayer : UIView
@property (assign, nonatomic) BOOL loopPlaybackForever;
@property (strong, nonatomic, readonly) AVPlayer *avPlayer;
@property (assign, nonatomic, readonly) BOOL isPlaying;
@property (assign, nonatomic, readonly) BOOL isInStall;
@property (assign, nonatomic, readonly) BOOL playbackExplicitlyPaused;
@property (assign, nonatomic, readonly) NSUInteger elapsedTimeInSec;

extern const int CONTROLS_HUD_HEIGHT;
extern const float AUTO_HIDE_HUD_DELAY;

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL useControlsOverlay:(BOOL)useOverlay;
- (void)setStallValueChangedDelegate:(id <MZPreviewPlayerStallState>)aDelegate;
- (void)play;
- (void)pause;
- (void)playFromBeginning;
- (void)destroyPlayer;

- (void)reattachLayerWithPlayer;
- (void)removePlayerFromLayer;

@end
