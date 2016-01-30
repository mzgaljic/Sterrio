
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

@interface MZPlayer ()
{
    id playbackObserver;
    AVPlayerLayer *playerLayer;
    UIVisualEffectView *visualEffectView;
    
    UIImageView *airplayLogoView;
    
    NSUInteger totalDuration;
    NSUInteger secondsLoaded;
    BOOL playbackStarted;
}

@property (strong, nonatomic, readwrite) AVPlayer *avPlayer;
@property (strong,nonatomic) UIView *controlsHud;

@property (strong, nonatomic) MPVolumeView *airplayButton;
@property (strong, nonatomic) SSBouncyButton *playPauseButton;
@property (strong, nonatomic) MZSlider *progressBar;
@property (strong, nonatomic) UILabel *elapsedTimeLabel;
@property (strong, nonatomic) UILabel *totalTimeLabel;

@property (strong, nonatomic) NSURL *videoURL;

@property (assign, nonatomic, readwrite) BOOL isPlaying;
@property (assign, nonatomic, readwrite) BOOL isInStall;
@property (assign, nonatomic, readwrite) BOOL playbackExplicitlyPaused;
@property (assign, nonatomic, readwrite) BOOL useControlsOverlay;

@property (weak, nonatomic) id <MZPreviewPlayerStallState> delegate;
@end
@implementation MZPlayer

const int CONTROLS_HUD_HEIGHT = 45;
const float AUTO_HIDE_HUD_DELAY = 4;
static BOOL isHudOnScreen = NO;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [playerLayer setFrame:frame];
    if(playbackStarted){
        [self setupControlsHud];
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
        playerLayer.backgroundColor = [[UIColor clearColor] CGColor];
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
    }
    return self;
}

- (void)setStallValueChangedDelegate:(id <MZPreviewPlayerStallState>)aDelegate
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

- (void)setupControlsHud
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
    if(self.playPauseButton == nil){
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
    
    int playBtnEdgePadding = 10;
    int playPauseBtnDiameter = CONTROLS_HUD_HEIGHT * 0.50;
    self.playPauseButton.frame = CGRectMake(playBtnEdgePadding,
                                            (CONTROLS_HUD_HEIGHT /2) - (playPauseBtnDiameter/2),
                                            playPauseBtnDiameter,
                                            playPauseBtnDiameter);
    
    totalDuration = CMTimeGetSeconds(self.avPlayer.currentItem.asset.duration);
    NSString *totalDurationString = [self convertSecondsToPrintableNSStringWithSliderValue:totalDuration];
    
    //Elapsed Time Label
    float fontSize = playPauseBtnDiameter * 0.85;
    if(self.elapsedTimeLabel == nil){
        self.elapsedTimeLabel = [[UILabel alloc] init];

        if(totalDurationString.length <= 4)
            self.elapsedTimeLabel.text = @"0:00";
        else if(totalDurationString.length == 5)
            self.elapsedTimeLabel.text = @"00:00";
        else
            self.elapsedTimeLabel.text = @"00:00:00";
        self.elapsedTimeLabel.textAlignment = NSTextAlignmentRight;
        self.elapsedTimeLabel.textColor = [UIColor whiteColor];
        self.elapsedTimeLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                     size:fontSize];
    }
    [self.elapsedTimeLabel sizeToFit];
    int buttonAndLabelPadding = playPauseBtnDiameter;
    self.elapsedTimeLabel.frame = CGRectMake(self.playPauseButton.frame.origin.x + playPauseBtnDiameter + buttonAndLabelPadding,
                                             (CONTROLS_HUD_HEIGHT /2) - (fontSize/2),
                                             self.elapsedTimeLabel.frame.size.width,
                                             self.elapsedTimeLabel.frame.size.height);
    
    //Total Duration Label
    if(self.totalTimeLabel == nil){
        self.totalTimeLabel = [[UILabel alloc] init];
        self.totalTimeLabel.text = totalDurationString;
        self.totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        self.totalTimeLabel.textColor = [UIColor whiteColor];
        self.totalTimeLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                   size:fontSize];
    }
    [self.totalTimeLabel sizeToFit];

    int airplayIconWidth = 25;
    int airPlayIconRightEdgePadding = playBtnEdgePadding;
    int widthSpacingFromTotalDurationLabelRightEdgeToFrameRightEdge = airPlayIconRightEdgePadding + airplayIconWidth + buttonAndLabelPadding;
    int labelAndSliderPadding = 5;
    int totalTimeLabelX = self.frame.size.width - widthSpacingFromTotalDurationLabelRightEdgeToFrameRightEdge - self.totalTimeLabel.frame.size.width + labelAndSliderPadding + 1;
    self.totalTimeLabel.frame = CGRectMake(totalTimeLabelX,
                                           (CONTROLS_HUD_HEIGHT /2) - (fontSize/2),
                                           self.totalTimeLabel.frame.size.width,
                                           self.totalTimeLabel.frame.size.height);
    
    //Seek Time Progress Bar
    int initialLayoutXCompensation = 0;
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
        initialLayoutXCompensation = -3;
    }
    int progressBarHeight = CONTROLS_HUD_HEIGHT/4;
    int xOrigin = self.elapsedTimeLabel.frame.origin.x + self.elapsedTimeLabel.frame.size.width + labelAndSliderPadding;
    int sliderWidth = self.frame.size.width - xOrigin - self.totalTimeLabel.frame.size.width - widthSpacingFromTotalDurationLabelRightEdgeToFrameRightEdge +1;
    int yOriginCompensation = 2;
    self.progressBar.frame = CGRectMake(xOrigin,
                                        (CONTROLS_HUD_HEIGHT /2) - (progressBarHeight/2) + yOriginCompensation,
                                        sliderWidth,
                                        progressBarHeight);
    
    //airplay button
    if(self.airplayButton == nil){
        self.airplayButton = [[MPVolumeView alloc] init];
        [self.airplayButton setShowsVolumeSlider:NO];        
        UIImage *airplayImg = [UIImage imageNamed:@"airplay_button"];
        UIImage *airplayNormalState = [UIImage colorOpaquePartOfImage:[UIColor whiteColor]
                                                                     :airplayImg];
        UIImage *airplayActiveState = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                    :airplayImg];
        
        [self.airplayButton setRouteButtonImage:airplayNormalState forState:UIControlStateNormal];
        [self.airplayButton setRouteButtonImage:airplayNormalState forState:UIControlStateHighlighted];
        [self.airplayButton setRouteButtonImage:airplayActiveState forState:UIControlStateSelected];
    }
    [self.airplayButton sizeToFit];
    self.airplayButton.frame = CGRectMake(self.totalTimeLabel.frame.origin.x + self.totalTimeLabel.frame.size.width - buttonAndLabelPadding/2,
                                          (CONTROLS_HUD_HEIGHT /2) - (self.airplayButton.frame.size.height/2),
                                          self.airplayButton.frame.size.width,
                                          self.airplayButton.frame.size.height);
    
    [self.controlsHud addSubview:self.playPauseButton];
    [self.controlsHud addSubview:self.elapsedTimeLabel];
    [self.controlsHud addSubview:self.progressBar];
    [self.controlsHud addSubview:self.totalTimeLabel];
    [self.controlsHud addSubview:self.airplayButton];

    
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
    [self setElapsedTimeLabelstringForSliderValue:currentTimeValue];
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
    [self setElapsedTimeLabelstringForSliderValue:sender.value];
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

//Slider helper stuff
- (void)setElapsedTimeLabelstringForSliderValue:(float)value
{
    self.elapsedTimeLabel.text = [self convertSecondsToPrintableNSStringWithSliderValue:value];
}

static NSString *secondsToStringReturn = @"";
static NSUInteger totalSeconds;
static NSUInteger totalMinutes;
static int seconds;
static int minutes;
static int hours;
- (NSString *)convertSecondsToPrintableNSStringWithSliderValue:(float)value
{
    totalSeconds = value;
    seconds = (int)(totalSeconds % MZSecondsInAMinute);
    totalMinutes = totalSeconds / MZSecondsInAMinute;
    minutes = (int)(totalMinutes % MZMinutesInAnHour);
    hours = (int)(totalMinutes / MZMinutesInAnHour);
    
    if(minutes < 10 && hours == 0)  //we can shorten the text
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
    else if(hours > 0)
    {
        if(hours <= 9)
            secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d:%02d",hours,minutes,seconds];
        else
            secondsToStringReturn = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes, seconds];
    }
    else
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    return secondsToStringReturn;
}

#pragma mark - Hud Control Button Targets
 -(void)playButtonTapped:(UIButton *)sender
{
    if (self.isPlaying){
        [self pause];
    }
    else{
        [self play];
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
                    
                    [self setupControlsHud];
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
