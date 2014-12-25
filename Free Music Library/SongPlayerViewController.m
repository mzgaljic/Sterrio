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
    
    //for key value observing
    id timeObserver;
    int totalVideoDuration;
    int mostRecentLoadedDuration;
}
@end

@implementation SongPlayerViewController
@synthesize navBar, playbackTimeSlider = _playbackTimeSlider, currentTimeLabel = _currentTimeLabel,
            totalDurationLabel = _totalDurationLabel;

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
    //these two observers help us know when this VC must update its GUI due to a new song playing, etc.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateScreenWithInfoForNewSong:)
                                                 name:NEW_SONG_IN_AVPLAYER
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastSongHasFinishedPlayback:)
                                                 name:AVPLAYER_DONE_PLAYING
                                               object:nil];
    _playbackTimeSlider.enabled = NO;
    _playbackTimeSlider.dataSource = self;
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
    [self checkDeviceOrientation];
    [self initAndRegisterAllButtons];
    [self positionMusicButtonsOnScreenAndSetThemUp];
    
    UIBarButtonItem *popButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                               target:self
                                                                               action:@selector(dismissVideoPlayerControllerButtonTapped)];
    self.navigationItem.leftBarButtonItem = popButton;
    [self setupPlaybackTimeSliderAndDuration];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:timeObserver];
#warning need to deregister from key value observers right here!
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
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(player.rate == 0)
        playAfterMovingSlider = NO;
    [player pause];
#warning need to update play/pause button while doing this
    sliderIsBeingTouched = YES;
}

- (IBAction)playbackSliderValueHasChanged:(id)sender
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CMTime newTime = CMTimeMakeWithSeconds(_playbackTimeSlider.value, 1);
        [(MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer] seekToTime:newTime];
    });
}

- (IBAction)playbackSliderEditingHasEnded:(id)sender
{
    if(playAfterMovingSlider)
        [(MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer] play];
    playAfterMovingSlider = YES;  //reset value
    sliderIsBeingTouched = NO;
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
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        CMTime currentTime = ((MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer]).currentItem.currentTime;
        Float64 currentTimeValue = CMTimeGetSeconds(currentTime);
        
        //sets the value directly from the value, since playback could stutter or pause! So you can't increment by 1 each second.
        [_playbackTimeSlider setValue:(currentTimeValue) animated:YES];
    });
    
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

#pragma mark - Positioning Music Buttons (should be loaded first)
- (void)positionMusicButtonsOnScreenAndSetThemUp
{
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
        playButton.enabled = NO;
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
        playButton.enabled = YES;
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
    }
}

#pragma mark - Playback Time Slider
- (void)setupPlaybackTimeSliderAndDuration
{
    CMTime cmTime = ((MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer]).currentItem.asset.duration;
    Float64 durationInSeconds = CMTimeGetSeconds(cmTime);
    
    if(durationInSeconds <= 0.0f || durationInSeconds == NAN){
        // Handle error
        NSString *title = @"Trouble Loading Video";
        NSString *msg = @"Sorry, something whacky is going on, please try again.";
        [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
        [self.navigationController popViewControllerAnimated:YES];
    }
    //setup total song duration lable animations
    CATransition *animation = [CATransition animation];
    animation.duration = 1.0;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    _playbackTimeSlider.minimumValue = 0.0f;
    _playbackTimeSlider.maximumValue = durationInSeconds;
    _playbackTimeSlider.popUpViewCornerRadius = 12.0;
    [_playbackTimeSlider setMaxFractionDigitsDisplayed:0];
    _playbackTimeSlider.popUpViewColor = [[UIColor defaultSystemTintColor] lighterColor];
    _playbackTimeSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:24];
    _playbackTimeSlider.textColor = [UIColor whiteColor];
    _playbackTimeSlider.minimumTrackTintColor = [UIColor defaultSystemTintColor];
    
    //set duration label
    [_totalDurationLabel.layer addAnimation:animation forKey:@"changeTextTransition"];  //animates the duration once its determined
    _totalDurationLabel.text = [self convertSecondsToPrintableNSStringWithSliderValue:durationInSeconds];  //just sets duration, already known.
}

#pragma mark - Responding to Button Events
//BACK BUTTON
- (void)backwardsButtonTappedOnce
{
    //code to rewind to previous song
    [MusicPlaybackController returnToPreviousTrack];
    
    [self backwardsButtonLetGo];
}

- (void)backwardsButtonBeingHeld{ [self addShadowToButton:backwardButton]; }
- (void)backwardsButtonLetGo{ [self removeShadowForButton:backwardButton]; }

//PLAY BUTTON
- (void)playOrPauseButtonTapped
{
    UIColor *color = [UIColor blackColor];
    UIImage *tempImage;
    if([MusicPlaybackController obtainRawAVPlayer].rate == 0)  //playing back
    {
        tempImage = [UIImage imageNamed:PAUSE_IMAGE_FILLED];
        UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:color :tempImage];
        
        [playButton setImage:pauseFilled forState:UIControlStateNormal];
        [MusicPlaybackController explicitlyPausePlayback:NO];
        [MusicPlaybackController resumePlayback];
    }
    else
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
    //code to fast forward
    [MusicPlaybackController skipToNextTrack];
    
    [self forwardsButtonLetGo];
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
    aButton.layer.shadowColor = [[UIColor defaultSystemTintColor] darkerColor].CGColor;
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if (kRateDidChangeKVO == context) {
        float rate = player.rate;
        BOOL internetConnectionPresent;
        BOOL videoCompletelyBuffered = (mostRecentLoadedDuration == totalVideoDuration);
        
        //make sure we notify the GUI (video player) in case its on screen
        if(rate == 1)
            [self playbackHasResumed];
        else
            [self playbackHasStopped];
        
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        if ([networkReachability currentReachabilityStatus] == NotReachable)
            internetConnectionPresent = NO;
        else
            internetConnectionPresent = YES;
        
        if(rate != 0 && mostRecentLoadedDuration != 0 &&internetConnectionPresent){  //playing
            NSLog(@"Playing");
            
        } else if(rate == 0 && !videoCompletelyBuffered &&!internetConnectionPresent){  //stopped
            //Playback has stopped due to an internet connection issue.
            NSLog(@"Video stopped, no connection.");
            
        }else{  //paused
            NSLog(@"Paused");
        }
        
    } else if (kStatusDidChangeKVO == context) {
        //player "status" has changed. Not particulary useful information.
        if (player.status == AVPlayerStatusReadyToPlay) {
            NSArray * timeRanges = player.currentItem.loadedTimeRanges;
            if (timeRanges && [timeRanges count]){
                CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
                int secondsBuffed = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
                if(secondsBuffed > 0){
                    NSLog(@"Min buffer reached to continue playback.");
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
            
            //if paused, check if user wanted it paused. if not, resume playback since buffer is back
            if(!(player.rate == 1) && ![MusicPlaybackController playbackExplicitlyPaused]){
                [MusicPlaybackController resumePlayback];
            }
        }
    }
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
        NSString *msg = @"Sorry, something went wrong while getting your song information.";
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
    if(buttonIndex == 0)
        [self dismissVideoPlayerControllerButtonTapped];
}


@end
