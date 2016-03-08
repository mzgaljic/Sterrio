
//
//  MZPreviewPlayer.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/7/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZPlayer.h"
#import "ReachabilitySingleton.h"
#import "UIImage+colorImages.h"
#import "UIButton+ExpandedHitArea.h"
#import "UIColor+LighterAndDarker.h"
#import "AppEnvironmentConstants.h"
#import "MZSlider.h"
#import "SSBouncyButton.h"
#import "SongPlayerViewDisplayUtility.h"

@interface MZPlayer ()
{
    id playbackObserver;
    AVPlayerLayer *playerLayer;
    UIVisualEffectView *visualEffectView;
    
    UIImageView *airplayLogoView;
    
    NSUInteger totalDuration;
    NSUInteger secondsLoaded;
    BOOL playbackStarted;
    
    BOOL isHudOnScreen;
}

@property (strong, nonatomic, readwrite) AVPlayer *avPlayer;
@property (strong,nonatomic) UIView *controlsHud;

@property (strong, nonatomic) MPVolumeView *mpVolumeView;
@property (strong, nonatomic) SSBouncyButton *playPauseButton;
@property (strong, nonatomic) MZSlider *progressBar;
@property (strong, nonatomic) UILabel *elapsedTimeLabel;
@property (strong, nonatomic) UILabel *totalTimeLabel;

@property (strong, nonatomic) NSURL *videoURL;

@property (assign, nonatomic, readwrite) BOOL isPlaying;
@property (assign, nonatomic, readwrite) BOOL isInStall;
@property (assign, nonatomic, readwrite) BOOL playbackExplicitlyPaused;
@property (assign, nonatomic, readwrite) BOOL useControlsOverlay;

@property (weak, nonatomic) id <MZPreviewPlayerDelegate> delegate;
@end
@implementation MZPlayer

const int CONTROLS_HUD_HEIGHT = 45;
const float AUTO_HIDE_HUD_DELAY = 4;
const int VIEW_EDGE_PADDING = 10;
const int LABEL_AND_SLIDER_PADDING = 5;
const int PLAY_PAUSE_BTN_DIAMETER = CONTROLS_HUD_HEIGHT * 0.50;
const int AIRPLAY_ICON_WIDTH = 25;
const int LABEL_FONT_SIZE = PLAY_PAUSE_BTN_DIAMETER * 0.85;
const int BUTTON_AND_LABEL_PADDING = PLAY_PAUSE_BTN_DIAMETER * 0.80;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [playerLayer setFrame:frame];
    if(playbackStarted){
        [self setupControlsHudCacheLabels:NO];
    }
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    _isPlaying = isPlaying;
    if(isPlaying)
        [self.playPauseButton setSelected:NO];  //toggle to pause button image
    else
        [self.playPauseButton setSelected:YES]; //toggle to play button image
}

- (void)setIsInStall:(BOOL)isInStall
{
    _isInStall = isInStall;
    [self.delegate previewPlayerStallStateChanged];
}

- (void)setLoopPlaybackForever:(BOOL)loopPlaybackForever
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    if(loopPlaybackForever) {
         __weak typeof(self) weakSelf = self; // prevent memory cycle
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                          object:self.avPlayer.currentItem
                                                           queue:nil
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          // holding a pointer to avPlayer to reuse it
                                                          if(weakSelf.loopPlaybackForever) {
                                                              [weakSelf.avPlayer seekToTime:kCMTimeZero];
                                                              [weakSelf.avPlayer play];
                                                          }
                                                      }];
    }
    _loopPlaybackForever = loopPlaybackForever;
}
   
#pragma mark - Lifecycle
- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL useControlsOverlay:(BOOL)useOverlay
{
    if (self = [super initWithFrame:frame]) {
        _isInStall = YES;
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
        _avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        [self initObservers];
        playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
        [playerLayer setFrame:self.bounds];
        [self.layer addSublayer:playerLayer];
        [self.layer setMasksToBounds:YES];
        _videoURL = videoURL;
        _useControlsOverlay = useOverlay;
        if(useOverlay) {
            UITapGestureRecognizer *singleFingerTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(userTappedPlayerView:)];
            [self addGestureRecognizer:singleFingerTap];
        }
        
        _avPlayer.allowsExternalPlayback = ![AppEnvironmentConstants shouldOnlyAirplayAudio];
        [self setupTimeObserver];
        
        NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
        [notifCenter addObserver:self
                        selector:@selector(airplayDevicesAvailableChanged:)
                            name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                          object:nil];
    }
    return self;
}

- (void)setStallValueChangedDelegate:(id <MZPreviewPlayerDelegate>)aDelegate
{
    self.delegate = aDelegate;
}

- (void)destroyPlayer
{
    [self.avPlayer replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
    [self removeTimeObserver];
    [self removeObservers];
    self.avPlayer = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reattachLayerWithPlayer
{
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    [playerLayer setFrame:self.bounds];
    [self.layer addSublayer:playerLayer];
    if(self.controlsHud){
        [self bringSubviewToFront:self.controlsHud];
    }
    [self setupTimeObserver];
}

- (void)removePlayerFromLayer
{
    [self removeTimeObserver];
    if([playerLayer player] != nil)
        [playerLayer setPlayer:nil];
}

- (void)setupControlsHudCacheLabels:(BOOL)cacheLabels
{
    if(! self.useControlsOverlay) {
        return;
    }
    
    int yOrigin = self.frame.size.height - CONTROLS_HUD_HEIGHT;
    if(self.controlsHud == nil){
        self.controlsHud = [[UIView alloc] init];
    }
    
    //adding some extra height at the bottom since the hud animates onto the screen with a spring effect.
    [self.controlsHud setFrame:CGRectMake(0,
                                         yOrigin,
                                         self.frame.size.width,
                                         CONTROLS_HUD_HEIGHT + (CONTROLS_HUD_HEIGHT /2))];
    
    [self.controlsHud setBackgroundColor:[UIColor clearColor]];
    
    if(visualEffectView == nil){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    }
    
    visualEffectView.frame = self.controlsHud.bounds;
    [self.controlsHud addSubview:visualEffectView];
    
    //Play-Pause button
    if(self.playPauseButton == nil) {
        self.playPauseButton = [[SSBouncyButton alloc] initAsImage];
        UIImage *pauseImage = [UIImage colorOpaquePartOfImage:[UIColor defaultWindowTintColor]
                                                             :[UIImage imageNamed:@"Pause"]];
        UIImage *playImage = [UIImage colorOpaquePartOfImage:[UIColor defaultWindowTintColor]
                                                            :[UIImage imageNamed:@"Play"]];
        [self.playPauseButton setImage:pauseImage forState:UIControlStateNormal];
        [self.playPauseButton setImage:playImage forState:UIControlStateSelected];
        [self.playPauseButton setSelected:NO];
        [self.playPauseButton setHitTestEdgeInsets:UIEdgeInsetsMake(-30, -30, -30, -25)];
        [self.playPauseButton addTarget:self
                                 action:@selector(playButtonTapped:)
                       forControlEvents:UIControlEventTouchUpInside];
    }
    
    self.playPauseButton.frame = CGRectMake(VIEW_EDGE_PADDING,
                                            (CONTROLS_HUD_HEIGHT /2) - (PLAY_PAUSE_BTN_DIAMETER/2),
                                            PLAY_PAUSE_BTN_DIAMETER,
                                            PLAY_PAUSE_BTN_DIAMETER);
    
    totalDuration = CMTimeGetSeconds(self.avPlayer.currentItem.asset.duration);
    NSString *totalDurationString = [SongPlayerViewDisplayUtility convertSecondsToPrintableNSStringWithSliderValue:totalDuration];
    
    //Elapsed Time Label
    if(! cacheLabels) {
        self.elapsedTimeLabel = nil;
        self.elapsedTimeLabel = [[UILabel alloc] init];
        if(totalDurationString.length <= 4)
            self.elapsedTimeLabel.text = @"0:00";
        else if(totalDurationString.length == 5)
            self.elapsedTimeLabel.text = @"00:00";
        else
            self.elapsedTimeLabel.text = @"00:00:00";
        self.elapsedTimeLabel.textAlignment = NSTextAlignmentRight;
        self.elapsedTimeLabel.textColor = [UIColor whiteColor];
        self.elapsedTimeLabel.font = [UIFont fontWithName:@"Menlo"
                                                     size:LABEL_FONT_SIZE];
    }
    if(totalDurationString.length <= 4)
        self.elapsedTimeLabel.text = @"0:00";
    else if(totalDurationString.length == 5)
        self.elapsedTimeLabel.text = @"00:00";
    else
        self.elapsedTimeLabel.text = @"00:00:00";
    self.elapsedTimeLabel.frame = [self elapsedTimeLabelRect];
    
    //Total Duration Label
    if(!cacheLabels) {
        self.totalTimeLabel = nil;
        self.totalTimeLabel = [[UILabel alloc] init];
        self.totalTimeLabel.text = totalDurationString;
        self.totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        self.totalTimeLabel.textColor = [UIColor whiteColor];
        self.totalTimeLabel.font = [UIFont fontWithName:@"Menlo"
                                                   size:LABEL_FONT_SIZE];
    }
    self.totalTimeLabel.frame = [self totalTimeLabelRect];
    
    //Seek Time Progress Bar
    if(self.progressBar == nil){
        self.progressBar = [[MZSlider alloc] init];
        [self.progressBar addTarget:self
                             action:@selector(progressBarEditingBegan:)
                   forControlEvents:UIControlEventTouchDown];
        [self.progressBar addTarget:self
                             action:@selector(progressBarChanged:)
                   forControlEvents:UIControlEventValueChanged];
        
        //progressBarChangeEnded was never fucking called as it should have been
        //with just 'UIControlEventEditingDidEnd'. So I added these extra targets.
        [self.progressBar addTarget:self
                             action:@selector(progressBarChangeEnded:)
                   forControlEvents:UIControlEventTouchUpInside];
        [self.progressBar addTarget:self
                             action:@selector(progressBarChangeEnded:)
                   forControlEvents:UIControlEventTouchUpOutside];
        [self.progressBar addTarget:self
                             action:@selector(progressBarChangeEnded:)
                   forControlEvents:UIControlEventTouchDragExit];
        [self.progressBar addTarget:self
                             action:@selector(progressBarChangeEnded:)
                   forControlEvents:UIControlEventEditingDidEndOnExit];
        [self.progressBar addTarget:self
                             action:@selector(progressBarChangeEnded:)
                   forControlEvents:UIControlEventEditingDidEnd];
        [self.progressBar addTarget:self
                             action:@selector(progressBarChangeEnded:)
                   forControlEvents:UIControlEventTouchCancel];
        //[self.progressBar setThumbImage:[UIImage imageNamed:@"UISliderKnob"] forState:UIControlStateNormal];
        self.progressBar.transform = CGAffineTransformMakeScale(0.80, 0.80);  //make knob smaller
        self.progressBar.maximumValue = totalDuration;
        self.progressBar.minimumValue = 0;
        self.progressBar.minimumTrackTintColor = [[UIColor defaultAppColorScheme] lighterColor];
        self.progressBar.maximumTrackTintColor = [UIColor groupTableViewBackgroundColor];
        self.progressBar.continuous = YES;
    }
    
    int volumeViewXOrigin = self.totalTimeLabel.frame.origin.x + self.totalTimeLabel.frame.size.width + LABEL_AND_SLIDER_PADDING;
    int height = CONTROLS_HUD_HEIGHT * 0.85;
    int volumeViewYOrigin = (CONTROLS_HUD_HEIGHT /2) - (height/2);
    if(self.mpVolumeView == nil) {
        self.mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(volumeViewXOrigin,
                                                                           volumeViewYOrigin,
                                                                           height,
                                                                           height)];
        [self.mpVolumeView setShowsVolumeSlider:NO];
        [self.mpVolumeView setShowsRouteButton:YES];
        UIImage *airplayImg = [UIImage imageNamed:@"airplay_button"];
        UIImage *airplayNormalState = [UIImage colorOpaquePartOfImage:[UIColor whiteColor]
                                                                     :airplayImg];
        UIImage *airplayActiveState = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                                     :airplayImg];
        
        [self.mpVolumeView setRouteButtonImage:airplayNormalState forState:UIControlStateNormal];
        [self.mpVolumeView setRouteButtonImage:airplayNormalState forState:UIControlStateHighlighted];
        [self.mpVolumeView setRouteButtonImage:airplayActiveState forState:UIControlStateSelected];
    } else {
        self.mpVolumeView.frame = CGRectMake(volumeViewXOrigin,
                                             volumeViewYOrigin,
                                             height,
                                             height);
    }
    
    int progressBarHeight = CONTROLS_HUD_HEIGHT/4;
    int xOrigin = self.elapsedTimeLabel.frame.origin.x + self.elapsedTimeLabel.frame.size.width + LABEL_AND_SLIDER_PADDING;
    self.progressBar.frame = CGRectMake(xOrigin,
                                        (CONTROLS_HUD_HEIGHT /2) - (progressBarHeight/2) + 2,
                                        [self sliderWidth],
                                        progressBarHeight);
    
    if(self.mpVolumeView.areWirelessRoutesAvailable) {
        //showing airplay button
        self.mpVolumeView.hidden = NO;
    } else {
        self.mpVolumeView.hidden = YES;
    }
    
    [self.controlsHud addSubview:self.playPauseButton];
    [self.controlsHud addSubview:self.elapsedTimeLabel];
    [self.controlsHud addSubview:self.progressBar];
    [self.controlsHud addSubview:self.totalTimeLabel];
    [self.controlsHud addSubview:self.mpVolumeView];

    [self addSubview:self.controlsHud];
    
    if(! isHudOnScreen){
        //now move entire hud off the player bounds so it can optionally be animated in later.
        [self.controlsHud setFrame:CGRectMake(self.controlsHud.frame.origin.x,
                                              self.controlsHud.frame.origin.y + CONTROLS_HUD_HEIGHT,
                                              self.controlsHud.frame.size.width,
                                              self.controlsHud.frame.size.height)];
    }
}

- (void)setupTimeObserver
{
    CMTime interval = CMTimeMake(1, 8);
    __weak __typeof(self) weakself = self;
    
    playbackObserver = [self.avPlayer addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock: ^(CMTime time) {
        [weakself updatePlaybackTimeSlider];
    }];
}

- (void)removeTimeObserver
{
    [self.avPlayer removeTimeObserver:playbackObserver];
}

- (void)updatePlaybackTimeSlider
{
    Float64 currentTimeValue = CMTimeGetSeconds(self.avPlayer.currentItem.currentTime);
    _elapsedTimeInSec = currentTimeValue;
    [self.progressBar setValue:(currentTimeValue) animated:YES];
    self.elapsedTimeLabel.text = [SongPlayerViewDisplayUtility convertSecondsToPrintableNSStringWithSliderValue:currentTimeValue];
}

#pragma mark - Hud Control Animations
- (void)animateHudOntoPlayer
{
    isHudOnScreen = YES;
    int yOrigin = self.frame.size.height - CONTROLS_HUD_HEIGHT;
    CGRect animationFrame = CGRectMake(0,
                                       yOrigin,
                                       self.frame.size.width,
                                       CONTROLS_HUD_HEIGHT);
    [UIView animateWithDuration:0.65
                          delay:0
         usingSpringWithDamping:0.60
          initialSpringVelocity:0.65
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.controlsHud.frame = animationFrame;
                     }
                     completion:^(BOOL finished) {
                         [self startAutoHideTimer];
                     }];
}

- (void)animateHudOffPlayer
{
    [self clearTimer];
    isHudOnScreen = NO;
    int yOrigin = self.frame.size.height;
    CGRect animationFrame = CGRectMake(0,
                                       yOrigin,
                                       self.frame.size.width,
                                       CONTROLS_HUD_HEIGHT);
    [UIView animateWithDuration:0.65
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0.65
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.controlsHud.frame = animationFrame;
                     }
                     completion:nil];
}

#pragma mark - Rect helpers
- (CGRect)elapsedTimeLabelRect
{
    [self.elapsedTimeLabel sizeToFit];
    int xOrigin = self.playPauseButton.frame.origin.x + PLAY_PAUSE_BTN_DIAMETER + BUTTON_AND_LABEL_PADDING;
    return CGRectMake(xOrigin,
                      (CONTROLS_HUD_HEIGHT /2) - (LABEL_FONT_SIZE/2),
                      self.elapsedTimeLabel.frame.size.width,
                      self.elapsedTimeLabel.frame.size.height);
}
- (CGRect)totalTimeLabelRect
{
    [self.totalTimeLabel sizeToFit];
    
    if(self.mpVolumeView.wirelessRoutesAvailable) {
        //showing airplay button
        int xOrigin = self.frame.size.width - VIEW_EDGE_PADDING - AIRPLAY_ICON_WIDTH - BUTTON_AND_LABEL_PADDING - self.totalTimeLabel.frame.size.width;
        return CGRectMake(xOrigin,
                          (CONTROLS_HUD_HEIGHT /2) - (LABEL_FONT_SIZE/2),
                          self.totalTimeLabel.frame.size.width,
                          self.totalTimeLabel.frame.size.height);
    } else {
        int xOrigin = self.frame.size.width - VIEW_EDGE_PADDING - self.totalTimeLabel.frame.size.width;
        return CGRectMake(xOrigin,
                         (CONTROLS_HUD_HEIGHT /2) - (LABEL_FONT_SIZE/2),
                          self.totalTimeLabel.frame.size.width,
                          self.totalTimeLabel.frame.size.height);
    }
}

- (int)sliderWidth
{
    CGRect elapsedLabelRect = [self elapsedTimeLabelRect];
    CGRect totalTimeLabelRect = [self totalTimeLabelRect];
    if(self.mpVolumeView.wirelessRoutesAvailable) {
        //showing airplay button
        return self.frame.size.width - elapsedLabelRect.origin.x - elapsedLabelRect.size.width - LABEL_AND_SLIDER_PADDING - VIEW_EDGE_PADDING - AIRPLAY_ICON_WIDTH - LABEL_AND_SLIDER_PADDING - totalTimeLabelRect.size.width - LABEL_AND_SLIDER_PADDING - LABEL_AND_SLIDER_PADDING - LABEL_AND_SLIDER_PADDING;
    } else {
        return self.frame.size.width - elapsedLabelRect.origin.x - elapsedLabelRect.size.width - LABEL_AND_SLIDER_PADDING - VIEW_EDGE_PADDING - totalTimeLabelRect.size.width - LABEL_AND_SLIDER_PADDING;
    }
}

#pragma mark - Hud Controls
- (void)userTappedPlayerView:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:recognizer.view];
    if(isHudOnScreen && location.y >= self.controlsHud.frame.origin.y){
        return;
    }
    if(isHudOnScreen)
        [self animateHudOffPlayer];
    else
        [self animateHudOntoPlayer];
}

- (void)play
{
    [self startAutoHideTimer];
    if(_elapsedTimeInSec == totalDuration){
        //start playback from beginning
        Float64 beginning = 0.00;
        CMTime targetTime = CMTimeMakeWithSeconds(beginning, NSEC_PER_SEC);
        [self.avPlayer seekToTime:targetTime
                  toleranceBefore:kCMTimeZero
                   toleranceAfter:kCMTimeZero];
    }
    self.playbackExplicitlyPaused = NO;
    [self.avPlayer play];
    [self.playPauseButton setSelected:NO];
    [self.delegate previewPlayerNeedsNowPlayingInfoCenterUpdate];
}

- (void)playFromBeginning
{
    [self startAutoHideTimer];
    //start playback from beginning
    Float64 beginning = 0.00;
    CMTime targetTime = CMTimeMakeWithSeconds(beginning, NSEC_PER_SEC);
    [self.avPlayer seekToTime:targetTime
              toleranceBefore:kCMTimeZero
               toleranceAfter:kCMTimeZero];
    self.playbackExplicitlyPaused = NO;
    [self.avPlayer play];
    [self.playPauseButton setSelected:NO];
    [self.delegate previewPlayerNeedsNowPlayingInfoCenterUpdate];
}

- (void)pause
{
    [self startAutoHideTimer];
    self.playbackExplicitlyPaused = YES;
    [self.avPlayer pause];
    [self.playPauseButton setSelected:YES];
    [self.delegate previewPlayerNeedsNowPlayingInfoCenterUpdate];
}

- (void)progressBarEditingBegan:(UISlider *)sender
{
    if (self.isPlaying) {
        [self.avPlayer pause];
    }
    [self clearTimer];
}

- (void)progressBarChanged:(UISlider *)sender
{
    _elapsedTimeInSec = sender.value;
    if(! self.avPlayer.externalPlaybackActive) {
        CMTime seekTime = CMTimeMakeWithSeconds(sender.value, NSEC_PER_SEC);
        [self.avPlayer seekToTime:seekTime];
    }
    self.elapsedTimeLabel.text = [SongPlayerViewDisplayUtility convertSecondsToPrintableNSStringWithSliderValue:sender.value];
}

- (void)progressBarChangeEnded:(UISlider *)sender
{
    _elapsedTimeInSec = sender.value;
    if(self.avPlayer.externalPlaybackActive) {
        CMTime seekTime = CMTimeMakeWithSeconds(sender.value, NSEC_PER_SEC);
        [self.avPlayer seekToTime:seekTime];
    }

    [self.delegate previewPlayerNeedsNowPlayingInfoCenterUpdate];
    [self.avPlayer play];
    [self startAutoHideTimer];
}

#pragma mark - Hiding/Showing airplay button
- (void)airplayDevicesAvailableChanged:(NSNotification*)aNotification
{
    if(((MPVolumeView*)aNotification.object).wirelessRoutesAvailable) {
        [self showAirplayButtonAnimated:YES];
    } else {
        [self showAirplayButtonAnimated:NO];
    }
}

- (void)showAirplayButtonAnimated:(BOOL)show
{
    if(show) {
        self.mpVolumeView.hidden = NO;
    } else {
        self.mpVolumeView.hidden = YES;
    }
    
    [UIView animateWithDuration:0.7
                          delay:0
                        options:UIViewAnimationOptionAllowAnimatedContent |
     UIViewAnimationOptionAllowUserInteraction |
     UIViewAnimationOptionBeginFromCurrentState|
     UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self setupControlsHudCacheLabels:YES];
                     }
                     completion:nil];
}

#pragma mark - Hud Control Button Targets
 -(void)playButtonTapped:(UIButton *)sender
{
    if (self.isPlaying){
        [self pause];
        [self.delegate userHasPausedPlayback:YES];
    }
    else{
        [self play];
        [self.delegate userHasPausedPlayback:NO];
    }
}

#pragma mark - Airplay Logo on Player
- (void)showAirPlayLogoView:(BOOL)show
{
    if(show){
        if(airplayLogoView == nil){
            [self removePlayerFromLayer];
            UIImage *airplayImg = [UIImage imageNamed:@"airplay"];
            airplayImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                        :airplayImg];
            
            airplayLogoView = [[UIImageView alloc] initWithImage:airplayImg];
            airplayLogoView.userInteractionEnabled = NO;
            [self addSubview:airplayLogoView];
            airplayLogoView.center = [self convertPoint:self.center fromView:self.superview];
            CGRect originalImgViewFrame = airplayLogoView.frame;
            airplayLogoView.frame = CGRectMake(0,
                                               0,
                                               airplayLogoView.frame.size.width /6,
                                               airplayLogoView.frame.size.height /6);
            airplayLogoView.center = [self convertPoint:self.center fromView:self.superview];
            [UIView animateWithDuration:0.8
                                  delay:0
                 usingSpringWithDamping:0.75
                  initialSpringVelocity:0.3
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 airplayLogoView.frame = originalImgViewFrame;
                             }
                             completion:nil];
        }
    } else{
        if(airplayLogoView){
            CGRect originalFrame = airplayLogoView.frame;
            airplayLogoView.frame = CGRectMake(0,
                                               0,
                                               airplayLogoView.frame.size.width /4,
                                               airplayLogoView.frame.size.height /4);
            airplayLogoView.center = [self convertPoint:self.center fromView:self.superview];
            CGRect animationFrame = airplayLogoView.frame;
            airplayLogoView.frame = originalFrame;
            
            [self reattachLayerWithPlayer];
            [self bringSubviewToFront:self.controlsHud];
            [self bringSubviewToFront:airplayLogoView];
            
            [UIView animateWithDuration:0.45
                                  delay:0
                 usingSpringWithDamping:1
                  initialSpringVelocity:0.3
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 airplayLogoView.frame = animationFrame;
                             }
                             completion:^(BOOL finished) {
                                 [airplayLogoView removeFromSuperview];
                                 airplayLogoView = nil;
                             }];
        }
    }
}


#pragma mark - Key Value Observing
- (void)initObservers
{
    [self.avPlayer addObserver:self
                    forKeyPath:@"currentItem.playbackBufferEmpty"
                       options:NSKeyValueObservingOptionNew
                       context:ksPlaybackBufferEmpty];
    [self.avPlayer addObserver:self
                    forKeyPath:@"currentItem.loadedTimeRanges"
                       options:NSKeyValueObservingOptionNew
                       context:ksLoadedTimeRanges];
    [self.avPlayer addObserver:self
                    forKeyPath:@"rate"
                       options:NSKeyValueObservingOptionNew
                       context:ksPlaybackRate];
    [self.avPlayer addObserver:self
                    forKeyPath:@"externalPlaybackActive"
                       options:NSKeyValueObservingOptionNew
                       context:ksAirplayState];
}

- (void)removeObservers
{
    [self.avPlayer removeObserver:self
                       forKeyPath:@"currentItem.playbackBufferEmpty"
                          context:ksPlaybackBufferEmpty];
    [self.avPlayer removeObserver:self
                       forKeyPath:@"currentItem.loadedTimeRanges"
                          context:ksLoadedTimeRanges];
    [self.avPlayer removeObserver:self
                       forKeyPath:@"rate"
                          context:ksPlaybackRate];
    [self.avPlayer removeObserver:self
                       forKeyPath:@"externalPlaybackActive"
                          context:ksAirplayState];
}

static void *ksLoadedTimeRanges = &ksLoadedTimeRanges;
static void *ksPlaybackBufferEmpty = &ksPlaybackBufferEmpty;
static void *ksPlaybackRate = &ksPlaybackRate;
static void *ksAirplayState = &ksAirplayState;
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(context == ksLoadedTimeRanges || context == ksPlaybackBufferEmpty){
        NSArray *timeRanges = self.avPlayer.currentItem.loadedTimeRanges;
        if (timeRanges && [timeRanges count]){
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            NSUInteger newSecondsBuff = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
            if(context == ksPlaybackBufferEmpty){
                if(newSecondsBuff == secondsLoaded && secondsLoaded != totalDuration && !self.isInStall){
                    NSLog(@"Preview is in stall");
                    self.isInStall = YES;
                    
                    if(self.avPlayer.rate > 0){
                        self.isPlaying = NO;
                        [self.avPlayer pause];
                    }
                }
                
            } else if(context == ksLoadedTimeRanges){
                NSUInteger currentTime = CMTimeGetSeconds(self.avPlayer.currentItem.currentTime);
                CMTimeRange aTimeRange;
                NSUInteger lowBound;
                NSUInteger upperBound;
                BOOL inALoadedRange = NO;
                for(int i = 0; i < timeRanges.count; i++){
                    aTimeRange = [timeRanges[i] CMTimeRangeValue];
                    lowBound = CMTimeGetSeconds(timerange.start);
                    upperBound = CMTimeGetSeconds(CMTimeAdd(timerange.start, aTimeRange.duration));
                    if(currentTime >= lowBound && currentTime < upperBound)
                        inALoadedRange = YES;
                }
                
                if(! inALoadedRange && !self.isInStall){
                    NSLog(@"Preview is in stall");
                    self.isInStall = YES;
                    
                    if(self.avPlayer.rate > 0){
                        self.isPlaying = NO;
                        [self.avPlayer pause];
                    }
                    
                } else if(newSecondsBuff > secondsLoaded && self.isInStall && [[ReachabilitySingleton sharedInstance] isConnectedToInternet]){
                    NSLog(@"Preview has left stall");
                    self.isInStall = NO;
                    
                    if(! self.playbackExplicitlyPaused){
                        self.isPlaying = YES;
                        [self.avPlayer play];
                    }
                }
                //check if playback began
                if(newSecondsBuff > secondsLoaded && self.avPlayer.rate == 1 && !playbackStarted){
                    playbackStarted = YES;
                    self.isPlaying = YES;
                    
                    self.isInStall = NO;
                    NSLog(@"Preview playback started");
                    
                    [self setupControlsHudCacheLabels:NO];
                }
                secondsLoaded = newSecondsBuff;
            }
        }
    } else if(context == ksPlaybackRate){
        self.isPlaying = (self.avPlayer.rate == 1);
    } else if(context == ksAirplayState){
        BOOL airplayActive = self.avPlayer.externalPlaybackActive;
        [self showAirPlayLogoView:airplayActive];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Stop-watch method to time code execution
static NSTimer *autoHideTimer;
- (void)startAutoHideTimer
{
    if(! self.useControlsOverlay) {
        return;
    }
    if(autoHideTimer)
        [self clearTimer];
    autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_HIDE_HUD_DELAY
                                                     target:self
                                                   selector:@selector(animateHudOffPlayer)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)clearTimer
{
    [autoHideTimer invalidate];
    autoHideTimer = nil;
}

@end
