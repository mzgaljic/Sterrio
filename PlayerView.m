//
//  PlayerView.m
//  Muzic
//
//  Created by Mark Zgaljic on 11/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlayerView.h"
#import "SongPlayerViewController.h"
#import "PreviousNowPlayingInfo.h"
#import "PlayableItem.h"
#import "MZSlider.h"
#import "SongPlayerViewDisplayUtility.h"

@interface PlayerView ()
{
    CGPoint gestureStartPoint;
    BOOL userDidSwipeUp;
    BOOL userDidSwipeDown;
    BOOL userDidTap;
    UIInterfaceOrientation lastOrientation;
    int killSlideXBoundary;
    NSMutableArray *lastTouchesDirection;
    BOOL userDidSwipePlayerOffScreenManually;
    int xValueBeforeDrag;
    
    UIImageView *airplayMsgView;
    
    //for player hud in landscape mode
    NSUInteger totalDuration;
    NSUInteger secondsLoaded;
    UIVisualEffectView *visualEffectView;
    BOOL isHudOnScreen;
    BOOL isUserScrubbing;
}
//for player hud stuff in landscape mode
@property (strong,nonatomic) UIView *controlsHud;
@property (strong, nonatomic) MPVolumeView *mpVolumeView;
@property (strong, nonatomic) SSBouncyButton *playPauseButton;
@property (strong, nonatomic) MZSlider *progressBar;
@property (strong, nonatomic) UILabel *elapsedTimeLabel;
@property (strong, nonatomic) UILabel *totalTimeLabel;
@property (assign, nonatomic) NSUInteger elapsedTimeInSec;
@property (assign, nonatomic) BOOL useControlsOverlay;
@end
@implementation PlayerView

typedef enum {leftDirection, rightDirection} HorizontalDirection;

- (void)shrunkenFrameHasChanged
{
    xValueBeforeDrag = self.frame.origin.x;
}

#pragma mark - UIView lifecycle
- (id)init
{
    if (self = [super init]) {
        AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
        layer.masksToBounds = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationNeedsToChanged)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackOfVideoHasBegun)
                                                     name:@"PlaybackStartedNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(airplayDevicesAvailableChanged:)
                                                     name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                   object:nil];
        
        lastOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if(UIInterfaceOrientationIsLandscape(lastOrientation)
           && [SongPlayerCoordinator isVideoPlayerExpanded]) {
            _useControlsOverlay = YES;
            [self setupControlsHudCacheLabels:NO];
        }
        self.multipleTouchEnabled = NO;
        lastTouchesDirection = [NSMutableArray array];
        
        UITapGestureRecognizer *tap;
        UISwipeGestureRecognizer *up;
        UISwipeGestureRecognizer *down;
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(userTappedPlayer)];
        up = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(userSwipedUp)];
        down = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(userSwipedDown)];
        up.direction = UISwipeGestureRecognizerDirectionUp;
        down.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:tap];
        [self addGestureRecognizer:up];
        [self addGestureRecognizer:down];
    }
    return self;
}

- (void)dealloc
{
    _controlsHud = nil;
    visualEffectView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AVPlayer & AVPlayerLayer code
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)removeLayerFromPlayer
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    if([playerLayer player] != nil)
        [playerLayer setPlayer:nil];
}

- (UIImage *)screenshotOfPlayer
{
    return [self viewAsScreenshot];
}

- (void)reattachLayerToPlayer
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    if([playerLayer player] == nil) {
        //do a nice fade-in animation without any stutters/"flashes" on screen.
        __block UIView *blackPlaceHolder = [[UIView alloc] initWithFrame:self.frame];
        blackPlaceHolder.backgroundColor = [UIColor blackColor];
        [[UIApplication sharedApplication].keyWindow insertSubview:blackPlaceHolder
                                                      belowSubview:self];
        self.alpha = 0;
        [playerLayer setPlayer:[MusicPlaybackController obtainRawAVPlayer]];
        [UIView animateWithDuration:1.8
                              delay:0
                            options:UIViewAnimationOptionAllowAnimatedContent
                                    | UIViewAnimationOptionAllowUserInteraction
                                    | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             blackPlaceHolder.alpha = 0;
                             self.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             [blackPlaceHolder removeFromSuperview];
                             blackPlaceHolder = nil;
                         }];
    }
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

#pragma mark - Responding to getures
- (void)userSwipedUp
{
    userDidSwipeUp = YES;
    [self segueToPlayerViewControllerIfAppropriate:YES];
}

- (void)userSwipedDown
{
    userDidSwipeDown = YES;
    [self popPlayerViewControllerIfAppropriate];
}

- (void)userTappedPlayer
{
    userDidTap = YES;
    [self segueToPlayerViewControllerIfAppropriate:NO];
    
    if([SongPlayerCoordinator isVideoPlayerExpanded]
       && UIInterfaceOrientationIsLandscape(lastOrientation)) {
        if(_controlsHud == nil) {
            _useControlsOverlay = YES;
            [self setupControlsHudCacheLabels:NO];
        }
        [self userTappedPlayerView:gestureStartPoint];
    }
}

- (void)userKilledPlayer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldDismissPlayerExpandingTip"
                                                        object:@NO];
    
    if(! userDidSwipePlayerOffScreenManually){
        [self movePlayerOffScreenAndKillPlayback];
    }
    userDidSwipePlayerOffScreenManually = NO;
    Song *songWeAreKilling = [MusicPlaybackController nowPlayingSong];
    
    //This lets the tableview data sources figure out that there is no new song playing when
    //efficiently updating the tableview cells.
    [PreviousNowPlayingInfo setPreviousPlayableItem:[NowPlayingSong sharedInstance].nowPlayingItem];
    [[NowPlayingSong sharedInstance] setNewNowPlayingItem:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZNewSongLoading
                                                        object:songWeAreKilling];
    [self performSelector:@selector(resetLastPlayableItem) withObject:nil afterDelay:0.2];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player dismissAllSpinners];
    [player replaceCurrentItemWithPlayerItem:nil];
    [SongPlayerCoordinator playerWasKilled:YES];
    [[NowPlayingSong sharedInstance] setNewNowPlayingItem:nil];
    
    //reset player state to defaults
    [MusicPlaybackController explicitlyPausePlayback:NO];
    [SongPlayerCoordinator placePlayerInDisabledState:NO];
    [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
    [[MZPlaybackQueue sharedInstance] clearEntireQueue];
    
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlayingItem.songForItem];
}

- (void)resetLastPlayableItem
{
    [PreviousNowPlayingInfo setPreviousPlayableItem:nil];
}

#pragma mark - Airplay state stuff
- (void)showAirPlayInUseMsg:(BOOL)show
{
    if(show){
        if(airplayMsgView == nil){
            [self removeLayerFromPlayer];
            UIImage *airplayImg = [UIImage imageNamed:@"airplay"];
            airplayImg = [UIImage colorOpaquePartOfImage:[AppEnvironmentConstants appTheme].mainGuiTint
                                                        :airplayImg];
            
            airplayMsgView = [[UIImageView alloc] initWithImage:airplayImg];
            airplayMsgView.userInteractionEnabled = NO;

            MRProgressOverlayView *spinner = [MRProgressOverlayView overlayForView:self];
            if(spinner) {
                //i want the airplay logo above the playerview but under the spinner.
                [self insertSubview:airplayMsgView belowSubview:spinner];
            } else {
                [self addSubview:airplayMsgView];
            }
            
            airplayMsgView.center = [self convertPoint:self.center fromView:self.superview];
            CGRect originalImgViewFrame = airplayMsgView.frame;
            airplayMsgView.frame = CGRectMake(0,
                                               0,
                                               airplayMsgView.frame.size.width /6,
                                               airplayMsgView.frame.size.height /6);
            airplayMsgView.center = [self convertPoint:self.center fromView:self.superview];
            [UIView animateWithDuration:0.8
                                  delay:0
                 usingSpringWithDamping:0.75
                  initialSpringVelocity:0.3
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 airplayMsgView.frame = originalImgViewFrame;
                             }
                             completion:nil];
        }
    } else{
        if(airplayMsgView){
            CGRect originalFrame = airplayMsgView.frame;
            airplayMsgView.frame = CGRectMake(0,
                                               0,
                                               airplayMsgView.frame.size.width /4,
                                               airplayMsgView.frame.size.height /4);
            airplayMsgView.center = [self convertPoint:self.center fromView:self.superview];
            CGRect animationFrame = airplayMsgView.frame;
            airplayMsgView.frame = originalFrame;
            
            [self reattachLayerToPlayer];
            [self bringSubviewToFront:airplayMsgView];
            
            [UIView animateWithDuration:0.45
                                  delay:0
                 usingSpringWithDamping:1
                  initialSpringVelocity:0.3
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 airplayMsgView.frame = animationFrame;
                             }
                             completion:^(BOOL finished) {
                                 [airplayMsgView removeFromSuperview];
                                 airplayMsgView = nil;
                             }];
        }
    }
}

- (void)newAirplayInUseMsgCenter:(CGPoint)newCenter
{
    if(airplayMsgView){
        airplayMsgView.center = newCenter;
    }
}

#pragma mark - Orientation and view "touch" code
//used to help the touchesMoved method below get the swipe length
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    userDidSwipeUp = NO;
    userDidSwipeDown = NO;
    userDidTap = NO;
    
    UITouch *touch = [touches anyObject];
    gestureStartPoint = [touch locationInView:self];
    
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    killSlideXBoundary = screenWidth * 0.85;
    killSlideXBoundary = screenWidth - killSlideXBoundary;
    [lastTouchesDirection removeAllObjects];
}

//used to get a "length" for each swipe gesture
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(userDidSwipeUp || userDidSwipeDown || userDidTap ||
       [SongPlayerCoordinator isVideoPlayerExpanded])
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self];
    CGFloat deltaXX = (gestureStartPoint.x - currentPosition.x);  //positive = left
    
    if(lastTouchesDirection.count > 5)
        [lastTouchesDirection removeObjectAtIndex:0];
    if(deltaXX > 0)
        [lastTouchesDirection addObject:[NSNumber numberWithInt:leftDirection]];
    else
        [lastTouchesDirection addObject:[NSNumber numberWithInt:rightDirection]];
    
    //make view follow finger
    CGRect frame = self.frame;
    self.frame = CGRectMake(frame.origin.x - deltaXX,
                            frame.origin.y,
                            frame.size.width,
                            frame.size.height);
    float percentageTowardLeft;
    int xVal = self.frame.origin.x;
    percentageTowardLeft = xVal/(float)xValueBeforeDrag;
    if(percentageTowardLeft < 0.2)
        percentageTowardLeft = 0.2;
    self.alpha = percentageTowardLeft;
    [CATransaction flush];  //force immdiate redraw
}

//detects when view (this AVPlayer) was tapped (fires when touch is released)
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL playerExpanded = [SongPlayerCoordinator isVideoPlayerExpanded];
    if(userDidSwipeDown || userDidSwipeUp || userDidTap || playerExpanded){
        [lastTouchesDirection removeAllObjects];
        self.alpha = 1;
        return;
    }
    
    if(! playerExpanded && !userDidSwipeUp && !userDidSwipeDown && !userDidTap){
        BOOL endMotionSwipeLeft = NO;
        int count = 0;
        for(int i = 0; i < lastTouchesDirection.count; i++){
            if(i > 2)
                break;
            if([lastTouchesDirection[i] intValue] == leftDirection)
                count++;
        }
        if(count >= 2)
            endMotionSwipeLeft = YES;
        
        int screenWidth = [UIScreen mainScreen].bounds.size.width;
        
        //this will be the real "kill" boundary if the user let go
        //before reaching the real boundary and was heading in the direction
        //of the kill boundary.
        int motionBoundaryKill = screenWidth/2.5;
        if(lastOrientation == UIInterfaceOrientationPortrait ||
           lastOrientation == UIInterfaceOrientationPortraitUpsideDown)
            motionBoundaryKill = killSlideXBoundary;
        
        //user has moved player past "kill" boundary
        if((self.frame.origin.x <= killSlideXBoundary && endMotionSwipeLeft) ||
           (endMotionSwipeLeft && self.frame.origin.x <= motionBoundaryKill)){
            userDidSwipePlayerOffScreenManually = YES;
            //user wants to kill player
            [self movePlayerOffScreenAndKillPlayback];
        }else{
            //user changed his/her mind
            [self movePlayerBackToOriginalLocation];
            self.alpha = 1;
        }
    }
    [lastTouchesDirection removeAllObjects];
    userDidSwipeUp = NO;
    userDidSwipeDown = NO;
    userDidTap = NO;
}

//called during low memory events by system, etc
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL moveViewBack = YES;
    if(userDidSwipeDown || userDidSwipeUp || userDidTap)
        moveViewBack = NO;
    
    userDidSwipeUp = NO;
    userDidSwipeDown = NO;
    userDidTap = NO;
    
    //check if user tapped or swiped. if not, then just animate it back to its original
    //position...dont want to do something the user didnt want.
    if(moveViewBack)
        [self movePlayerBackToOriginalLocation];
    [lastTouchesDirection removeAllObjects];
}

- (void)movePlayerBackToOriginalLocation
{
    __weak PlayerView *weakSelf = self;
    [UIView animateWithDuration:0.85
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.56
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         if(lastOrientation == UIInterfaceOrientationPortrait ||
                            lastOrientation == UIInterfaceOrientationPortraitUpsideDown){
                             weakSelf.frame = [[SongPlayerCoordinator sharedInstance] smallPlayerFrameInPortrait];
                         } else{
                             weakSelf.frame = [[SongPlayerCoordinator sharedInstance] smallPlayerFrameInLandscape];
                         }
                     } completion:nil];
}

- (void)movePlayerOffScreenAndKillPlayback
{
    __weak PlayerView *weakSelf = self;
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    int width = weakSelf.frame.size.width;
    [UIView animateWithDuration:0.8
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         weakSelf.alpha = 0;
                         weakSelf.frame = CGRectMake(0 - width,
                                                     weakSelf.frame.origin.y,
                                                     weakSelf.frame.size.width,
                                                     weakSelf.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if(userDidSwipePlayerOffScreenManually)
                             [weakSelf userKilledPlayer];
                         //move frame back to bottom right so it looks the same
                         //the next time the player is opened
                         weakSelf.alpha = 0;
                         weakSelf.frame = CGRectMake(screenWidth + width/2,
                                                     weakSelf.frame.origin.y + (weakSelf.frame.size.height * 2) ,
                                                     weakSelf.frame.size.width,
                                                     weakSelf.frame.size.height);
                     }];
}

#pragma mark - Rotation
//will rotate the video ONLY when it is small.
//The SongPlayerViewController class handles the big video rotation.
- (void)orientationNeedsToChanged
{
    if(UIInterfaceOrientationIsLandscape(lastOrientation)) {
        _useControlsOverlay = NO;
        [self.controlsHud removeFromSuperview];
        [self.progressBar removeFromSuperview];
        self.controlsHud = nil;
        self.progressBar = nil;
        visualEffectView = nil;
        isHudOnScreen = NO;
    } else {
        if([SongPlayerCoordinator isVideoPlayerExpanded]) {
            _useControlsOverlay = YES;
            
            //setup hud with a delay. If not delayed, you can see the hud during the
            //rotation animation, which looks tacky.
            float delayInSeconds = 0.6;
            __weak PlayerView *weakself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [weakself setupControlsHudCacheLabels:NO];
            });
        }
    }
    
    lastOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if([SongPlayerCoordinator isVideoPlayerExpanded]) {
        return;   //don't touch the player when it is expanded
    } else{
        [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerNeedsToBeRotated];
    }
}

#pragma mark - Handling Poping and pushing of the player VC along with this view
- (void)segueToPlayerViewControllerIfAppropriate:(BOOL)swiped
{
    BOOL expandingNow = ![SongPlayerCoordinator isVideoPlayerExpanded];
    [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:[MZCommons topViewController]];
    if(expandingNow && UIInterfaceOrientationIsLandscape(lastOrientation)) {
        //want user to see the hud as soon as the player is opened in landscape.
        _useControlsOverlay = YES;
        if(swiped) {
            //the hud is set up if a user taps the playerView. If it hasn't been set up yet,
            //then they've swiped it up.
            [self performSelector:@selector(setUpControlsHudAndAnimateUp)
                       withObject:nil
                       afterDelay:0.3];
        }
    }
}

- (void)popPlayerViewControllerIfAppropriate
{
    if([SongPlayerCoordinator isVideoPlayerExpanded]){
        //same code as in MyAlerts...this code is better than
        UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
        SongPlayerViewController *vc =  (SongPlayerViewController *)[keyWindow visibleViewController];
        [vc preDealloc];
        BOOL animated = NO;
        if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
            animated = YES;
        
        [vc dismissViewControllerAnimated:animated completion:nil];
        [[SongPlayerCoordinator sharedInstance] beginShrinkingVideoPlayer];
        [self.controlsHud removeFromSuperview];
        [self.progressBar removeFromSuperview];
        self.controlsHud = nil;
        self.progressBar = nil;
        visualEffectView = nil;
        _useControlsOverlay = NO;
        isHudOnScreen = NO;
    }
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
- (void)userTappedPlayerView:(CGPoint)location
{
    if(isHudOnScreen && location.y >= self.controlsHud.frame.origin.y){
        return;
    }
    if(isHudOnScreen)
        [self animateHudOffPlayer];
    else
        [self animateHudOntoPlayer];
}

- (void)playCalled
{
    [self startAutoHideTimer];
    if(_elapsedTimeInSec == totalDuration){
        //start playback from beginning
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
    }
    [self.playPauseButton setSelected:NO];
}

- (void)pauseCalled
{
    if(! isUserScrubbing) {
        //this is the hack that was placed in to tie this in to the gui properly
        //(like if the user pauses from control center, etc.)
        //
        [self startAutoHideTimer];
    }
    [self.playPauseButton setSelected:YES];
}

//called by MusicPlaybackController so that we reuse that timeObserver (keeps things simple.)
- (void)updatePlaybackTimeSliderWithTimeValue:(Float64)currentTimeValue
{
    _elapsedTimeInSec = currentTimeValue;
    [self.progressBar setValue:(currentTimeValue) animated:YES];
    [self setElapsedTimeLabelstringForSliderValue:currentTimeValue];
}

- (void)progressBarEditingBegan:(UISlider *)sender
{
    isUserScrubbing = YES;
    [MusicPlaybackController explicitlyPausePlayback:YES];
    [MusicPlaybackController pausePlayback];
    [self clearTimer];
}

- (void)progressBarChanged:(UISlider *)sender
{
    _elapsedTimeInSec = sender.value;
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(! player.externalPlaybackActive) {
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithFloat:sender.value]];
    }
    [self setElapsedTimeLabelstringForSliderValue:sender.value];
}

- (void)progressBarChangeEnded:(UISlider *)sender
{
    isUserScrubbing = NO;
    _elapsedTimeInSec = sender.value;
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(player.externalPlaybackActive) {
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithFloat:sender.value]];
    }
    
    [MusicPlaybackController explicitlyPausePlayback:NO];
    [MusicPlaybackController resumePlayback];
    [self startAutoHideTimer];
}

//Slider helper stuff
- (void)setElapsedTimeLabelstringForSliderValue:(float)value
{
    self.elapsedTimeLabel.text = [SongPlayerViewDisplayUtility convertSecondsToPrintableNSStringWithSliderValue:value];
}

#pragma mark - Hud Control Button Targets
- (void)playButtonTapped:(UIButton *)sender
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(player.rate > 0) {
        [self startAutoHideTimer];
        [MusicPlaybackController pausePlayback];
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [self.playPauseButton setSelected:YES];
    } else {
        [self startAutoHideTimer];
        [MusicPlaybackController resumePlayback];
        [MusicPlaybackController explicitlyPausePlayback:NO];
        [self.playPauseButton setSelected:NO];
    }
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
        UIImage *pauseImage = [UIImage colorOpaquePartOfImage:[AppEnvironmentConstants appTheme].navBarToolbarTextTint
                                                             :[UIImage imageNamed:@"Pause"]];
        UIImage *playImage = [UIImage colorOpaquePartOfImage:[AppEnvironmentConstants appTheme].navBarToolbarTextTint
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
    
    Song *song = [NowPlayingSong sharedInstance].nowPlayingItem.songForItem;
    totalDuration = [song.duration integerValue];
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
        self.progressBar.minimumValue = 0;
        self.progressBar.minimumTrackTintColor = [[AppEnvironmentConstants appTheme].mainGuiTint lighterColor];
        self.progressBar.maximumTrackTintColor = [UIColor groupTableViewBackgroundColor];
        self.progressBar.continuous = YES;
    }
    self.progressBar.maximumValue = totalDuration;
    
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
        UIImage *airplayActiveState = [UIImage colorOpaquePartOfImage:[AppEnvironmentConstants appTheme].mainGuiTint
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


//this is the one called from the notification when the player starts, hence it forces the "play"
//state.
- (void)playbackOfVideoHasBegun
{
    if([SongPlayerCoordinator isVideoPlayerExpanded]) {
        //need to create new hud, the code to calculate the width of all the labels
        //and the slider is based on the video duration.
        UIView *oldHud = self.controlsHud;
        self.controlsHud = nil;
        [self setupControlsHudCacheLabels:NO];
        [oldHud removeFromSuperview];
        isHudOnScreen = NO;
    }
}

- (void)setUpControlsHudAndAnimateUp
{
    [self setupControlsHudCacheLabels:NO];
    isHudOnScreen = NO;
    [self userTappedPlayerView:self.center];
}

@end