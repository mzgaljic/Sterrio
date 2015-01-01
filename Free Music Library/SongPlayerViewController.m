//
//  SongPlayerViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongPlayerViewController.h"

@interface SongPlayerViewController ()
{
    NSArray *musicButtons;
    UIButton *playButton;
    UIButton *forwardButton;
    UIButton *backwardButton;
    NSString *songLabel;
    NSString *artistAlbumLabel;
    
    BOOL playerButtonsSetUp;
    BOOL waitingForNextOrPrevVideoToLoad;
    UIColor *colorOfPlaybackButtons;
    
    //for key value observing
    id timeObserver;
    int totalVideoDuration;
    int mostRecentLoadedDuration;
}
@end

@implementation SongPlayerViewController
@synthesize navBar, currentTimeLabel = _currentTimeLabel,totalDurationLabel = _totalDurationLabel, playbackSlider = _playbackSlider;

static UIInterfaceOrientation lastKnownOrientation;
static BOOL playAfterMovingSlider = YES;
static BOOL sliderIsBeingTouched = NO;

NSString * const NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
NSString * const AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";

NSString * const PAUSE_IMAGE_FILLED = @"Pause-Filled";
NSString * const PAUSE_IMAGE_UNFILLED = @"Pause-Line";
NSString * const PLAY_IMAGE_FILLED = @"Play-Filled";
NSString * const PLAY_IMAGE_UNFILLED = @"Play-Line";
NSString * const FORWARD_IMAGE_FILLED = @"Seek-Filled";
NSString * const FORWARD_IMAGE_UNFILLED = @"Seek-Line";
NSString * const BACKWARD_IMAGE_FILLED = @"Backward-Filled";
NSString * const BACKWARD_IMAGE_UNFILLED = @"Backward-Line";

//key value observing (AVPlayer)
void *kCurrentItemDidChangeKVO  = &kCurrentItemDidChangeKVO;
void *kRateDidChangeKVO         = &kRateDidChangeKVO;
void *kStatusDidChangeKVO       = &kStatusDidChangeKVO;
void *kDurationDidChangeKVO     = &kDurationDidChangeKVO;
void *kTimeRangesKVO            = &kTimeRangesKVO;
void *kBufferFullKVO            = &kBufferFullKVO;
void *kBufferEmptyKVO           = &kBufferEmptyKVO;
void *kDidFailKVO               = &kDidFailKVO;

#pragma mark - VC Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    colorOfPlaybackButtons = [UIColor defaultAppColorScheme];
    waitingForNextOrPrevVideoToLoad = NO;
    [self initAndRegisterAllButtons];
    
    //these two observers help us know when this VC must update its GUI due to a new song playing, etc.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateScreenWithInfoForNewSong:)
                                                 name:NEW_SONG_IN_AVPLAYER
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastSongHasFinishedPlayback:)
                                                 name:AVPLAYER_DONE_PLAYING
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackOfVideoHasBegun)
                                                 name:@"PlaybackStartedNotification"
                                               object:nil];
    //self.playbackSlider.enabled = NO;
    self.playbackSlider.dataSource = self;
    [[SongPlayerCoordinator sharedInstance] setDelegate:self];
    
    _currentTimeLabel.text = @"--:--";
    _totalDurationLabel.text = @"--:--";
    _currentTimeLabel.textColor = [UIColor blackColor];
    _totalDurationLabel.textColor = [UIColor blackColor];
    
    [self setupKeyvalueObservers];
}

static int numTimesVCLoaded = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    if(numTimesVCLoaded == 0){
         [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];  //sets up the player only once
        
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player startPlaybackOfSong:nowPlaying goingForward:YES];
        //avplayer will control itself for the most part now...
    }
    numTimesVCLoaded++;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(shareButtonTapped)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarArrowDown"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(dismissVideoPlayerControllerButtonTapped)];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self positionMusicButtonsOnScreenAndSetThemUp];
    
    [self checkDeviceOrientation];
    [self positionPlaybackSliderOnScreen];
    
    if([MusicPlaybackController obtainRawAVPlayer].rate == 1)  //takes care of duration label, slider, etc.
        [self playbackOfVideoHasBegun];
    else{
        [_playbackSlider setMaximumValue:0];
        [_playbackSlider setValue:0];
        _playbackSlider.enabled = NO;
    }
    
    //check if this song is the last one
    if([MusicPlaybackController numMoreSongsInQueue] == 0)
        [self hideNextTrackButton];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(playerButtonsSetUp == NO)
        [self positionMusicButtonsOnScreenAndSetThemUp];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:timeObserver];
    [self removeObservers];
}

#pragma mark - Check and update GUI based on device orientation (or responding to events)
- (void)lastSongHasFinishedPlayback:(NSNotification *)object
{
#warning desired for behavior after queue finishes playing goes here
}

//NOT the same as updating the lock screen. this is specifically the info shown
//in this VC (song name, updating song index, etc)
- (void)updateScreenWithInfoForNewSong:(NSNotification *)object
{
    /*
    Song *newSong = (Song *)object;
     _songLabel = nowPlayingSong.songName;
     self.scrollingSongView.text = _songLabel;
     self.scrollingSongView.textColor = [UIColor blackColor];
     self.scrollingSongView.font = [UIFont fontWithName:@"HelveticaNeue" size:40.0f];
     
     NSMutableString *artistAlbumLabel = [NSMutableString string];
     if(nowPlayingSong.artist != nil)
     [artistAlbumLabel appendString:nowPlayingSong.artist.artistName];
     if(nowPlayingSong.album != nil)
     {
     if(nowPlayingSong.artist != nil)
     [artistAlbumLabel appendString:@" ・ "];
     [artistAlbumLabel appendString:nowPlayingSong.album.albumName];
     }
     _artistAlbumLabel = artistAlbumLabel;
     self.scrollingArtistAlbumView.text = _artistAlbumLabel;
     self.scrollingArtistAlbumView.textColor = [UIColor blackColor];
     self.scrollingArtistAlbumView.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:self.scrollingSongView.font.pointSize];
     self.scrollingArtistAlbumView.scrollSpeed = 20.0;
     
     NSString *navBarTitle = [NSString stringWithFormat:@"%i of %i",
     [[self printFriendlySongIndex] intValue],
     [self numberOfSongsInCoreDataModel]];
     self.navBar.title = navBarTitle;
     */
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
        return YES;
    }
    else{
        [self.navigationController setNavigationBarHidden:NO];
        return NO;
    }
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
        [playerView setFrame:CGRectMake(0, 0, ceil(screenHeight +1), screenWidth)];  //make frame full screen
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
        [playerView setFrame:CGRectMake(0,   playerYValue,
                                             widthOfScreenRoationIndependant,
                                             videoFrameHeight)];
        [self positionMusicButtonsOnScreenAndSetThemUp];
    }
    
    lastKnownOrientation = toInterfaceOrientation;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {  //selector works on iOS7+
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

#pragma mark - Responding to Player Playback Events (rate, internet connection, etc.)
- (IBAction)playbackSliderEditingHasBegun:(id)sender
{
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player.rate == 0)
        playAfterMovingSlider = NO;
    sliderIsBeingTouched = YES;
    [player pause];
    [self toggleDisplayToPausedState];
}
- (IBAction)playbackSliderEditingHasEndedA:(id)sender  //touch up inside
{
    sliderIsBeingTouched = NO;
    if(playAfterMovingSlider)
        [[MusicPlaybackController obtainRawAVPlayer] play];
    playAfterMovingSlider = YES;  //reset value
}
- (IBAction)playbackSliderEditingHasEndedB:(id)sender  //touch up outside
{
    [self playbackSliderEditingHasEndedA:nil];
}

- (IBAction)playbackSliderValueHasChanged:(id)sender
{
    CMTime newTime = CMTimeMakeWithSeconds(_playbackSlider.value, 1);
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
    //sets the value directly from the value, since playback could stutter or pause! So you can't increment by 1 each second.
    [self.playbackSlider setValue:(currentTimeValue) animated:YES];
}

- (NSString *)convertSecondsToPrintableNSStringWithSliderValue:(float)value
{
    NSUInteger totalSeconds = value;
    NSString *returnString;
    short  seconds = totalSeconds % 60;
    short minutes = (totalSeconds / 60) % 60;
    short hours = (short)totalSeconds / 3600;
    
    if(minutes < 10 && hours == 0)  //we can shorten the text
        returnString = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
    else if(hours > 0)
    {
        if(hours < 9)
            returnString = [NSString stringWithFormat:@"%i:%02d:%02d",hours, minutes, seconds];
        else
            returnString = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    }
    else
        returnString = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    return returnString;
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
- (void)positionMusicButtonsOnScreenAndSetThemUp
{
    if(playerButtonsSetUp == YES){
        //dont need to set them up, just re-animate a "fade in"
        for(UIButton *aButton in musicButtons){
            aButton.alpha = 0.0;  //make button transparent
            [UIView animateWithDuration:0.80  //now animate a "fade in"
                                  delay:0.0
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{ aButton.alpha = 1.0; }
                             completion:nil];
        }
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
        [UIView animateWithDuration:0.80  //now animate a "fade in"
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{ aButton.alpha = 1.0; }
                         completion:nil];
    }
    playerButtonsSetUp = YES;
}

#pragma mark - Playback Time Slider
- (void)positionPlaybackSliderOnScreen
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    int labelWidth = 43;  //hardcoded because i counted how wide it needs to be to fit our text (67 for including hours)
    int labelHeight = 21;
    int padding = 10;
    
    //setup current time label
    int labelXValue = screenWidth * 0.02f;
    int yValue = screenHeight * 0.74f;
    [_currentTimeLabel setFrame:CGRectMake(labelXValue, yValue, labelWidth, labelHeight)];
    int currentTimeLabelxValue = labelXValue;
    
    //setup slider
    int xValue = currentTimeLabelxValue + labelWidth + padding;
    //widthValue = self.playbackSlider.frame.size.width; //taken from autolayout
    int sliderWidth = screenWidth - ((labelXValue + labelWidth + padding) * 2);
    int sliderHeight = labelHeight;
    [self.playbackSlider setFrame:CGRectMake(xValue, yValue, sliderWidth, sliderHeight)];
    
    //slider settings
    self.playbackSlider.minimumValue = 0.0f;
    self.playbackSlider.popUpViewCornerRadius = 12.0;
    [self.playbackSlider setMaxFractionDigitsDisplayed:0];
    self.playbackSlider.popUpViewColor = [[UIColor defaultAppColorScheme] lighterColor];
    self.playbackSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:24];
    self.playbackSlider.textColor = [UIColor whiteColor];
    self.playbackSlider.minimumTrackTintColor = [[UIColor defaultAppColorScheme] lighterColor];
    
    //setup total duration label
    labelXValue = xValue + sliderWidth + padding;
    yValue = yValue;
    [_totalDurationLabel setFrame:CGRectMake(labelXValue, yValue, labelWidth, labelHeight)];
    
    _currentTimeLabel.textAlignment = NSTextAlignmentRight;
    _totalDurationLabel.textAlignment = NSTextAlignmentLeft;
}

- (void)displayTotalSliderAndLabelDuration
{
    CMTime cmTime = [MusicPlaybackController obtainRawAVPlayer].currentItem.asset.duration;
    Float64 durationInSeconds = CMTimeGetSeconds(cmTime);
    
    if(durationInSeconds <= 0.0f || isnan(durationInSeconds)){
        // Handle error
        if(![self isInternetReachable]){
            [MyAlerts displayAlertWithAlertType:CannotConnectToYouTube];

        } else{
            NSString *title = @"Trouble Loading Video";
            NSString *msg = @"A fatal error has occured, please try again.";
            [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            [self dismissVideoPlayerControllerButtonTapped];
        }
    } else{
        //setup total song duration label animations
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        self.playbackSlider.maximumValue = durationInSeconds;
        
        //set duration label
        [_totalDurationLabel.layer addAnimation:animation forKey:@"changeTextTransition"];  //animates the duration once its determined
        _totalDurationLabel.text = [self convertSecondsToPrintableNSStringWithSliderValue:durationInSeconds];  //just sets duration, already known.
    }
}

#pragma mark - Responding to Button Events
//BACK BUTTON
- (void)backwardsButtonTappedOnce
{
    waitingForNextOrPrevVideoToLoad = YES;
    [[MusicPlaybackController obtainRawAVPlayer] pause];
    self.playbackSlider.enabled = NO;
    [MusicPlaybackController returnToPreviousTrack];
    [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
    [MusicPlaybackController simpleSpinnerOnScreen:YES];
    [self backwardsButtonLetGo];
    [self showNextTrackButton];  //in case it wasnt on screen already
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
    [[MusicPlaybackController obtainRawAVPlayer] pause];
    self.playbackSlider.enabled = NO;
    [MusicPlaybackController skipToNextTrack];
    [self showSpinnerForBasicLoadingOnView:[MusicPlaybackController obtainRawPlayerView]];
    [MusicPlaybackController simpleSpinnerOnScreen:YES];
    [self forwardsButtonLetGo];
    
    //check if this next song is the last one
    if([MusicPlaybackController numMoreSongsInQueue] == 0)
        [self hideNextTrackButton];
}

- (void)forwardsButtonBeingHeld{ [self addShadowToButton:forwardButton]; }
- (void)forwardsButtonLetGo{ [self removeShadowForButton:forwardButton]; }

//only toggles the gui! does not mean user hit pause! Used for responding to rate changes during buffering.
- (void)toggleDisplayToPausedState
{
    UIColor *color = [UIColor blackColor];
    UIImage *tempImage = [UIImage imageNamed:PLAY_IMAGE_FILLED];
    UIImage *playFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
    [playButton setImage:playFilled forState:UIControlStateNormal];
}
//read comment in method above
- (void)toggleDisplayToPlayingState
{
    UIColor *color = [UIColor blackColor];
    UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
    UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
    [playButton setImage:pauseFilled forState:UIControlStateNormal];
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


#pragma mark - Key value observing stuff
- (void)setupKeyvalueObservers
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    
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
    [player addObserver:self
             forKeyPath:@"currentItem.playbackBufferFull"
                options:NSKeyValueObservingOptionNew
                context:kBufferFullKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.playbackBufferEmpty"
                options:NSKeyValueObservingOptionNew
                context:kBufferEmptyKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.error"
                options:NSKeyValueObservingOptionNew
                context:kDidFailKVO];
    
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, 100) queue:nil usingBlock:^(CMTime time) {
        //code will be called each 1/10th second....  NSLog(@"Playback time %.5f", CMTimeGetSeconds(time));
        [self updatePlaybackTimeSlider];
    }];
}

- (void)removeObservers
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    
    @try{
        [player removeObserver:self forKeyPath:@"rate"];
        [player removeObserver:self forKeyPath:@"currentItem.status"];
        [player removeObserver:self forKeyPath:@"currentItem.duration"];
        [player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges"];
        [player removeObserver:self forKeyPath:@"currentItem.playbackBufferFull"];
        [player removeObserver:self forKeyPath:@"currentItem.playbackBufferEmpty"];
        [player removeObserver:self forKeyPath:@"currentItem.error"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    BOOL playbackExplicitlyPaused = [MusicPlaybackController playbackExplicitlyPaused];
    
    if (kRateDidChangeKVO == context) {
        if(player.rate == 0 && !playbackExplicitlyPaused){
            if(! [MusicPlaybackController isInternetProblemSpinnerOnScreen]){
                [self showSpinnerForBasicLoadingOnView:playerView];
                [MusicPlaybackController simpleSpinnerOnScreen:YES];
                [self toggleDisplayToPausedState];
            }
            if(!sliderIsBeingTouched)
                [player play];
        } else if(player.rate == 1){
            [self dismissAllSpinnersForView:playerView];
            [MusicPlaybackController noSpinnersOnScreen];
            [self toggleDisplayToPlayingState];
        }
    } else if (kStatusDidChangeKVO == context) {
        //player "status" has changed. Not particulary useful information.
        if (player.status == AVPlayerStatusReadyToPlay) {
            NSArray * timeRanges = player.currentItem.loadedTimeRanges;
            if (timeRanges && [timeRanges count]){
                CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
                int secondsBuffed = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
                if(secondsBuffed > 0){
                    //NSLog(@"Min buffer reached to continue playback.");
                }
            }
        }
        
    } else if (kTimeRangesKVO == context) {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            
            int secondsLoaded = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
            if(secondsLoaded == mostRecentLoadedDuration)
                return;
            else
                mostRecentLoadedDuration = secondsLoaded;
            
            //NSLog(@"New loaded range: %i -> %i", (int)CMTimeGetSeconds(timerange.start), secondsLoaded);
            if(player.rate == 0 && !playbackExplicitlyPaused && !waitingForNextOrPrevVideoToLoad && !sliderIsBeingTouched){
                //continue where playback left off...
                [self dismissAllSpinnersForView:playerView];
                [MusicPlaybackController noSpinnersOnScreen];
                [MusicPlaybackController resumePlayback];
                [self toggleDisplayToPlayingState];
            }
        }
    }
}

- (void)playbackOfVideoHasBegun
{
    self.playbackSlider.enabled = YES;
    waitingForNextOrPrevVideoToLoad = NO;
    UIImage *tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
    UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:[UIColor blackColor] :tempImage];
    
    [playButton setImage:pauseFilled forState:UIControlStateNormal];
    [MusicPlaybackController explicitlyPausePlayback:NO];
    [MusicPlaybackController resumePlayback];
    
    [self displayTotalSliderAndLabelDuration];
}

#pragma mark - Loading Spinner & Internet convenience methods
- (BOOL)isInternetReachable
{
    return ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) ? NO : YES;
}

//these methods are also in MyAVPlayer
- (void)showSpinnerForInternetConnectionIssueOnView:(UIView *)displaySpinnerOnMe
{
    if(![MusicPlaybackController isInternetProblemSpinnerOnScreen]){
        [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
        [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe
                                            title:@"Internet connection lost..."
                                             mode:MRProgressOverlayViewModeIndeterminateSmall
                                         animated:YES];
    }
}

- (void)showSpinnerForBasicLoadingOnView:(UIView *)displaySpinnerOnMe
{
    if(![MusicPlaybackController isSimpleSpinnerOnScreen]){
        [MRProgressOverlayView dismissAllOverlaysForView:displaySpinnerOnMe animated:NO];
        [MRProgressOverlayView showOverlayAddedTo:displaySpinnerOnMe title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
    }
}

- (void)dismissAllSpinnersForView:(UIView *)dismissViewOnMe
{
    [MRProgressOverlayView dismissAllOverlaysForView:dismissViewOnMe animated:YES];
}

#pragma mark - Share Button Tapped
- (void)shareButtonTapped
{
    Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
    if(nowPlayingSong){
        NSString *youtubeLinkBeginning = @"www.youtube.com/watch?v=";
        NSMutableString *shareString = [NSMutableString stringWithString:@"\n"];
        [shareString appendString:youtubeLinkBeginning];
        [shareString appendString:nowPlayingSong.youtube_id];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, nil];
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop];
        
        [self presentViewController:activityVC animated:YES completion:nil];
    } else{
        // Handle error
        NSString *title = @"Trouble Sharing";
        NSString *msg = @"There was a problem gathering information for this song.";
        [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
    }
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialogUsingTitle:(NSString *)aTitle andMessage:(NSString *)aMessage
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:aTitle
                                                      message:aMessage
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

- (void)alertView:(SDCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    return;
}


@end
