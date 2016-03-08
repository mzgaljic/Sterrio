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

@protocol MZPreviewPlayerDelegate <NSObject>
- (void)previewPlayerStallStateChanged;
- (void)previewPlayerNeedsNowPlayingInfoCenterUpdate;
- (void)userHasPausedPlayback:(BOOL)paused;
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
extern const int VIEW_EDGE_PADDING;
extern const int LABEL_AND_SLIDER_PADDING;
extern const int PLAY_PAUSE_BTN_DIAMETER;
extern const int AIRPLAY_ICON_WIDTH;
extern const int LABEL_FONT_SIZE;
extern const int BUTTON_AND_LABEL_PADDING;

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL useControlsOverlay:(BOOL)useOverlay;
- (void)setStallValueChangedDelegate:(id <MZPreviewPlayerDelegate>)aDelegate;
- (void)play;
- (void)pause;
- (void)playFromBeginning;
- (void)destroyPlayer;

- (void)reattachLayerWithPlayer;
- (void)removePlayerFromLayer;

@end
