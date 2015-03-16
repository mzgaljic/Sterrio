//
//  SongPlayerViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongPlayerViewController.h"
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
    NSArray *musicButtons;
    UIButton *playButton;
    UIButton *forwardButton;
    UIButton *backwardButton;
    
    GCDiscreetNotificationView *sliderHint;  //slider hint
    
    BOOL playerButtonsSetUp;
    DurationLabelStates stateOfDurationLabels;
    GUIPlaybackState stateOfGUIPlayback;
    UIColor *colorOfPlaybackButtons;
    
    BOOL firstTimeUpdatingSliderSinceShowingPlayer;
    BOOL deferTimeLabelAdjustmentUntilPortrait;
    
    //for key value observing
    id timeObserver;
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
static const short longDurationLabelOffset = 24;
static int numTimesSetupKeyValueObservers = 0;
const CGFloat observationsPerSecond = 15.0f;  //for timeObserver var

NSString * const AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";
NSString * const CURRENT_SONG_DONE_PLAYING = @"Current item has finished, update gui please!";
NSString * const CURRENT_SONG_STOPPED_PLAYBACK = @"playback has stopped for some unknown reason (stall?)";
NSString * const CURRENT_SONG_RESUMED_PLAYBACK = @"playback has resumed from a stall probably";

NSString * const PAUSE_IMAGE_FILLED = @"Pause-Filled";
NSString * const PAUSE_IMAGE_UNFILLED = @"Pause-Line";
NSString * const PLAY_IMAGE_FILLED = @"Play-Filled";
NSString * const PLAY_IMAGE_UNFILLED = @"Play-Line";
NSString * const FORWARD_IMAGE_FILLED = @"Seek-Filled";
NSString * const FORWARD_IMAGE_UNFILLED = @"Seek-Line";
NSString * const BACKWARD_IMAGE_FILLED = @"Backward-Filled";
NSString * const BACKWARD_IMAGE_UNFILLED = @"Backward-Line";

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
    
    //make sure ASValueTrackingSlider is still using the superclass JAMAccurateSlider
    if(! [ASValueTrackingSlider isSubclassOfClass:[JAMAccurateSlider class]]){
        NSLog(@"ASValueTrackingSlider HAS BEEN UPDATED/CHANGED. THE SUPER CLASS IS NO LONGER JAMAccurateSlider, PLEASE FIX THIS ASAP.");
        abort();
    }
    
    //clear out garbage values from storyboard
    _songNameLabel.text = @"";
    _artistAndAlbumLabel.text = @"";
    
    //this allows me to discover if AVSValueTrackingSlider changes, even on a new device.
    [_playbackSlider disablePopupSliderCompletely:NO];
    
    //disabling popup on slider for small screens since the interface is too small
    int iphone5Height = 568;
    int phoneHeight = [UIScreen mainScreen].bounds.size.height;
    if(self.view.frame.size.width > phoneHeight)
        phoneHeight = [UIScreen mainScreen].bounds.size.width;
    if(phoneHeight < iphone5Height)
        [_playbackSlider disablePopupSliderCompletely:YES];
    
    firstTimeUpdatingSliderSinceShowingPlayer = YES;
    colorOfPlaybackButtons = [UIColor defaultAppColorScheme];
    waitingForNextOrPrevVideoToLoad = YES;
    [self initAndRegisterAllButtons];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateScreenWithInfoForNewSong:)
                                                 name:MZNewSongLoading
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastSongHasFinishedPlayback:)
                                                 name:AVPLAYER_DONE_PLAYING
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
    self.playbackSlider.dataSource = self;
    [[SongPlayerCoordinator sharedInstance] setDelegate:self];
    
    _currentTimeLabel.text = @"--:--";
    _totalDurationLabel.text = @"--:--";
    _currentTimeLabel.textColor = [UIColor blackColor];
    _totalDurationLabel.textColor = [UIColor blackColor];
    self.navBar.title = [MusicPlaybackController prettyPrintNavBarTitle];
    
    //app crashes shortly after dismissing this VC if the share sheet was selected. Need
    //this if statement!
    if(numTimesSetupKeyValueObservers == 0)
        [self setupKeyvalueObservers];
    numTimesSetupKeyValueObservers++;
}

static int numTimesVCLoaded = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    if(numTimesVCLoaded == 0){
         [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];  //sets up the player only once
        
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player startPlaybackOfSong:nowPlaying goingForward:YES oldSong:nil];
        //avplayer will control itself for the most part now...
    }
    numTimesVCLoaded++;
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                           target:self
                                                                           action:@selector(shareButtonTapped)];
    UIBarButtonItem *queue = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                           target:self
                                                                           action:@selector(viewPlaybackQueue)];
    NSArray *rightBarBtns = @[share, queue];
    self.navigationItem.rightBarButtonItems = rightBarBtns;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarArrowDown"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(dismissVideoPlayerControllerButtonTapped)];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL positionedSliderAlready = NO;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        [self positionMusicButtonsOnScreenAndSetThemUp];
        [self positionPlaybackSliderOnScreen];
        positionedSliderAlready = YES;
    }
    
    [self checkDeviceOrientation];
    if(! positionedSliderAlready)
        [self positionPlaybackSliderOnScreen];
    
    [self InitSongInfoLabelsOnScreenAnimated:NO onRotation:NO];
    
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    
    //check if at least 1 second of video has loaded. If so, we should consider the video as
    //playing back, or at least trying to. We can then set up the slider and totalDuration label.
    BOOL playbackUnderway = NO;
    NSArray * timeRanges = player.currentItem.loadedTimeRanges;
    if (timeRanges && [timeRanges count]){
        CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
        NSUInteger secondsBuffed = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
        if(secondsBuffed > 0){
            [self playbackOfVideoHasBegunRespectPlayPauseState];
            playbackUnderway = YES;
        }
    }
    if(! playbackUnderway){
        [_playbackSlider setMaximumValue:0];
        [_playbackSlider setValue:0];
        _playbackSlider.enabled = NO;
    }
    
    //check if this song is the last one
    if([MusicPlaybackController isSongLastInQueue:nowPlaying])
        [self hideNextTrackButton];
    if([MusicPlaybackController isSongFirstInQueue:nowPlaying])
        [self hidePreviousTrackButton];
    
     //make sure slider hint view is at the same height as the nav bar...only in portrait
    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
        [self setupSliderHintView];
    UIColor *niceGrey = [[UIColor alloc] initWithRed:106.0/255
                                               green:114.0/255
                                                blue:121.0/255
                                               alpha:1];
    _artistAndAlbumLabel.textColor = niceGrey;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    if(timeObserver == nil){
        [self restoreTimeObserver];
        firstTimeUpdatingSliderSinceShowingPlayer = YES;
    }
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
    [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:timeObserver];
    [self removeObservers];
    sliderHint = nil;
    self.playbackSlider.dataSource = nil;
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
- (void)lastSongHasFinishedPlayback:(NSNotification *)object
{
    //seek to end of track, if its not already (just in case)
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player){
        if(player.currentItem)
            [player seekToTime:player.currentItem.asset.duration];
    }
    [self toggleDisplayToPausedState];
}

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
}

- (void)setupSliderHintView
{
    short statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    short navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGRect frame = self.sliderHintView.frame;
    CGRect newFrame = CGRectMake(frame.origin.x,
                                 navBarHeight+statusBarHeight,
                                 frame.size.width,
                                 frame.size.height);
    self.sliderHintView.frame = newFrame;
}

- (void)checkDeviceOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self.navigationController setNavigationBarHidden:NO];
    lastKnownOrientation = orientation;
}

- (BOOL)prefersStatusBarHidden
{
    if(lastKnownOrientation == UIInterfaceOrientationLandscapeLeft || lastKnownOrientation == UIInterfaceOrientationLandscapeRight){
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
    if(fromInterfaceOrientation != UIInterfaceOrientationPortrait)
        [self setupSliderHintView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(lastKnownOrientation == UIInterfaceOrientationLandscapeLeft && toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        return;  //we dont need to do anything, video player should still remain full screen.
    if(lastKnownOrientation == UIInterfaceOrientationLandscapeRight && toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        return;  //same reason as first if
    if(lastKnownOrientation == toInterfaceOrientation)
        return;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft){
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
        CGRect newFrame = CGRectMake(0,   playerYValue,
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
}

- (void)initLabelsOnScreenDelayed
{
    [self InitSongInfoLabelsOnScreenAnimated:YES onRotation:YES];
}

#pragma mark - Responding to player playback events (rate, internet connection, etc.) Slider and labels.
- (IBAction)playbackSliderEditingHasBegun:(id)sender
{
    NSString *hint = @"Slide ↑ or ↓ for more accuracy.";
    int presentationMode = GCDiscreetNotificationViewPresentationModeTop;
    if(! sliderHint)
        sliderHint = [[GCDiscreetNotificationView alloc] initWithText:hint
                                                         showActivity:NO
                                                   inPresentationMode:presentationMode
                                                               inView:_sliderHintView];
    _sliderHintView.hidden = NO;
    if(sliderHint)
        [sliderHint showAnimated];
    
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player.rate == 0)
        playAfterMovingSlider = NO;
    sliderIsBeingTouched = YES;
    [player pause];
    [MusicPlaybackController explicitlyPausePlayback:YES];
    [self toggleDisplayToPausedState];
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
    [MusicPlaybackController updateLockScreenInfoAndArtForSong:[NowPlayingSong sharedInstance].nowPlaying];
}
- (IBAction)playbackSliderEditingHasEndedB:(id)sender  //touch up outside
{
    [self playbackSliderEditingHasEndedA:nil];
}

- (IBAction)playbackSliderValueHasChanged:(id)sender
{
    CMTime newTime = CMTimeMakeWithSeconds(_playbackSlider.value, NSEC_PER_SEC);
    [[MusicPlaybackController obtainRawAVPlayer] seekToTime:newTime];
}

- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value
{
    NSString *returnString = [self convertSecondsToPrintableNSStringWithSliderValue:value];
    _currentTimeLabel.text = returnString;
    return returnString;
}

- (void)updatePlaybackTimeSlider
{
    if(sliderIsBeingTouched)
        return;
    
    Float64 currentTimeValue = CMTimeGetSeconds([MusicPlaybackController obtainRawAVPlayer].currentItem.currentTime);
    
    //sets slider directly from avplayer. playback can stutter or pause, so we can't just increment by 1...
    if(firstTimeUpdatingSliderSinceShowingPlayer)
        [self.playbackSlider setValue:(currentTimeValue) animated:NO];
    else{
        if([_playbackSlider isPopupSliderCompletelyDisabled]){
            //popup slider is disabled on devices smaller than iPhone 5. This messes with internals of ASValueTrackingSlider
            //in this case we want to manually perform animation updates (dont let ASValueTrackingSlider handle it)
            [_playbackSlider setParentValue:(currentTimeValue) animated:YES];  //custom method i created
        }
        else
            [_playbackSlider setValue:(currentTimeValue) animated:YES];
    }
    
    firstTimeUpdatingSliderSinceShowingPlayer = NO;
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
    else
        self.playbackSlider.enabled = YES;  //this is the last song anyway, slider can remain active.
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
        UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
        UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
        [playButton setImage:pauseFilled forState:UIControlStateNormal];
    } else{
        UIImage *tempImage = [UIImage imageNamed:PLAY_IMAGE_FILLED];
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
        [playButton setImage:playFilled forState:UIControlStateNormal];
    }
    
    [self displayTotalSliderAndLabelDuration];
    
    NSUInteger test = CMTimeGetSeconds(player.currentItem.currentTime);
    if(player.currentItem)
        [_playbackSlider setValue:test animated:NO];
    else
        [_playbackSlider setValue:0];
    waitingForNextOrPrevVideoToLoad = NO;
    
    if(! [MusicPlaybackController isSongFirstInQueue:[MusicPlaybackController nowPlayingSong]])
        [self showPreviousTrackButton];
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
    UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
    UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
    
    [playButton setImage:pauseFilled forState:UIControlStateNormal];
    [MusicPlaybackController explicitlyPausePlayback:NO];
    [MusicPlaybackController resumePlayback];
    
    [self displayTotalSliderAndLabelDuration];
    if(! [MusicPlaybackController isSongFirstInQueue:[MusicPlaybackController nowPlayingSong]])
        [self showPreviousTrackButton];
}

#pragma mark - Initializing & Registering Buttons
- (void)initAndRegisterAllButtons
{
    backwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [backwardButton addTarget:self
                       action:@selector(backwardsButtonTappedOnce)
             forControlEvents:UIControlEventTouchUpInside];
    [backwardButton addTarget:self
                       action:@selector(backwardsButtonBeingHeld)
             forControlEvents:UIControlEventTouchDown];
    [backwardButton addTarget:self
                       action:@selector(backwardsButtonLetGo)
             forControlEvents:UIControlEventTouchUpOutside];
    [playButton addTarget:self
                   action:@selector(playOrPauseButtonTapped)
         forControlEvents:UIControlEventTouchUpInside];
    [playButton addTarget:self
                   action:@selector(playOrPauseButtonBeingHeld)
         forControlEvents:UIControlEventTouchDown];
    [playButton addTarget:self
                   action:@selector(playOrPauseButtonLetGo)
         forControlEvents:UIControlEventTouchUpOutside];
    [forwardButton addTarget:self
                      action:@selector(forwardsButtonTappedOnce)
            forControlEvents:UIControlEventTouchUpInside];
    [forwardButton addTarget:self
                      action:@selector(forwardsButtonBeingHeld)
            forControlEvents:UIControlEventTouchDown];
    [forwardButton addTarget:self
                      action:@selector(forwardsButtonLetGo)
            forControlEvents:UIControlEventTouchUpOutside];
    
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
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{ aButton.alpha = 1.0; }
                             completion:nil];
        }
        
        _currentTimeLabel.alpha = 0.0;
        _totalDurationLabel.alpha = 0.0;
        [UIView animateWithDuration:0.7  //now animate a "fade in"
                              delay:0.2
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^
                        {
                            _currentTimeLabel.alpha = 1.0;
                            _totalDurationLabel.alpha = 1.0;
                        }
                         completion:nil];
    }
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        return;
    
    //make images fill up frame, change button hit area
    for(UIButton *aButton in musicButtons){
        aButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        aButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        [aButton setHitTestEdgeInsets:UIEdgeInsetsMake(-32, -32, -32, -32)];
    }
    
    float imgScaleFactor = 1.4f;
    float percentDownScreen = 0.84f;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    UIColor *appTint = [UIColor blackColor];
    float yValue, xValue;
    //play button or pause button
    if([MusicPlaybackController obtainRawAVPlayer].rate == 0){
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:appTint
                                                             :[UIImage imageNamed:PLAY_IMAGE_FILLED]];
        
        float playButtonWidth = playFilled.size.width * imgScaleFactor;
        float playButtonHeight = playFilled.size.height * imgScaleFactor;
        yValue = ceil(screenHeight * percentDownScreen);  //want the play button to be 84% of the way down the screen
        //want play button to be in the middle of the screen horizontally
        xValue = (screenWidth * 0.5) - (playButtonWidth/2);
        playButton.frame = CGRectMake(xValue +0, yValue, playButtonWidth, playButtonHeight);
        [playButton setImage:playFilled forState:UIControlStateNormal];
    } else{
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:appTint
                                                             :[UIImage imageNamed:PAUSE_IMAGE_FILLED]];
        
        float playButtonWidth = playFilled.size.width * imgScaleFactor;
        float playButtonHeight = playFilled.size.height * imgScaleFactor;
        yValue = ceil(screenHeight * percentDownScreen);  //want the play button to be 84% of the way down the screen
        //want play button to be in the middle of the screen horizontally
        xValue = (screenWidth * 0.5) - (playButtonWidth/2);
        playButton.frame = CGRectMake(xValue +1, yValue, playButtonWidth, playButtonHeight);
        [playButton setImage:playFilled forState:UIControlStateNormal];
    }
    
    //seek backward button
    UIImage *backFilled = [UIImage colorOpaquePartOfImage:appTint
                                                         :[UIImage imageNamed:BACKWARD_IMAGE_FILLED]];
    
    float backwardButtonWidth = backFilled.size.width * imgScaleFactor;
    float backwardButtonHeight = backFilled.size.height * imgScaleFactor;
    //will be in between the play button and left side of screen
    xValue = (((screenWidth /2) - ((screenWidth /2) /2)) - backwardButtonWidth/2);
    //middle y value in the center of the play button
    float middlePointVertically = playButton.center.y;
    yValue = (middlePointVertically - (backFilled.size.height/1.5));
    backwardButton.frame = CGRectMake(xValue-3, yValue -1, backwardButtonWidth, backwardButtonHeight);
    [backwardButton setImage:backFilled forState:UIControlStateNormal];
    
    //see forward button
    UIImage *forwardFilled = [UIImage colorOpaquePartOfImage:appTint
                                                            :[UIImage imageNamed:FORWARD_IMAGE_FILLED]];
    
    float forwardButtonWidth = forwardFilled.size.width * imgScaleFactor;
    float forwardButtonHeight = forwardFilled.size.height * imgScaleFactor;
    //will be in between the play button and right side of screen
    xValue = (((screenWidth /2) + ((screenWidth /2) /2)) - forwardButtonWidth/2);
    yValue = (middlePointVertically - (forwardFilled.size.height/1.5));
    forwardButton.frame = CGRectMake(xValue +3, yValue -1, forwardButtonWidth, forwardButtonHeight);
    [forwardButton setImage:forwardFilled forState:UIControlStateNormal];
    
    //add buttons to the viewControllers view
    for(UIButton *aButton in musicButtons){
        [self.view addSubview:aButton];
        aButton.alpha = 0.0;  //make button transparent
        [UIView animateWithDuration:0.70  //now animate a "fade in"
                              delay:0.1
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{ aButton.alpha = 1.0; }
                         completion:nil];
    }
    _currentTimeLabel.alpha = 0.0;
    _totalDurationLabel.alpha = 0.0;
    [UIView animateWithDuration:0.7  //now animate a "fade in"
                          delay:0.2
                        options:UIViewAnimationOptionAllowUserInteraction
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
    
    //this const factor will provide a duration "feel" similar to the
    //duration "8" on an iphone 6 width. This const factor will help us
    //generate a duration value that gives the same feel on other devices
    //with a different screen size.
    float constantFactor = 1/119.0f;
    int duration = constantFactor * phoneWidth;
    _songNameLabel.scrollDuration = duration;
    _artistAndAlbumLabel.scrollDuration = duration;
    _songNameLabel.fadeLength = 6.0f;
    _artistAndAlbumLabel.fadeLength = 6.0f;
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light"
                                   size:songNameFontSize];
    _songNameLabel.font = font;
    _artistAndAlbumLabel.font = font;
    
    _songNameLabel.text = [MusicPlaybackController nowPlayingSong].songName;
    _artistAndAlbumLabel.text = [self generateArtistAndAlbumString];
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
            [artistAndAlbum appendString:@" ・ "];
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
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 _songNameLabel.alpha = 1;
                                 _artistAndAlbumLabel.alpha = 1;
                             } completion:^(BOOL finished) {}];

        } else{
            __weak SongPlayerViewController *weakSelf = self;
            [UIView animateWithDuration:0.8
                                  delay:0.2
                                options:UIViewAnimationOptionAllowUserInteraction
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
    NSString *nameOfFontForTimeLabels = @"HelveticaNeue-Medium";
    short timeLabelFontSize = _currentTimeLabel.font.pointSize;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        return;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    int labelWidth = 43;  //hardcoded because i counted how wide it needs to be to fit our text (67 for including hours)
    int labelHeight = 21;
    int padding = 10;
    
    //setup current time label
    int labelXValue = screenWidth * 0.02f;
    int yValue = screenHeight * 0.74f;
    [_currentTimeLabel removeFromSuperview];
    [_currentTimeLabel setFrame:CGRectMake(labelXValue, yValue, labelWidth, labelHeight)];
    _currentTimeLabel.font = [UIFont fontWithName:nameOfFontForTimeLabels
                                             size:timeLabelFontSize];
    [self.view addSubview:_currentTimeLabel];
    int currentTimeLabelxValue = labelXValue;
    
    //setup slider
    int xValue = currentTimeLabelxValue + labelWidth + padding;
    //widthValue = self.playbackSlider.frame.size.width; //taken from autolayout
    int sliderWidth = screenWidth - ((labelXValue + labelWidth + padding) * 2);
    int sliderHeight = labelHeight;
    [_playbackSlider removeFromSuperview];
    [_playbackSlider setFrame:CGRectMake(xValue, yValue +2, sliderWidth, sliderHeight)];
    _playbackSlider.transform = CGAffineTransformMakeScale(0.82, 0.82);  //make knob smaller
    [self.view addSubview:_playbackSlider];
    
    //slider settings
    _playbackSlider.minimumValue = 0.0f;
    _playbackSlider.popUpViewCornerRadius = 5.0;
    [_playbackSlider setMaxFractionDigitsDisplayed:0];
    _playbackSlider.popUpViewColor = [[UIColor defaultAppColorScheme] lighterColor];
    _playbackSlider.font = [UIFont fontWithName:nameOfFontForTimeLabels size:24];
    _playbackSlider.textColor = [UIColor whiteColor];
    _playbackSlider.minimumTrackTintColor = [[UIColor defaultAppColorScheme] lighterColor];
    
    //check if device is older than 5, need to disable the popup on small screen sizes
    //since it doesnt fit well
    int iphone5Height = 568;
    int phoneHeight = self.view.frame.size.height;
    if(self.view.frame.size.width > phoneHeight)
        phoneHeight = self.view.frame.size.width;
    BOOL runningiPhone5orNewer = YES;
    if(phoneHeight < iphone5Height)
        runningiPhone5orNewer = NO;
    if(! runningiPhone5orNewer)
       [_playbackSlider hidePopUpViewAnimated:NO];
    
    //setup total duration label
    labelXValue = xValue + sliderWidth + padding;
    yValue = yValue;
    [_totalDurationLabel removeFromSuperview];
    [_totalDurationLabel setFrame:CGRectMake(labelXValue, yValue, labelWidth, labelHeight)];
    _totalDurationLabel.font = [UIFont fontWithName:nameOfFontForTimeLabels
                                               size:timeLabelFontSize];
    [self.view addSubview:_totalDurationLabel];
    
    _currentTimeLabel.textAlignment = NSTextAlignmentRight;
    _totalDurationLabel.textAlignment = NSTextAlignmentLeft;
    
    _playbackSlider.alpha = 0.0;
    [UIView animateWithDuration:0.7  //now animate a "fade in"
                          delay:0.2
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^
     {
         _playbackSlider.alpha = 1.0;
     }
                     completion:nil];
}

- (void)displayTotalSliderAndLabelDuration
{
    NSInteger durationInSeconds = [[MusicPlaybackController nowPlayingSong].duration integerValue];
    if(durationInSeconds <= 0.0f || isnan(durationInSeconds)){
        // Handle error
        if(![[ReachabilitySingleton sharedInstance] isConnectedToInternet])
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        else
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_FatalSongDurationError];
    } else{
        //setup total song duration label animations
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        _playbackSlider.maximumValue = durationInSeconds;
        
        NSString *newText = [self convertSecondsToPrintableNSStringWithSliderValue:durationInSeconds];
        if(stateOfDurationLabels == DurationLabelStateNotSet){
            //figure it out lol
            _totalDurationLabel.text = newText;
#warning may be able to remove weird counter code in this accomodateinterface method. check.
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

#pragma mark - Responding to Button Events
//BACK BUTTON
- (void)backwardsButtonTappedOnce
{
    [MusicPlaybackController returnToPreviousTrack];
    [self backwardsButtonLetGo];
    
    float seconds = CMTimeGetSeconds([MusicPlaybackController obtainRawAVPlayer].currentItem.currentTime);
    if(seconds < MZSkipToSongBeginningIfBackBtnTappedBoundary){
        //previous song will actually be loaded
        waitingForNextOrPrevVideoToLoad = YES;
        [MusicPlaybackController pausePlayback];
        self.playbackSlider.enabled = NO;
        [self showNextTrackButton];  //in case it wasnt on screen already
        
        //check if this next song is the first one in the queue
        if([MusicPlaybackController isSongFirstInQueue:[MusicPlaybackController nowPlayingSong]])
            [self hidePreviousTrackButton];
    }
    //else the song will simply start from the beginning...
}

- (void)backwardsButtonBeingHeld{ [self addShadowToButton:backwardButton]; }
- (void)backwardsButtonLetGo{ [self removeShadowForButton:backwardButton]; }

//PLAY BUTTON
- (void)playOrPauseButtonTapped
{
    UIColor *color = [UIColor blackColor];
    UIImage *tempImage;
    if([MusicPlaybackController obtainRawAVPlayer].rate == 0)  //currently paused, resume..
    {
        tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
        UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
        
        [playButton setImage:pauseFilled forState:UIControlStateNormal];
        [MusicPlaybackController explicitlyPausePlayback:NO];
        [MusicPlaybackController resumePlayback];
    }
    else  //playing now, pause..
    {
        tempImage = [UIImage imageNamed:PLAY_IMAGE_FILLED];
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
        
        [playButton setImage:playFilled forState:UIControlStateNormal];
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [MusicPlaybackController pausePlayback];
    }
    playButton.enabled = YES;
    [self playOrPauseButtonLetGo];
}

- (void)playOrPauseButtonBeingHeld{ [self addShadowToButton:playButton]; }
- (void)playOrPauseButtonLetGo{ [self removeShadowForButton:playButton]; }

//FORWARD BUTTON
- (void)forwardsButtonTappedOnce
{
    waitingForNextOrPrevVideoToLoad = YES;
    [MusicPlaybackController pausePlayback];
    self.playbackSlider.enabled = NO;
    [MusicPlaybackController skipToNextTrack];
    [self forwardsButtonLetGo];
    [self showPreviousTrackButton];
    
    //check if this next song is the last one
    if([MusicPlaybackController isSongLastInQueue:[MusicPlaybackController nowPlayingSong]])
        [self hideNextTrackButton];
}

- (void)forwardsButtonBeingHeld{ [self addShadowToButton:forwardButton]; }
- (void)forwardsButtonLetGo{ [self removeShadowForButton:forwardButton]; }

//only toggles the gui! does not mean user hit pause! Used for responding to rate changes during buffering.
- (void)toggleDisplayToPausedState
{
    if(stateOfGUIPlayback == GUIPlaybackStatePlaying ||
       (stateOfGUIPlayback == GUIPlaybackStatePaused && [MusicPlaybackController isPlayerStalled])){
        UIColor *color = [UIColor blackColor];
        UIImage *tempImage = [UIImage imageNamed:PLAY_IMAGE_FILLED];
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
        [playButton setImage:playFilled forState:UIControlStateNormal];
    }
    stateOfGUIPlayback = GUIPlaybackStatePaused;
}
//read comment in method above
- (void)toggleDisplayToPlayingState
{
    if(stateOfGUIPlayback == GUIPlaybackStatePaused && ![MusicPlaybackController isPlayerStalled]){
        UIColor *color = [UIColor blackColor];
        UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
        UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
        [playButton setImage:pauseFilled forState:UIControlStateNormal];
    }
    if(![MusicPlaybackController isPlayerStalled])
        stateOfGUIPlayback = GUIPlaybackStatePlaying;
    else
        [self toggleDisplayToPausedState];
}

//BUTTON SHADOWS
- (void)addShadowToButton:(UIButton *)aButton
{
    aButton.layer.shadowColor = [[UIColor defaultAppColorScheme] darkerColor].CGColor;
    aButton.layer.shadowRadius = 5.0f;
    aButton.layer.shadowOpacity = 1.0f;
    aButton.layer.shadowOffset = CGSizeZero;
}

- (void)removeShadowForButton:(UIButton *)aButton
{
    aButton.layer.shadowColor = [UIColor clearColor].CGColor;
    aButton.layer.shadowRadius = 5.0f;
    aButton.layer.shadowOpacity = 1.0f;
    aButton.layer.shadowOffset = CGSizeZero;
}

- (void)dismissVideoPlayerControllerButtonTapped
{
    [[SongPlayerCoordinator sharedInstance] beginShrinkingVideoPlayer];
    [self preDealloc];
    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Adding and removing GUI buttons on the fly
- (void)hideNextTrackButton
{
    [forwardButton removeFromSuperview];
}

- (void)showNextTrackButton
{
    if([forwardButton isDescendantOfView:self.view])
        return;
    else
        [self.view addSubview:forwardButton];
}

- (void)hidePreviousTrackButton
{
    [backwardButton removeFromSuperview];
}

- (void)showPreviousTrackButton
{
    if([backwardButton isDescendantOfView:self.view])
        return;
    else
        [self.view addSubview:backwardButton];
}


#pragma mark - Key value observing stuff
- (void)setupKeyvalueObservers
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    //not all observers are actually used, but keep in case I have a need down the road.
    [player addObserver:self
             forKeyPath:@"rate"
                options:NSKeyValueObservingOptionNew
                context:kRateDidChangeKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.status"
                options:NSKeyValueObservingOptionNew
                context:kStatusDidChangeKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.duration"
                options:NSKeyValueObservingOptionNew
                context:kDurationDidChangeKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.loadedTimeRanges"
                options:NSKeyValueObservingOptionNew
                context:kTimeRangesKVO];
    
    [self restoreTimeObserver];
    
    //label observers...
    [_totalDurationLabel addObserver:self
                          forKeyPath:@"text"
                             options:NSKeyValueObservingOptionNew
                             context:kTotalDurationLabelDidChange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(killTimeObserver)
                                                 name:MZAppWasBackgrounded
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restoreTimeObserver)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)removeObservers
{
    //temporarily disable logging since this "crash" when removing observers does not impact the program at all.
    Fabric *myFabric = [Fabric sharedSDK];
    myFabric.debug = YES;
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    
    @try{
        [player removeObserver:self forKeyPath:@"rate" context:kRateDidChangeKVO];
        [player removeObserver:self forKeyPath:@"currentItem.status" context:kStatusDidChangeKVO];
        [player removeObserver:self forKeyPath:@"currentItem.duration" context:kDurationDidChangeKVO];
        [player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges" context:kTimeRangesKVO];
    }
    //do nothing, obviously it wasn't attached because an exception was thrown
    @catch(id anException){}
    
    @try {
        [_totalDurationLabel removeObserver:self forKeyPath:@"text" context:kTotalDurationLabelDidChange];
    }
    //do nothing
    @catch (id anException) {}
    
    [self killTimeObserver];
    myFabric.debug = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{    
    //check for duration label change
    if (context == kTotalDurationLabelDidChange) {
        [self accomodateInterfaceBasedOnDurationLabelSize:(UILabel *)object];
    }
    
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    BOOL playbackExplicitlyPaused = [MusicPlaybackController playbackExplicitlyPaused];
    
    if (context == kRateDidChangeKVO) {
        if(player.rate == 0 && !playbackExplicitlyPaused){
            if(! [MusicPlaybackController isInternetProblemSpinnerOnScreen]){
                [self toggleDisplayToPausedState];
            }
            if(!sliderIsBeingTouched && !waitingForNextOrPrevVideoToLoad){
                [player play];
            }
        }
        if(player.rate == 0)
            [self toggleDisplayToPausedState];
        if(player.rate == 1 && ![MusicPlaybackController isPlayerStalled]){
            [self toggleDisplayToPlayingState];
        }
        if([MusicPlaybackController isPlayerStalled])
            [self toggleDisplayToPausedState];;
    } else if (kStatusDidChangeKVO == context) {
        //player "status" has changed. Not particulary useful information.
        if (player.status == AVPlayerStatusReadyToPlay) {
            //line above is new?
            /*
            NSArray * timeRanges = player.currentItem.loadedTimeRanges;
            if (timeRanges && [timeRanges count]){
                CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
                int secondsBuffed = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
                if(secondsBuffed > 0){
                    //NSLog(@"Min buffer reached to continue playback.");
                }
            }
             */
        }
        
    } else if (kTimeRangesKVO == context) {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            /*
             code unneeded for now...
             
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            
            int secondsLoaded = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
            if(secondsLoaded == mostRecentLoadedDuration)
                return;
            else
                mostRecentLoadedDuration = secondsLoaded;
            NSLog(@"New loaded range: %i -> %i", (int)CMTimeGetSeconds(timerange.start), secondsLoaded);
            */
            
            if(player.rate == 0 && !playbackExplicitlyPaused && !waitingForNextOrPrevVideoToLoad && !sliderIsBeingTouched && ![MusicPlaybackController isPlayerStalled]){
                //continue where playback left off...
                [MusicPlaybackController resumePlayback];
                [self toggleDisplayToPlayingState];
            }
        }
    }
}

#pragma mark - Responding to app state
- (void)killTimeObserver
{
    timeObserver = nil;
}

- (void)restoreTimeObserver
{
    if(timeObserver != nil)
        return;
    
    __weak SongPlayerViewController *weakSelf = self;
    __weak AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    CMTime timeInterval = CMTimeMake(1, observationsPerSecond);
    timeObserver = [player addPeriodicTimeObserverForInterval:timeInterval queue:nil usingBlock:^(CMTime time) {
        //code will be called each 1/10th second...
        [weakSelf updatePlaybackTimeSlider];
    }];
}

#pragma mark - Share Button Tapped
- (void)shareButtonTapped
{
    Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
    if(nowPlayingSong){
        NSString *youtubeLinkBase = @"www.youtube.com/watch?v=";
        NSMutableString *shareString = [NSMutableString stringWithString:@"\n"];
        [shareString appendString:youtubeLinkBase];
        [shareString appendString:nowPlayingSong.youtube_id];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, nil];
        
        __block UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:nil];
        __weak UIActivityViewController *weakActivityVC = activityVC;
        __weak SongPlayerViewController *weakSelf = self;
        
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop];
        //set tint color specifically for this VC so that the text and buttons are visible
        [activityVC.view setTintColor:[UIColor defaultAppColorScheme]];
        
        [self removeObservers];
        [activityVC setCompletionHandler:^(NSString *activityType, BOOL completed) {
            //finish your code when the user finish or dismiss...
            [weakSelf restoreTimeObserver];
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
    segue.blurRadius = 100;
    segue.saturationDeltaFactor = .9;
    segue.tintColor = [UIColor blackColor];
    [segue perform];
}

@end
