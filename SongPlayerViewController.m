//
//  SongPlayerViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongPlayerViewController.h"
#import "PlayableItem.h"
#import "SDCAlertController.h"
#import <TUSafariActivity.h>
#import "SongPlayerViewDisplayUtility.h"

typedef enum{
    DurationLabelStateNotSet,
    DurationLabelStateMinutes,
    DurationLabelStateHours
} DurationLabelStates;

typedef enum{
    GUIPlaybackStatePlaying,
    GUIPlaybackStatePaused
} GUIPlaybackState;


@interface SongPlayerViewController ()
{
    IBActionSheet *popup;
    
    NSArray *musicButtons;
    SSBouncyButton *playButton;
    SSBouncyButton *forwardButton;
    SSBouncyButton *backwardButton;
    SSBouncyButton *timerButton;
    SSBouncyButton *repeatModeButton;
    SSBouncyButton *shuffleModeButton;
    
    GCDiscreetNotificationView *sliderHint;  //slider hint
    
    CMTime lastScrubbingSeekTime;
    
    BOOL playerButtonsSetUp;
    DurationLabelStates stateOfDurationLabels;
    GUIPlaybackState stateOfGUIPlayback;
    UIColor *colorOfPlaybackButtons;
    
    BOOL firstTimeUpdatingSliderSinceShowingPlayer;
    BOOL deferTimeLabelAdjustmentUntilPortrait;

    int extraStatusBarHeight;
    int totalVideoDuration;
    //int mostRecentLoadedDuration;  unneeded for now. Used in observeValueForKeyPath
}
@end

@implementation SongPlayerViewController
@synthesize navBar, currentTimeLabel = _currentTimeLabel,totalDurationLabel = _totalDurationLabel, playbackSlider = _playbackSlider;

static UIInterfaceOrientation lastKnownOrientation;
static BOOL playAfterMovingSlider = YES;
static BOOL sliderIsBeingTouched = NO;
static BOOL waitingForNextOrPrevVideoToLoad;
static BOOL isPlayerOnExternalDisplayWhileScrubbing = NO;
static const short longDurationLabelOffset = 24;
static int numTimesSetupKeyValueObservers = 0;

NSString * const CURRENT_SONG_DONE_PLAYING = @"Current item has finished, update gui please!";
NSString * const CURRENT_SONG_STOPPED_PLAYBACK = @"playback has stopped for some unknown reason (stall?)";
NSString * const CURRENT_SONG_RESUMED_PLAYBACK = @"playback has resumed from a stall probably";

NSString * const PAUSE_IMAGE = @"Pause";
NSString * const PLAY_IMAGE = @"Play";
NSString * const FORWARD_IMAGE = @"Forward";
NSString * const BACKWARD_IMAGE = @"Backward";

NSString * const TIMER_INACTIVE = @"timer_inactive";
NSString * const TIMER_ACTIVE = @"timer_active";

//key value observing (AVPlayer)
static void *kCurrentItemDidChangeKVO  = &kCurrentItemDidChangeKVO;
static void *kRateDidChangeKVO         = &kRateDidChangeKVO;
static void *kStatusDidChangeKVO       = &kStatusDidChangeKVO;
static void *kDurationDidChangeKVO     = &kDurationDidChangeKVO;
static void *kTimeRangesKVO            = &kTimeRangesKVO;

static void *kTotalDurationLabelDidChange = &kTotalDurationLabelDidChange;

#pragma mark - VC Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [SongPlayerCoordinator playerWasKilled:NO];
    
    //clear out garbage values from storyboard
    _songNameLabel.text = nil;
    _artistAndAlbumLabel.text = nil;
    
    firstTimeUpdatingSliderSinceShowingPlayer = YES;
    colorOfPlaybackButtons = [AppEnvironmentConstants appTheme].mainGuiTint;
    waitingForNextOrPrevVideoToLoad = YES;
    [self initAndRegisterAllButtons];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateScreenWithInfoForNewSong:)
                                                 name:MZNewSongLoading
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackOfVideoHasBegun)
                                                 name:@"PlaybackStartedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentSongInQueueHasEndedPlayback)
                                                 name:CURRENT_SONG_DONE_PLAYING
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackHasStopped)
                                                 name:CURRENT_SONG_STOPPED_PLAYBACK
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackHasResumed)
                                                 name:CURRENT_SONG_RESUMED_PLAYBACK
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerMustDisplayDisabledState:)
                                                 name:MZInterfaceNeedsToBlockCurrentSongPlayback
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(killTimeObserver)
                                                 name:MZAppWasBackgrounded
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restoreTimeObserver)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerControlsShouldBeUpdated)
                                                 name:MZAVPlayerStallStateChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateSleepTimerIcon)
                                                 name:TIMER_IMG_NEEDS_UPDATE
                                               object:nil];
    [[SongPlayerCoordinator sharedInstance] setDelegate:self];
    
    _currentTimeLabel.text = @"0:00";
    _totalDurationLabel.text = @"00:00";
    _currentTimeLabel.textColor = [UIColor blackColor];
    _totalDurationLabel.textColor = [UIColor blackColor];
    self.navBar.title = [MusicPlaybackController prettyPrintNavBarTitle];
    
    extraStatusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    if(extraStatusBarHeight >= [AppEnvironmentConstants regularStatusBarHeightPortrait]) {
        extraStatusBarHeight -= [AppEnvironmentConstants regularStatusBarHeightPortrait];
    }
    
    //app crashes shortly after dismissing this VC if the share sheet was selected. Need
    //this if statement!
    if(numTimesSetupKeyValueObservers == 0)
        [self setupKeyvalueObservers];
    numTimesSetupKeyValueObservers++;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                           target:self
                                                                           action:@selector(shareButtonTapped)];
    UIBarButtonItem *queue = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"queue"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(viewPlaybackQueue)];
    NSArray *rightBarBtns = @[share, queue];
    self.navigationItem.rightBarButtonItems = rightBarBtns;
    UIImage *downBtnImg = [UIImage imageNamed:@"UIButtonBarArrowDown"];
    UIBarButtonItem *downBtn = [[UIBarButtonItem alloc] initWithImage:downBtnImg
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(dismissVCButtonTapped)];
    self.navigationItem.leftBarButtonItem = downBtn;
    
    BOOL positionedSliderAlready = NO;
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)){
        [self positionMusicButtonsOnScreenAndSetThemUp];
        [self positionPlaybackSliderOnScreen];
        positionedSliderAlready = YES;
    }
    
    [self checkInterfaceOrientation];
    if(! positionedSliderAlready)
        [self positionPlaybackSliderOnScreen];
    
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        [self InitSongInfoLabelsOnScreenAnimated:NO onRotation:NO];
    }
    
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    
    //check if at least 1 second of video has loaded. If so, we should consider the video as
    //playing back, or at least trying to. We can then enable or disable the slider accordingly.
    BOOL playbackUnderway = NO;
    NSArray * timeRanges = player.currentItem.loadedTimeRanges;
    if (timeRanges && [timeRanges count]){
        CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
        NSUInteger secondsBuffed = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
        if(secondsBuffed > 0){
            playbackUnderway = YES;
        }
    }
    if(! playbackUnderway){
        [_playbackSlider setMaximumValue:0];
        [_playbackSlider setValue:0];
        _playbackSlider.enabled = NO;
    }
    
     //make sure slider hint view is at the same height as the nav bar...only in portrait
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
        [self setupSliderHintView];
    UIColor *niceGrey = [[UIColor alloc] initWithRed:106.0/255
                                               green:114.0/255
                                                blue:121.0/255
                                               alpha:1];
    _artistAndAlbumLabel.textColor = niceGrey;
    [self setNeedsStatusBarAppearanceUpdate];
    
    if([MusicPlaybackController avplayerTimeObserver] == nil){
        [self restoreTimeObserver];
        firstTimeUpdatingSliderSinceShowingPlayer = YES;
    }
    
    [self displayTotalSliderAndLabelDuration];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkIfInterfaceShouldBeDisabled];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
    numTimesSetupKeyValueObservers--;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([SongPlayerViewController class]));
}

- (void)preDealloc
{
    if([MusicPlaybackController avplayerTimeObserver] != nil) {
            [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:[MusicPlaybackController avplayerTimeObserver]];
    }
    
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
    [self removeObservers];
    sliderHint = nil;
    _totalDurationLabel = nil;
    _currentTimeLabel = nil;
    self.navBar = nil;
    self.playbackSlider = nil;
    self.songNameLabel = nil;
    self.artistAndAlbumLabel = nil;
    numTimesSetupKeyValueObservers = 0;
    accomodateInterfaceLabelsCounter = 0;
}

#pragma mark - Check and update GUI based on device orientation (or responding to events)
//NOT the same as updating the lock screen. this is specifically the info shown
//in this VC (song name, updating song index, etc)
- (void)updateScreenWithInfoForNewSong:(NSNotification *)object
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.8;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [_songNameLabel.layer addAnimation:animation
                                forKey:@"changeTextTransition"];
    [_artistAndAlbumLabel.layer addAnimation:animation
                                      forKey:@"changeTextTransition"];
     
    
    [self.navigationController.navigationBar.layer addAnimation:animation
                                                         forKey:@"changeTextTransition"];

    BOOL prevArtistLabelHadATextValue = ([_artistAndAlbumLabel.text length] > 0);
    _artistAndAlbumLabel.text = [self generateArtistAndAlbumString];
    self.navBar.title = [MusicPlaybackController prettyPrintNavBarTitle];
    _songNameLabel.text = [MusicPlaybackController nowPlayingSong].songName;
    
    CGRect playerFrame = [[SongPlayerCoordinator sharedInstance] currentPlayerViewFrame];
    if(playerFrame.size.height != [UIScreen mainScreen].bounds.size.height){
        //currently in portrait mode, can show new frame
        if([_artistAndAlbumLabel.text length] > 0)
            [self configureSongAndArtistAlbumLabelFramesAnimated:YES onRotation:NO];
        else{
            if(prevArtistLabelHadATextValue)
                [self configureSongAndArtistAlbumLabelFramesAnimated:YES onRotation:NO];
            else
                [self configureSongAndArtistAlbumLabelFramesAnimated:NO onRotation:NO];
        }
    }
    
    [self displayTotalSliderAndLabelDuration];
}

- (void)setupSliderHintView
{
    [sliderHint setBoldTextFontName:[AppEnvironmentConstants boldFontName]];
    short statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    short navBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    int yOrigin;
    //if the status bar is expanded (in a call, using navigation, etc.), we need to adjust frame.
    if([UIApplication sharedApplication].statusBarFrame.size.height > [AppEnvironmentConstants regularStatusBarHeightPortrait]) {
        yOrigin = navBarHeight - statusBarHeight;
    } else {
        yOrigin = navBarHeight + statusBarHeight;
    }
    CGRect frame = self.sliderHintView.frame;
    CGRect newFrame = CGRectMake(frame.origin.x,
                                 yOrigin,
                                 frame.size.width,
                                 frame.size.height);
    self.sliderHintView.frame = newFrame;
}

- (void)checkInterfaceOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self.navigationController setNavigationBarHidden:NO];
    lastKnownOrientation = orientation;
}

- (BOOL)prefersStatusBarHidden
{
    if(UIInterfaceOrientationIsLandscape(lastKnownOrientation)){
        [self.navigationController setNavigationBarHidden:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        return YES;
    }
    else{
        [self.navigationController setNavigationBarHidden:NO];
        return NO;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(playerButtonsSetUp == NO){
        [self positionMusicButtonsOnScreenAndSetThemUp];
        [self positionPlaybackSliderOnScreen];
    }
    if(deferTimeLabelAdjustmentUntilPortrait){
        deferTimeLabelAdjustmentUntilPortrait = NO;
        [self accomodateInterfaceBasedOnDurationLabelSize:self.totalDurationLabel];
    }
    if(! UIInterfaceOrientationIsPortrait(fromInterfaceOrientation))
        [self setupSliderHintView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    _sliderHintView.hidden = YES;
    short cancelButtonIndex = 2;
    [popup dismissWithClickedButtonIndex:cancelButtonIndex animated:NO];
    
    if(UIInterfaceOrientationIsLandscape(lastKnownOrientation)
       && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        return; //we dont need to do anything, video player should still remain full screen.
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        CGRect newFrame = CGRectMake(0, 0, ceil(screenHeight +1), screenWidth);
        [[SongPlayerCoordinator sharedInstance] recordCurrentPlayerViewFrame:newFrame];
        [playerView setFrame:newFrame];  //make frame full screen
    }
    else{
        //show portrait player
        float widthOfScreenRoationIndependant;
        float heightOfScreenRotationIndependant;
        float  a = [[UIScreen mainScreen] bounds].size.height;
        float b = [[UIScreen mainScreen] bounds].size.width;
        if(a < b)
        {
            heightOfScreenRotationIndependant = b;
            widthOfScreenRoationIndependant = a;
        }
        else
        {
            widthOfScreenRoationIndependant = b;
            heightOfScreenRotationIndependant = a;
        }
        float videoFrameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
        float playerFrameYTempValue = roundf(((heightOfScreenRotationIndependant / 2.0) /1.5));
        int playerYValue = nearestEvenInt((int)playerFrameYTempValue);
        CGRect newFrame = CGRectMake(0,
                                     playerYValue,
                                     widthOfScreenRoationIndependant,
                                     videoFrameHeight);
        [[SongPlayerCoordinator sharedInstance] recordCurrentPlayerViewFrame:newFrame];
        [playerView setFrame:newFrame];

        [self positionMusicButtonsOnScreenAndSetThemUp];
        [self positionPlaybackSliderOnScreen];
    }
    
    lastKnownOrientation = toInterfaceOrientation;
    [self setNeedsStatusBarAppearanceUpdate];
    [self performSelector:@selector(initLabelsOnScreenDelayed)
               withObject:nil
               afterDelay:0.05f];
    
    CGPoint newCenter = [playerView convertPoint:playerView.center
                             fromCoordinateSpace:playerView.superview];
    [playerView newAirplayInUseMsgCenter:newCenter];
}

- (void)initLabelsOnScreenDelayed
{
    [self InitSongInfoLabelsOnScreenAnimated:YES onRotation:YES];
}

#pragma mark - Responding to player playback events (rate, internet connection, etc.) Slider and labels.
- (IBAction)playbackSliderEditingHasBegun:(id)sender
{
    BOOL dontShowHint = NO;
    //if the status bar is expanded (in a call, using navigation, etc.) don't show hint.
    if([UIApplication sharedApplication].statusBarFrame.size.height > [AppEnvironmentConstants regularStatusBarHeightPortrait]) {
        dontShowHint = YES;
    }
    
    NSString *hint = @"Slide ↑ or ↓ for more accuracy.";
    int presentationMode = GCDiscreetNotificationViewPresentationModeTop;
    if(!dontShowHint) {
        [sliderHint removeFromSuperview];
        sliderHint = nil;
        sliderHint = [[GCDiscreetNotificationView alloc] initWithText:hint
                                                         showActivity:NO
                                                   inPresentationMode:presentationMode
                                                               inView:_sliderHintView];
    }

    if(sliderHint && !dontShowHint) {
        _sliderHintView.hidden = NO;
        [sliderHint showAnimated];
    }
    
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player.rate == 0)
        playAfterMovingSlider = NO;
    sliderIsBeingTouched = YES;
    [player pause];
    [MusicPlaybackController explicitlyPausePlayback:YES];
    [self toggleDisplayToPausedState];
    if(player.isExternalPlaybackActive)
        isPlayerOnExternalDisplayWhileScrubbing = YES;
}
- (IBAction)playbackSliderEditingHasEndedA:(id)sender  //touch up inside
{
    sliderIsBeingTouched = NO;
    if(playAfterMovingSlider){
        [[MusicPlaybackController obtainRawAVPlayer] play];
        [MusicPlaybackController explicitlyPausePlayback:NO];
    }
    playAfterMovingSlider = YES;  //reset value
    
    [sliderHint hideAnimated];
    
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlayingItem.songForItem];
    [self playerControlsShouldBeUpdated];
    
    if(isPlayerOnExternalDisplayWhileScrubbing)
        [[MusicPlaybackController obtainRawAVPlayer] seekToTime:lastScrubbingSeekTime];
}
- (IBAction)playbackSliderEditingHasEndedB:(id)sender  //touch up outside
{
    [self playbackSliderEditingHasEndedA:nil];
}

- (IBAction)playbackSliderValueHasChanged:(id)sender
{
    CMTime newTime = CMTimeMakeWithSeconds(_playbackSlider.value, NSEC_PER_SEC);
    if(! isPlayerOnExternalDisplayWhileScrubbing)
        [[MusicPlaybackController obtainRawAVPlayer] seekToTime:newTime];
    lastScrubbingSeekTime = newTime;
}

- (void)updatePlaybackTimeSliderWithTimeValue:(Float64)currentTimeValue
{
    _currentTimeLabel.text = [SongPlayerViewDisplayUtility convertSecondsToPrintableNSStringWithSliderValue:currentTimeValue];
    
    if(sliderIsBeingTouched)
        return;
    
    //sets slider directly from avplayer. playback can stutter or pause, so we can't just increment by 1...
    if(firstTimeUpdatingSliderSinceShowingPlayer)
        [self.playbackSlider setValue:(currentTimeValue) animated:NO];
    else{
        [_playbackSlider setValue:(currentTimeValue) animated:YES];
    }
    
    firstTimeUpdatingSliderSinceShowingPlayer = NO;
}

static int accomodateInterfaceLabelsCounter = 0;
- (void)accomodateInterfaceBasedOnDurationLabelSize:(UILabel *)changedLabel
{
    if(lastKnownOrientation ==  UIInterfaceOrientationLandscapeLeft ||
       lastKnownOrientation == UIInterfaceOrientationLandscapeRight){
        //here i am using this to find out if this is the first time the view has appeared
        if(accomodateInterfaceLabelsCounter == 0){
            deferTimeLabelAdjustmentUntilPortrait = YES;
            accomodateInterfaceLabelsCounter++;
            return;
        }
    }
    //duration state not set yet, and we are displaying minutes.
    if(stateOfDurationLabels == DurationLabelStateNotSet && [changedLabel.text length] <= 5){
        stateOfDurationLabels = DurationLabelStateMinutes;
        return;
        //dont need to check for the oppsosite condition here because it works already for hours.
    }
    
    UILabel *label = changedLabel;
    short offset = longDurationLabelOffset;
    CGRect originalCurrTimeLabelFrame = _currentTimeLabel.frame;
    CGRect newCurrTimeLabelFrame;
    CGRect originalTotalTimeLabelFrame = _totalDurationLabel.frame;
    CGRect newTotalTimeLabelFrame;
    CGRect originalSliderFrame = _playbackSlider.frame;
    CGRect newSliderFrame;
    
    if([label.text length] > 5){
        //displaying hours
        if(stateOfDurationLabels == DurationLabelStateHours)
            return;
        stateOfDurationLabels = DurationLabelStateHours;
        
        //shrink all items on screen, regardless of which label is showing the hours
        newCurrTimeLabelFrame = CGRectMake(originalCurrTimeLabelFrame.origin.x,
                                           originalCurrTimeLabelFrame.origin.y,
                                           originalCurrTimeLabelFrame.size.width + offset,
                                           originalCurrTimeLabelFrame.size.height);
        newTotalTimeLabelFrame = CGRectMake(originalTotalTimeLabelFrame.origin.x - offset,
                                            originalTotalTimeLabelFrame.origin.y,
                                            originalTotalTimeLabelFrame.size.width + offset,
                                            originalTotalTimeLabelFrame.size.height);
        newSliderFrame = CGRectMake(originalSliderFrame.origin.x + offset,
                                    originalSliderFrame.origin.y,
                                    originalSliderFrame.size.width - offset * 2,
                                    originalSliderFrame.size.height);
    } else{
        //displaying only minutes
        if(stateOfDurationLabels == DurationLabelStateMinutes)
            return;
        stateOfDurationLabels = DurationLabelStateMinutes;
        
        newCurrTimeLabelFrame = CGRectMake(originalCurrTimeLabelFrame.origin.x,
                                           originalCurrTimeLabelFrame.origin.y,
                                           originalCurrTimeLabelFrame.size.width - offset,
                                           originalCurrTimeLabelFrame.size.height);
        newTotalTimeLabelFrame = CGRectMake(originalTotalTimeLabelFrame.origin.x + offset,
                                            originalTotalTimeLabelFrame.origin.y,
                                            originalTotalTimeLabelFrame.size.width - offset,
                                            originalTotalTimeLabelFrame.size.height);
        newSliderFrame = CGRectMake(originalSliderFrame.origin.x - offset,
                                    originalSliderFrame.origin.y,
                                    originalSliderFrame.size.width + offset * 2,
                                    originalSliderFrame.size.height);
    }
    [_playbackSlider removeConstraints:_playbackSlider.constraints];
    [_playbackSlider setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _currentTimeLabel.frame = newCurrTimeLabelFrame;
        _totalDurationLabel.frame = newTotalTimeLabelFrame;
        _playbackSlider.frame = newSliderFrame;
    } completion:nil];
}

- (void)playbackHasStopped
{
    [self toggleDisplayToPausedState];
}

- (void)playbackHasResumed
{
    [self toggleDisplayToPlayingState];
    playButton.enabled = YES;  //in case it isnt
}

- (void)currentSongInQueueHasEndedPlayback
{
    BOOL moreSongsInQueue = ([MusicPlaybackController numMoreSongsInQueue] != 0);
    //disabling until the next song in the queue is loaded.
    //another method will reenable it when necessary
    if(moreSongsInQueue)
        self.playbackSlider.enabled = NO;
    else{
        //this is the last song anyway, slider can remain active.
        self.playbackSlider.enabled = YES;
    }
}


- (void)playerMustDisplayDisabledState:(NSNotification *)notif
{
    //the actual play and pause logic is done in a similar  method in the AVPlayer itself.
    //this is just forcing the GUI to represent the current state accurately.
    if([notif.name isEqualToString:MZInterfaceNeedsToBlockCurrentSongPlayback]){
        NSNumber *val = (NSNumber *)notif.object;
        BOOL disabled = [val boolValue];
        if(disabled){
            [self disableGUI];
        } else{
            [self reenablingGUI];
            //there was a bug where the total duration label would not get set in a specific case.
            [self displayTotalSliderAndLabelDuration];
            [_playbackSlider setEnabled:YES];
        }
    }
}

- (void)disableGUI
{
    [self toggleDisplayToPausedState];
    [playButton setEnabled:NO];
    [self.playbackSlider setEnabled:NO];
}

- (void)reenablingGUI
{
    if([SongPlayerCoordinator wasPlayerInPlayStateBeforeGUIDisabled]){
        [self toggleDisplayToPlayingState];
    }
    [playButton setEnabled:YES];
    if(! waitingForNextOrPrevVideoToLoad)
        [self.playbackSlider setEnabled:YES];
}

- (void)checkIfInterfaceShouldBeDisabled
{
    if([SongPlayerCoordinator isPlayerInDisabledState]){
        NSNotification *notif;
        notif = [[NSNotification alloc] initWithName:MZInterfaceNeedsToBlockCurrentSongPlayback
                                              object:[NSNumber numberWithBool:YES]
                                            userInfo:nil];
        [self playerMustDisplayDisabledState:notif];
    }
}

//same thing as method beneath this one, except the playback state is not touched
- (void)playbackOfVideoHasBegunRespectPlayPauseState
{
    self.playbackSlider.enabled = YES;
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    
    //want to make the gui respect the current playback state here
    if(player.rate == 1){
        UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE];
        UIImage *pauseImg = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
        [playButton setImage:pauseImg forState:UIControlStateNormal];
    } else{
        UIImage *tempImage = [UIImage imageNamed:PLAY_IMAGE];
        UIImage *playImg = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
        [playButton setImage:playImg forState:UIControlStateNormal];
    }
    
    NSUInteger test = CMTimeGetSeconds(player.currentItem.currentTime);
    if(player.currentItem)
        [_playbackSlider setValue:test animated:NO];
    else
        [_playbackSlider setValue:0];
    waitingForNextOrPrevVideoToLoad = NO;
}

//this is the one called from the notification when the player starts, hence it forces the "play" state.
- (void)playbackOfVideoHasBegun
{
    self.playbackSlider.enabled = YES;
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player.currentItem)
        [_playbackSlider setValue:CMTimeGetSeconds(player.currentItem.currentTime) animated:YES];
    else
        [_playbackSlider setValue:0];
    waitingForNextOrPrevVideoToLoad = NO;
    UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE];
    UIImage *pauseImg = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
    
    [playButton setImage:pauseImg forState:UIControlStateNormal];
    [MusicPlaybackController explicitlyPausePlayback:NO];
}

#pragma mark - Initializing & Registering Buttons
- (void)initAndRegisterAllButtons
{
    backwardButton = [[SSBouncyButton alloc] initAsImage];
    playButton = [[SSBouncyButton alloc] initAsImage];
    forwardButton = [[SSBouncyButton alloc] initAsImage];
    timerButton = [[SSBouncyButton alloc] initAsImage];
    repeatModeButton = [[SSBouncyButton alloc] init];
    repeatModeButton.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                       size:repeatModeButton.titleLabel.font.pointSize];
    shuffleModeButton = [[SSBouncyButton alloc] init];
    shuffleModeButton.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                        size:repeatModeButton.titleLabel.font.pointSize];
    
    [backwardButton addTarget:self
                       action:@selector(backwardsButtonTappedOnce)
             forControlEvents:UIControlEventTouchUpInside];
    [playButton addTarget:self
                   action:@selector(playOrPauseButtonTapped)
         forControlEvents:UIControlEventTouchUpInside];
    [forwardButton addTarget:self
                      action:@selector(forwardsButtonTappedOnce)
            forControlEvents:UIControlEventTouchUpInside];
    [timerButton addTarget:self
                    action:@selector(timerButtonTappedOnce)
          forControlEvents:UIControlEventTouchUpInside];
    [repeatModeButton addTarget:self
                         action:@selector(repeatModeButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [shuffleModeButton addTarget:self
                          action:@selector(shuffleModeButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];
    [self updateRepeatButtonGivenNewRepeatState];
    [self updateShuffleButtonGivenNewShuffleState];
    
    musicButtons = @[backwardButton, playButton, forwardButton];
}

#pragma mark - Positioning Music Buttons (buttons need to be initialized first)
//This method also fades the buttons and the time labels back into place on rotation
- (void)positionMusicButtonsOnScreenAndSetThemUp
{
    if(playerButtonsSetUp == YES){
        //dont need to set them up, just re-animate a "fade in"
        for(UIButton *aButton in musicButtons){
            aButton.alpha = 0.0;  //make button transparent
            [UIView animateWithDuration:0.7  //now animate a "fade in"
                                  delay:0.2
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                             animations:^{ aButton.alpha = 1.0; }
                             completion:nil];
        }
        
        _currentTimeLabel.alpha = 0.0;
        _totalDurationLabel.alpha = 0.0;
        [UIView animateWithDuration:0.7  //now animate a "fade in"
                              delay:0.2
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                         animations:^
                        {
                            _currentTimeLabel.alpha = 1.0;
                            _totalDurationLabel.alpha = 1.0;
                        }
                         completion:nil];
    }
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft
       || orientation == UIInterfaceOrientationLandscapeRight)
        return;
    
    //make images fill up frame, change button hit area
    for(UIButton *aButton in musicButtons){
        aButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        aButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        [aButton setHitTestEdgeInsets:UIEdgeInsetsMake(-15, -15, -15, -15)];
    }
    
    float percentDownScreen = 0.84f;
    float yValue, xValue;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    UIColor *buttonTint = [UIColor blackColor];
    
    //play button or pause button
    UIImage *playBtnImage;
    if([MusicPlaybackController obtainRawAVPlayer].rate == 0)
        playBtnImage = [UIImage colorOpaquePartOfImage:buttonTint
                                                      :[UIImage imageNamed:PLAY_IMAGE]];
    else
        playBtnImage = [UIImage colorOpaquePartOfImage:buttonTint
                                                      :[UIImage imageNamed:PAUSE_IMAGE]];
    
    [playButton setImage:playBtnImage forState:UIControlStateNormal];
    float playButtonWidth = playBtnImage.size.width;
    float playButtonHeight = playBtnImage.size.height;
    //want the play button to be 84% of the way down the screen
    yValue = round(screenHeight * percentDownScreen);
    yValue -= extraStatusBarHeight;
    
    //+1 is just for visual offset. code is perfect without it but the +1 makes it FEEL better.
    xValue = (screenWidth/2) - (playButtonWidth/2)+1;
    playButton.frame = CGRectMake(xValue, yValue, playButtonWidth, playButtonHeight);
    
    //seek backward button
    UIImage *backImg = [UIImage colorOpaquePartOfImage:buttonTint
                                                      :[UIImage imageNamed:BACKWARD_IMAGE]];
    
    float backwardButtonWidth = backImg.size.width;
    float backwardButtonHeight = backImg.size.height;
    //will be in between the play button and left side of screen
    xValue = ((screenWidth/2)/2) - backwardButtonWidth/2;
    yValue = playButton.center.y - backwardButtonHeight/2;
    backwardButton.frame = CGRectMake(xValue-3, yValue -1, backwardButtonWidth, backwardButtonHeight);
    [backwardButton setImage:backImg forState:UIControlStateNormal];
    
    //seek forward button
    UIImage *forwardImg = [UIImage colorOpaquePartOfImage:buttonTint
                                                         :[UIImage imageNamed:FORWARD_IMAGE]];
    
    float forwardButtonWidth = forwardImg.size.width;
    float forwardButtonHeight = forwardImg.size.height;
    //will be in between the play button and right side of screen
    xValue = ((screenWidth /2) + ((screenWidth/2)/2) - forwardButtonWidth/2);
    yValue = playButton.center.y - forwardButtonHeight/2;
    forwardButton.frame = CGRectMake(xValue +3, yValue -1, forwardButtonWidth, forwardButtonHeight);
    [forwardButton setImage:forwardImg forState:UIControlStateNormal];
    
    //timer button
    NSString *btnImgName;
    if([AppEnvironmentConstants isPlaybackTimerActive])
        btnImgName = TIMER_ACTIVE;
    else
        btnImgName = TIMER_INACTIVE;
    short paddingFromScreenBottom = 5;
    UIColor *appTint = [AppEnvironmentConstants appTheme].contrastingTextColor;
    UIImage *timerImg = [UIImage colorOpaquePartOfImage:appTint :[UIImage imageNamed:btnImgName]];
    CGRect timerBtnFrame = CGRectMake(screenWidth/2 - timerImg.size.width/2,
                                      screenHeight - timerImg.size.height - paddingFromScreenBottom - extraStatusBarHeight,
                                      timerImg.size.width,
                                      timerImg.size.height);
    timerButton.frame = timerBtnFrame;
    timerButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [timerButton setImage:timerImg forState:UIControlStateNormal];
    timerButton.alpha = 0;
    [timerButton setHitTestEdgeInsets:UIEdgeInsetsMake(-20, -30, -15, -30)];
    [self.view addSubview:timerButton];
    [UIView animateWithDuration:0.70  //now animate a "fade in"
                          delay:0.1
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^{ timerButton.alpha = 1.0; }
                     completion:nil];
    
    //repeat mode button
    short bottomTextButtonsWidth = 90;
    short bottomTextButtonsHeight = 30;
    repeatModeButton.center = timerButton.center;
    CGRect repeatModeBtnFrame = CGRectMake(screenWidth/3.5 - bottomTextButtonsWidth,
                                           repeatModeButton.frame.origin.y - bottomTextButtonsHeight/2,
                                           bottomTextButtonsWidth,
                                           bottomTextButtonsHeight);
    repeatModeButton.frame = repeatModeBtnFrame;
    repeatModeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    repeatModeButton.tintColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
    repeatModeButton.alpha = 0;
    [repeatModeButton setHitTestEdgeInsets:UIEdgeInsetsMake(-15, -25, -15, -25)];
    [self.view addSubview:repeatModeButton];
    [UIView animateWithDuration:0.70  //now animate a "fade in"
                          delay:0.1
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^{ repeatModeButton.alpha = 1.0; }
                     completion:nil];
    
    //shuffle mode button
    shuffleModeButton.center = timerButton.center;
    int repeatXStart = repeatModeBtnFrame.origin.x;
    CGRect shuffleModeBtnFrame = CGRectMake(screenWidth - repeatXStart - bottomTextButtonsWidth,
                                           repeatModeBtnFrame.origin.y,
                                           bottomTextButtonsWidth,
                                           bottomTextButtonsHeight);
    shuffleModeButton.frame = shuffleModeBtnFrame;
    shuffleModeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    shuffleModeButton.tintColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
    shuffleModeButton.alpha = 0;
    [shuffleModeButton setHitTestEdgeInsets:UIEdgeInsetsMake(-15, -25, -15, -25)];
    [self.view addSubview:shuffleModeButton];
    [UIView animateWithDuration:0.70  //now animate a "fade in"
                          delay:0.1
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^{ shuffleModeButton.alpha = 1.0; }
                     completion:nil];

    
    //add buttons to the viewControllers view
    for(UIButton *aButton in musicButtons){
        aButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:aButton];
        aButton.alpha = 0.0;  //make button transparent
        [UIView animateWithDuration:0.70  //now animate a "fade in"
                              delay:0.1
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                         animations:^{ aButton.alpha = 1.0; }
                         completion:nil];
    }
    _currentTimeLabel.alpha = 0.0;
    _totalDurationLabel.alpha = 0.0;
    [UIView animateWithDuration:0.7  //now animate a "fade in"
                          delay:0.2
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         _currentTimeLabel.alpha = 1.0;
         _totalDurationLabel.alpha = 1.0;
     }
                     completion:nil];
    playerButtonsSetUp = YES;
}

#pragma mark - Initializing Song and Album/Artist labels
- (void)InitSongInfoLabelsOnScreenAnimated:(BOOL)animate onRotation:(BOOL)rotating
{
    int iphone5Height = 568;
    int phoneWidth = self.view.frame.size.width;
    int phoneHeight = self.view.frame.size.height;
    if(self.view.frame.size.width > phoneHeight){
        phoneHeight = phoneWidth;
        phoneWidth = phoneHeight;
    }
    
    short songNameFontSize = 32;
    if(phoneHeight < iphone5Height)
        songNameFontSize = 20;
    
    _songNameLabel.text = [MusicPlaybackController nowPlayingSong].songName;
    _songNameLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _artistAndAlbumLabel.text = [self generateArtistAndAlbumString];
    _artistAndAlbumLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    float labelScrollRate = phoneWidth / 25.0;
    _songNameLabel.rate = labelScrollRate;
    _artistAndAlbumLabel.rate = labelScrollRate;
    _songNameLabel.fadeLength = 6.0f;
    _artistAndAlbumLabel.fadeLength = 6.0f;
    UIFont *font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                   size:songNameFontSize];
    _songNameLabel.font = font;
    _artistAndAlbumLabel.font = font;
    [self configureSongAndArtistAlbumLabelFramesAnimated:animate onRotation:rotating];
}

- (NSString *)generateArtistAndAlbumString
{
    NSMutableString *artistAndAlbum = [NSMutableString string];
    if([MusicPlaybackController nowPlayingSong].artist != nil)
        [artistAndAlbum appendString:[MusicPlaybackController nowPlayingSong].artist.artistName];
    if([MusicPlaybackController nowPlayingSong].album != nil)
    {
        if([MusicPlaybackController nowPlayingSong].artist != nil)
            [artistAndAlbum appendString:@" – "];
        [artistAndAlbum appendString:[MusicPlaybackController nowPlayingSong].album.albumName];
    }
    return artistAndAlbum;
}

//assumes the labels text has already been set.
- (void)configureSongAndArtistAlbumLabelFramesAnimated:(BOOL)animated
                                            onRotation:(BOOL)rotating
{
    //VC has just been pushed, dont need to animate into place!
    if(! animated){
        [self performSongArtistAlbumLabelFrameChanges];
    } else{
        if(rotating){
            [self performSongArtistAlbumLabelFrameChanges];
            _songNameLabel.alpha = 0;
            _artistAndAlbumLabel.alpha = 0;
            [UIView animateWithDuration:0.8
                                  delay:0.2
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 _songNameLabel.alpha = 1;
                                 _artistAndAlbumLabel.alpha = 1;
                             } completion:^(BOOL finished) {}];

        } else{
            __weak SongPlayerViewController *weakSelf = self;
            [UIView animateWithDuration:0.8
                                  delay:0.2
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [weakSelf performSongArtistAlbumLabelFrameChanges];
                             } completion:^(BOOL finished) {}];
        }
    }
}

- (void)performSongArtistAlbumLabelFrameChanges
{
    BOOL displayingBothLabels = YES;
    if(_artistAndAlbumLabel.text.length == 0)
        displayingBothLabels = NO;
    //make sure frames are good
    CGRect playerViewFrameInWindow = [[SongPlayerCoordinator sharedInstance] currentPlayerViewFrame];
    
    short navBarHeight = self.navigationController.navigationBar.frame.size.height;
    short statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    int playerYValue = playerViewFrameInWindow.origin.y - navBarHeight -
    statusBarHeight;
    if([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait)
        playerYValue -= statusBarHeight;
    int topOfView = 0;
    
    int mid1 = (topOfView + playerYValue)/2;  //mid of top and player
    int mid2 = (topOfView + mid1)/2;  //mid of mid1 and top
    int mid3 = (mid1 + playerYValue)/2;  //mid of mid 1 and player
    CGRect songLabelFrame;
    CGRect artistAlbumLabelFrame;
    
    //the +2 and -2 at the end of the y values (in CGRectMake) are just offsets
    //which compensate for the sldierhintview getting in the way
    if(displayingBothLabels)
    {
        songLabelFrame = CGRectMake(_songNameLabel.frame.origin.x,
                                    mid2+(_songNameLabel.frame.size.height/2)+2,
                                    _songNameLabel.frame.size.width,
                                    _songNameLabel.frame.size.height);
        
        artistAlbumLabelFrame = CGRectMake(_artistAndAlbumLabel.frame.origin.x,
                                           mid3+(_artistAndAlbumLabel.frame.size.height/2)-2,
                                           _artistAndAlbumLabel.frame.size.width,
                                           _artistAndAlbumLabel.frame.size.height);
        [_artistAndAlbumLabel setFrame:artistAlbumLabelFrame];
    }
    else
    {
        //only display song label, make it centered.
        songLabelFrame = CGRectMake(_songNameLabel.frame.origin.x,
                                    mid1+(_songNameLabel.frame.size.height/2),
                                    _songNameLabel.frame.size.width,
                                    _songNameLabel.frame.size.height);
    }
    [_songNameLabel setFrame:songLabelFrame];
}

#pragma mark - Playback Time Slider
- (void)positionPlaybackSliderOnScreen
{
    NSString *nameOfFontForTimeLabels = @"Menlo";
    short timeLabelFontSize = _currentTimeLabel.font.pointSize;
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        return;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    //hardcoded because i counted how wide it needs to be to fit our text (67 for including hours)
    int labelWidth = 52;
    int labelHeight = 21;
    int padding = 10;
    
    //setup current time label
    int labelXValue = screenWidth * 0.02f;
    int yValue = screenHeight * 0.74f;
    yValue -= extraStatusBarHeight;
    [_currentTimeLabel setFrame:CGRectMake(labelXValue, yValue, labelWidth, labelHeight)];
    _currentTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _currentTimeLabel.font = [UIFont fontWithName:nameOfFontForTimeLabels
                                             size:timeLabelFontSize];
    [self.view addSubview:_currentTimeLabel];
    int currentTimeLabelxValue = labelXValue;
    
    //setup slider
    int xValue = currentTimeLabelxValue + labelWidth + padding;
    //widthValue = self.playbackSlider.frame.size.width; //taken from autolayout
    int sliderWidth = screenWidth - ((labelXValue + labelWidth + padding) * 2);
    int sliderHeight = labelHeight;
    [_playbackSlider setFrame:CGRectMake(xValue, yValue +2, sliderWidth, sliderHeight)];
    _playbackSlider.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _playbackSlider.transform = CGAffineTransformMakeScale(0.82, 0.82);  //make knob smaller
    [self.view addSubview:_playbackSlider];
    
    //slider settings
    _playbackSlider.minimumValue = 0.0f;
    _playbackSlider.minimumTrackTintColor = [[AppEnvironmentConstants appTheme].mainGuiTint lighterColor];
    
    //setup total duration label
    labelXValue = xValue + sliderWidth + padding;
    yValue = yValue;
    [_totalDurationLabel setFrame:CGRectMake(labelXValue, yValue, labelWidth, labelHeight)];
    _totalDurationLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _totalDurationLabel.font = [UIFont fontWithName:nameOfFontForTimeLabels
                                               size:timeLabelFontSize];
    [self.view addSubview:_totalDurationLabel];
    
    _currentTimeLabel.textAlignment = NSTextAlignmentRight;
    _totalDurationLabel.textAlignment = NSTextAlignmentLeft;
    
    _playbackSlider.alpha = 0.0;
    [UIView animateWithDuration:0.7  //now animate a "fade in"
                          delay:0.2
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         _playbackSlider.alpha = 1.0;
     }
                     completion:nil];
}

- (void)displayTotalSliderAndLabelDuration
{
    NSInteger durationInSeconds = [[NowPlayingSong sharedInstance].nowPlayingItem.songForItem.duration integerValue];
    if(durationInSeconds <= 0.0f || isnan(durationInSeconds)){
        //Don't need to handle error, duration now showing isnt crucial.
        return;
    } else{
        //setup total song duration label animations
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        _playbackSlider.maximumValue = durationInSeconds;
        
        NSString *newText = [SongPlayerViewDisplayUtility convertSecondsToPrintableNSStringWithSliderValue:durationInSeconds];
        if(stateOfDurationLabels == DurationLabelStateNotSet){
            //figure it out lol
            _totalDurationLabel.text = newText;
            [self accomodateInterfaceBasedOnDurationLabelSize:_totalDurationLabel];
        }
        
        //only want to animate the change if we are also not animating the label width
        if(stateOfDurationLabels == DurationLabelStateMinutes){
            if([newText length] <= 5)  //displaying minutes
                [_totalDurationLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
        } else if(stateOfDurationLabels == DurationLabelStateHours){
            if([newText length] > 5)  //displaying hours
                [_totalDurationLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
        }
        _totalDurationLabel.text = newText;
    }
}

#pragma mark - Responding to Button Events (SleepTimer stuff)
//tapping timer button twice very fast would launch two pickers lol. this fixes that bug.
static BOOL goingToAnimateTimerPicker = NO;
//TIMER BUTTON
- (void)timerButtonTappedOnce
{
    if(goingToAnimateTimerPicker)
        return;
    
    if([AppEnvironmentConstants isPlaybackTimerActive] && !userReplacingExistingTimer){
        [self performSelector:@selector(showTimerActionSheeet)
                   withObject:nil
                   afterDelay:0.4];
        return;
    }
    
    goingToAnimateTimerPicker = YES;
    [self performSelector:@selector(showTimerPicker) withObject:nil afterDelay:0.25];
}

- (void)showTimerPicker
{
    __weak SongPlayerViewController *weakself = self;
    [ActionSheetDatePicker showPickerWithTitle:@"Sleep Timer"
                                datePickerMode:UIDatePickerModeCountDownTimer
                                  selectedDate:nil
                                   minimumDate:nil
                                   maximumDate:nil
                                     doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                         [weakself resetPlayerViewStateAfterPickerDismiss];
                                         NSTimeInterval timeInterval = picker.countDownDuration;
                                         if(timeInterval == 0){
                                             //set default (bug)
                                             timeInterval = 60;
                                         }
                                         [weakself startPlaybackTimerWithSeconds:timeInterval];
                                         userReplacingExistingTimer = NO;
                                         picker = nil;
                                         
                                     } cancelBlock:^(ActionSheetDatePicker *picker) {
                                         [weakself resetPlayerViewStateAfterPickerDismiss];
                                         userReplacingExistingTimer = NO;
                                         picker = nil;
                                     }
                                        origin:self.view];
    goingToAnimateTimerPicker = NO;
}

- (void)showTimerActionSheeet
{
    __weak SongPlayerViewController *weakself = self;
    popup = [[IBActionSheet alloc] initWithTitle:nil
                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                        } cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:@"Remove Sleep Timer"
                               otherButtonTitles:@"New Sleep Timer", nil];
    
    for(UIButton *aButton in popup.buttons){
        aButton.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:20];
    }
    [popup setButtonTextColor:[AppEnvironmentConstants appTheme].mainGuiTint];
    short destructiveButtonIndex = 0;
    [popup setButtonTextColor:[UIColor redColor] forButtonAtIndex:destructiveButtonIndex];
    [popup setTitleTextColor:[UIColor darkGrayColor]];
    [popup setCancelButtonFont:[UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                               size:20]];
    [popup setTitleFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18]];
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

static BOOL userReplacingExistingTimer = NO;
#pragma mark - Handling action sheet
- (void)handleActionClickWithButtonIndex:(NSInteger) buttonIndex
{
    switch (buttonIndex)
    {
        case 0:
            [AppEnvironmentConstants setPlaybackTimerActive:NO onThreadNum:-1];
            [self updateSleepTimerIcon];
            break;
        case 1:
            userReplacingExistingTimer = YES;
            [self performSelector:@selector(showTimerPicker) withObject:nil afterDelay:0.1];
            break;
        case 2:
            break;
        default:
            break;
    }
}

- (void)resetPlayerViewStateAfterPickerDismiss
{
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];
    });
}

static NSUInteger threadIdPlaybackSleepTimerCounter = 0;
static NSString * const TIMER_IMG_NEEDS_UPDATE = @"sleep timer needs update";
- (void)startPlaybackTimerWithSeconds:(NSTimeInterval)timeIntervalInSeconds
{
    __weak SongPlayerViewController *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger threadNum = ++threadIdPlaybackSleepTimerCounter;
        [AppEnvironmentConstants setPlaybackTimerActive:YES onThreadNum:threadNum];
        pthread_setname_np("MZMusic: Playback Timer");
        
        NSLog(@"Creating playback timer for %f seconds", timeIntervalInSeconds);
        [weakself updateSleepTimerIcon];
        [NSThread sleepForTimeInterval:timeIntervalInSeconds];
        
        if(threadNum == [AppEnvironmentConstants threadNumOfPlaybackSleepTimerThreadWhichShouldFire])
        {
            [MusicPlaybackController explicitlyPausePlayback:YES];
            [MusicPlaybackController pausePlayback];
            NSLog(@"Playback timer has fired");
            [AppEnvironmentConstants setPlaybackTimerActive:NO onThreadNum:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                                    object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:TIMER_IMG_NEEDS_UPDATE
                                                                    object:nil];
                [CATransaction flush];  //force immediate redraw
            });
        }
    });
}

- (void)updateSleepTimerIcon
{
    NSString *btnImgName;
    if([AppEnvironmentConstants isPlaybackTimerActive])
        btnImgName = TIMER_ACTIVE;
    else
        btnImgName = TIMER_INACTIVE;
    UIColor *appTint = [AppEnvironmentConstants appTheme].mainGuiTint;
    UIImage *timerImg = [UIImage colorOpaquePartOfImage:appTint :[UIImage imageNamed:btnImgName]];
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction |  UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [timerButton setImage:timerImg forState:UIControlStateNormal];
                     }
                     completion:nil];
    [CATransaction flush];  //force immediate redraw
}

#pragma mark - Responding to Button Events
- (void)repeatModeButtonTapped
{
    switch ([AppEnvironmentConstants playbackRepeatType])
    {
        case PLABACK_REPEAT_MODE_disabled:
        {
            [AppEnvironmentConstants setPlaybackRepeatType:PLABACK_REPEAT_MODE_Song];
            break;
        }
        case PLABACK_REPEAT_MODE_Song:
        {
            [AppEnvironmentConstants setPlaybackRepeatType:PLABACK_REPEAT_MODE_All];
            break;
        }
        case PLABACK_REPEAT_MODE_All:
        {
            [AppEnvironmentConstants setPlaybackRepeatType:PLABACK_REPEAT_MODE_disabled];
            break;
        }
        default:
            break;
    }
    [self updateRepeatButtonGivenNewRepeatState];
}

- (void)updateRepeatButtonGivenNewRepeatState
{
    switch ([AppEnvironmentConstants playbackRepeatType])
    {
        case PLABACK_REPEAT_MODE_disabled:
        {
            repeatModeButton.selected = NO;
            break;
        }
        case PLABACK_REPEAT_MODE_Song:
        {
            repeatModeButton.selected = YES;
            break;
        }
        case PLABACK_REPEAT_MODE_All:
        {
            repeatModeButton.selected = YES;
            break;
        }
        default:
            break;
    }
    UIControlState controlState;
    if(repeatModeButton.selected)
        controlState = UIControlStateSelected;
    else
        controlState = UIControlStateNormal;
    
    [repeatModeButton setTitle:[AppEnvironmentConstants stringRepresentationOfRepeatMode]
                      forState:controlState];
}

- (void)shuffleModeButtonTapped
{
    NSString *msg = @"This feature is coming soon.";
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:@"Shuffle"
                                                                    message:msg
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    [alert addAction:[SDCAlertAction actionWithTitle:@"OK"
                                               style:SDCAlertActionStyleRecommended
                                             handler:nil]];
    [alert presentWithCompletion:nil];
    return;
    
#warning Shuffle feature unfinished.
    /*
    switch ([AppEnvironmentConstants shuffleState])
    {
        case SHUFFLE_STATE_Disabled:
        {
            [AppEnvironmentConstants setShuffleState:SHUFFLE_STATE_Enabled];
            break;
        }
        case SHUFFLE_STATE_Enabled:
        {
            [AppEnvironmentConstants setShuffleState:SHUFFLE_STATE_Disabled];
            break;
        }
        default:
            break;
    }
    [self updateShuffleButtonGivenNewShuffleState];
    */
}

- (void)updateShuffleButtonGivenNewShuffleState
{
    switch ([AppEnvironmentConstants shuffleState])
    {
        case SHUFFLE_STATE_Disabled:
        {
            shuffleModeButton.selected = NO;
            break;
        }
        case SHUFFLE_STATE_Enabled:
        {
            shuffleModeButton.selected = YES;
            break;
        }
        default:
            break;
    }
    UIControlState controlState;
    if(shuffleModeButton.selected)
        controlState = UIControlStateSelected;
    else
        controlState = UIControlStateNormal;
    
    [shuffleModeButton setTitle:[AppEnvironmentConstants stringRepresentationOfShuffleState]
                       forState:controlState];
}


//BACK BUTTON
- (void)backwardsButtonTappedOnce
{
    if(! [MusicPlaybackController shouldSeekToStartOnBackPress]){
        //previous song will actually be loaded
        waitingForNextOrPrevVideoToLoad = YES;
        self.playbackSlider.enabled = NO;
    } else
        [self toggleDisplayToPlayingState];
    //order matters here...this call should be after the if statement.
    //delay helps keep the button animations responsive.
    [MusicPlaybackController performSelector:@selector(returnToPreviousTrack)
                                  withObject:nil
                                  afterDelay:0.1];
}

//PLAY BUTTON
- (void)playOrPauseButtonTapped
{
    UIColor *color = [UIColor blackColor];
    UIImage *tempImage;
    UIImage *newBtnImage;
    if([MusicPlaybackController obtainRawAVPlayer].rate == 0)  //currently paused, resume..
    {
        tempImage = [UIImage imageNamed:PAUSE_IMAGE];
        newBtnImage = [UIImage colorOpaquePartOfImage:color :tempImage];
        [MusicPlaybackController explicitlyPausePlayback:NO];
        [MusicPlaybackController resumePlayback];
    }
    else  //playing now, pause..
    {
        tempImage = [UIImage imageNamed:PLAY_IMAGE];
        newBtnImage = [UIImage colorOpaquePartOfImage:color :tempImage];
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [MusicPlaybackController pausePlayback];
    }
    playButton.enabled = YES;
    [self performSelector:@selector(changePlayButtonImageTo:) withObject:newBtnImage afterDelay:0.3];
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlayingItem.songForItem];
}

- (void)changePlayButtonImageTo:(UIImage *)newBtnImage
{
    CGPoint buttonCenter = playButton.center;
    [playButton setImage:newBtnImage forState:UIControlStateNormal];

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         [playButton setCenter:buttonCenter];
                     }
                     completion:nil];
}

//FORWARD BUTTON
- (void)forwardsButtonTappedOnce
{
    waitingForNextOrPrevVideoToLoad = YES;
    self.playbackSlider.enabled = NO;
    //delay helps keep the button animations responsive.
    [MusicPlaybackController performSelector:@selector(skipToNextTrack)
                                  withObject:nil
                                  afterDelay:0.1];
}

//only toggles the gui! does not mean user hit pause! Used for responding to rate changes during buffering.
- (void)toggleDisplayToPausedState
{
    if(stateOfGUIPlayback == GUIPlaybackStatePlaying ||
       (stateOfGUIPlayback == GUIPlaybackStatePaused && [MusicPlaybackController isPlayerStalled])){
        UIColor *color = [UIColor blackColor];
        UIImage *tempImage = [UIImage imageNamed:PLAY_IMAGE];
        UIImage *playImg = [UIImage colorOpaquePartOfImage:color :tempImage];
        [self changePlayButtonImageTo:playImg];
    }
    stateOfGUIPlayback = GUIPlaybackStatePaused;
}
//read comment in method above
- (void)toggleDisplayToPlayingState
{
    if(sliderIsBeingTouched){
        [self toggleDisplayToPausedState];
        return;
    }
    
    if(stateOfGUIPlayback == GUIPlaybackStatePaused && ![MusicPlaybackController isPlayerStalled]){
        UIColor *color = [UIColor blackColor];
        UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE];
        UIImage *pauseImg = [UIImage colorOpaquePartOfImage:color :tempImage];
        [self changePlayButtonImageTo:pauseImg];
    }
    if(![MusicPlaybackController isPlayerStalled])
        stateOfGUIPlayback = GUIPlaybackStatePlaying;
    else
        [self toggleDisplayToPausedState];
}

- (void)dismissVCButtonTapped
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [[SongPlayerCoordinator sharedInstance] beginShrinkingVideoPlayer];
    [self preDealloc];
}

#pragma mark - Key value observing stuff
- (void)setupKeyvalueObservers
{
    [self restoreTimeObserver];
    
    //label observers...
    [_totalDurationLabel addObserver:self
                          forKeyPath:@"text"
                             options:NSKeyValueObservingOptionNew
                             context:kTotalDurationLabelDidChange];
}

- (void)removeObservers
{
    @try {
        [_totalDurationLabel removeObserver:self forKeyPath:@"text" context:kTotalDurationLabelDidChange];
    }
    //do nothing
    @catch (id anException) {}
    
    [self killTimeObserver];
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{    
    //check for duration label change
    if (context == kTotalDurationLabelDidChange) {
        [self accomodateInterfaceBasedOnDurationLabelSize:(UILabel *)object];
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)playerControlsShouldBeUpdated  //MZAVPlayerStallStateChanged
{   
    if([MusicPlaybackController isPlayerStalled]){
        [self toggleDisplayToPausedState];
    } else{
        if([MusicPlaybackController obtainRawAVPlayer].rate == 1)
            [self toggleDisplayToPlayingState];
        else
            [self toggleDisplayToPausedState];
    }
}

#pragma mark - Responding to app state
- (void)killTimeObserver
{
    [MusicPlaybackController setAVPlayerTimeObserver:nil];
}

- (void)restoreTimeObserver
{
    if([MusicPlaybackController avplayerTimeObserver] != nil)
        return;
    
    __weak SongPlayerViewController *weakSelf = self;
    __weak AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    CMTime timeInterval = CMTimeMake(1, 8);
    [MusicPlaybackController setAVPlayerTimeObserver: [player addPeriodicTimeObserverForInterval:timeInterval queue:nil usingBlock:^(CMTime time){
        //code will be called 10 times a second (ie. every 0.1 seconds)
        
        Float64 currentTimeValue = CMTimeGetSeconds([MusicPlaybackController obtainRawAVPlayer].currentItem.currentTime);
        [weakSelf updatePlaybackTimeSliderWithTimeValue:currentTimeValue];
        [[MusicPlaybackController obtainRawPlayerView] updatePlaybackTimeSliderWithTimeValue:currentTimeValue];
        
        id observer = [MusicPlaybackController avplayerTimeObserver];
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        if (observer != nil &&
            (state == UIApplicationStateBackground
            || state == UIApplicationStateInactive
            || ![SongPlayerCoordinator isVideoPlayerExpanded]))
        {
            [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:[MusicPlaybackController avplayerTimeObserver]];
            [MusicPlaybackController setAVPlayerTimeObserver:nil];
        }
    }]];
}

#pragma mark - Share Button Tapped
- (void)shareButtonTapped
{
    Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
    if(nowPlayingSong){
        NSString *youtubeLink = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", nowPlayingSong.youtube_id];
        NSURL *shareUrl = [NSURL URLWithString:youtubeLink];
        NSArray *activityItems = @[shareUrl];
        
        //temporarily changing app default colors for the activityviewcontroller.
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.window.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[AppEnvironmentConstants appTheme].mainGuiTint, NSForegroundColorAttributeName, nil]];
        
        TUSafariActivity *openInSafariActivity = [[TUSafariActivity alloc] init];
        NSArray *activities = @[openInSafariActivity];
        __block UIActivityViewController *activityVC = [[UIActivityViewController alloc]
                                                        initWithActivityItems:activityItems
                                                        applicationActivities:activities];
        __weak UIActivityViewController *weakActivityVC = activityVC;
        __weak SongPlayerViewController *weakSelf = self;
        
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop,
                                             UIActivityTypeAddToReadingList];
        //set tint color specifically for this VC so that the text and buttons are visible
        [activityVC.view setTintColor:[AppEnvironmentConstants appTheme].mainGuiTint];
        
        [self removeObservers];
        
        __weak NSString *videoId = nowPlayingSong.youtube_id;
        
        [activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed,  NSArray *returnedItems, NSError *activityError) {
            if(activityType == nil) {
                activityType = @"";  //set it to an empty string just so we don't crash here.
            }
            [weakSelf restoreTimeObserver];
            NSString *regex = @"(UIActivityType)|(TU)|(Activity)|(.*\\.)";
            NSString *shareMethod = [MZCommons replaceCharsMatchingRegex:regex
                                                                            withChars:@""
                                                                          usingString:activityType];
            
            if(completed &&
               ([shareMethod caseInsensitiveCompare:@"Message"] == NSOrderedSame
               || [shareMethod caseInsensitiveCompare:@"Mail"] == NSOrderedSame
               || [shareMethod caseInsensitiveCompare:@"PostToFacebook"] == NSOrderedSame
               || [shareMethod caseInsensitiveCompare:@"PostToTwitter"] == NSOrderedSame
               || [shareMethod caseInsensitiveCompare:@"PostToWeibo"] == NSOrderedSame)) {
                [Answers logShareWithMethod:shareMethod
                                contentName:nil
                                contentType:@"YouTube Video"
                                  contentId:videoId
                           customAttributes:@{@"VideoFromLibrary" : [NSNumber numberWithBool:YES]}];
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                //restoring default button and title font colors in the app.
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.window.tintColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
                [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[AppEnvironmentConstants appTheme].navBarToolbarTextTint, NSForegroundColorAttributeName, nil]];
                [weakSelf.navigationController.navigationBar setTitleTextAttributes:
                 @{NSForegroundColorAttributeName:[AppEnvironmentConstants appTheme].navBarToolbarTextTint}];
            }];
        }];
        [self presentViewController:activityVC
                           animated:YES
                         completion:^{
                             //fixes memory leak
                             weakActivityVC.excludedActivityTypes = nil;
                             activityVC = nil;
                         }];
    } else{
        // Handle error
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_TroubleSharingLibrarySong];
    }
}

- (void)viewPlaybackQueue
{
    QueueViewController *vc = [[QueueViewController alloc] init];
    AFBlurSegue *segue = [[AFBlurSegue alloc] initWithIdentifier:@"showQueueSEgue"
                                                          source:self
                                                     destination:vc];
    segue.animate = YES;
    segue.blurRadius = 50;
    segue.saturationDeltaFactor = .1;
    [segue perform];
}

@end
