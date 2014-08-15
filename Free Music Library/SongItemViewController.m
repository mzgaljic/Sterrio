//
//  SongItemViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongItemViewController.h"

@interface SongItemViewController ()
{
    id endOfSongObserver;
}
@property (nonatomic, strong) NSTimer *sliderTimer;
@property (nonatomic, assign) BOOL needToLoadPlayer;  //used to determine if user went all the way 'back' using slide gesture
@property (nonatomic, assign) BOOL needsToDisplayNewVideo;  //used to determine if user is tapping on 'now playing', or a new song.
@property (nonatomic, assign) BOOL playbackOccuring;
@property (nonatomic, assign) BOOL userWantsPlaybackPaused;

@property (nonatomic, strong) NSArray *musicButtons;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *backwardButton;
@end

@implementation SongItemViewController
@synthesize navBar, playerView, playbackTimeSlider = _playbackTimeSlider, currentTimeLabel = _currentTimeLabel, totalDurationLabel = _totalDurationLabel;
static const short STATUS_AND_NAV_BAR_OFFSET = 64;
static NSString *PAUSE_IMAGE_FILLED = @"Pause-Filled";
static NSString *PAUSE_IMAGE_UNFILLED = @"Pause-Line";
static NSString *PLAY_IMAGE_FILLED = @"Play-Filled";
static NSString *PLAY_IMAGE_UNFILLED = @"Play-Line";
static NSString *FORWARD_IMAGE_FILLED = @"Seek-Filled";
static NSString *FORWARD_IMAGE_UNFILLED = @"Seek-Line";
static NSString *BACKWARD_IMAGE_FILLED = @"Backward-Filled";
static NSString *BACKWARD_IMAGE_UNFILLED = @"Backward-Line";

#warning unregister for observer changes if the same player isnt reused! ie: [observedObject removeObserver:inspector forKeyPath:@"openingBalance"];

//for observing AVPlayer notifications
void *kRateDidChangeKVO = &kRateDidChangeKVO;
void *kTimeRangesKVO = &kTimeRangesKVO;

#pragma mark - ViewController lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _backwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _musicButtons = @[_backwardButton, _playButton, _forwardButton];
    
    _needToLoadPlayer = YES;
    _needsToDisplayNewVideo = [YouTubeMoviePlayerSingleton needsToDisplayNewVideo];
    _playbackTimeSlider.enabled = NO;
    _playbackTimeSlider.dataSource = self;
    _sliderTimer = nil;
    
    _currentTimeLabel.text = @"--:--";
    _totalDurationLabel.text = @"--:--";
    
    //hack to hide back button text. This ALSO changes future back buttons if more stuff is pushed. BEWARE.
    self.navigationController.navigationBar.topItem.title = @"";
    
    PlaybackModelSingleton * playbackModel = [PlaybackModelSingleton createSingleton];
    if(_needsToDisplayNewVideo)
        [self setUpVideoPlayerUsingVideoID:playbackModel.nowPlayingSong.youtubeId];
    else
        [self startPlayback:nil];
    
    //set song/album details for currently selected song
    self.songNameLabel.text = playbackModel.nowPlayingSong.songName;
    NSString *navBarTitle = [NSString stringWithFormat:@"%lu of %lu",(unsigned long)playbackModel.printFrienlyNowPlayingSongNumber,
                                                                    (unsigned long)playbackModel.printFrienlyTotalSongsInCollectionNumber];
    self.navBar.title = navBarTitle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(shareButtonTapped)];
    
    if(_needToLoadPlayer){
        [self setupVideoPlayerViewDimensionsAndShowLoading];
        [self positionMusicButtonsOnScreenAndSetThemUp];
        [self positionPlaybackSliderOnScreen];
    } else{
        //force player to seek .2 second forward, this way the video refreshes and doesn't get stuck (issue with back sliding gesture)
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CMTime currentTime = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer].currentItem.currentTime;
            Float64 currentTimeValue = CMTimeGetSeconds(currentTime);
            AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
            CMTime newTime = CMTimeMakeWithSeconds(currentTimeValue + 0.2f, currentTime.timescale);
            
            dispatch_async( dispatch_get_main_queue(), ^{
                
                [player seekToTime:newTime];
            });
        });
    }
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self.navigationController setNavigationBarHidden:NO];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setUpLockScreenInfoAndArt];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    _needToLoadPlayer = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNavigationBarHidden:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PlaybackStartedNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _needToLoadPlayer = YES;
}

#pragma mark - Memory Warning
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}
                                              
#pragma mark - Share Button
- (void)shareButtonTapped
{
    NSString *youtubeLinkBeginning = @"youtube.com/watch?v=";
    NSMutableString *shareString = [NSMutableString stringWithString:@"Check out this song:\n"];
    [shareString appendString:youtubeLinkBeginning];
    [shareString appendString:[PlaybackModelSingleton createSingleton].nowPlayingSong.youtubeId];
    //UIImage *shareImage = [UIImage imageNamed:@"Pause-Filled"];
    //NSURL *shareUrl = nil;
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, nil];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                       UIActivityTypeAssignToContact,
                                       UIActivityTypeSaveToCameraRoll];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - Music Buttons
- (void)positionMusicButtonsOnScreenAndSetThemUp  //buttons are initialized in viewDidLoad
{
    //make images fill up frame, change button hit area
    for(UIButton *aButton in _musicButtons){
        aButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        aButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        [aButton setHitTestEdgeInsets:UIEdgeInsetsMake(-36, -36, -36, -36)];
    }
    
    float imgScaleFactor = 1.4f;
    float percentDownScreen = 0.84f;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    //play button
    UIImage *playImage = [UIImage imageNamed:PLAY_IMAGE_FILLED];
    float playButtonWidth = playImage.size.width * imgScaleFactor;
    float playButtonHeight = playImage.size.height * imgScaleFactor;
    float yValue = ceil(screenHeight * percentDownScreen);  //want the play button to be 84% of the way down the screen
    //want play button to be in the middle of the screen horizontally
    float xValue = (screenWidth * 0.5) - (playButtonWidth/2);
    _playButton.frame = CGRectMake(xValue +2, yValue, playButtonWidth, playButtonHeight);
    [_playButton setImage:playImage forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:PLAY_IMAGE_UNFILLED] forState: UIControlStateHighlighted];
    
    //seek backward button
    UIImage *backwardImage = [UIImage imageNamed:BACKWARD_IMAGE_FILLED];
    float backwardButtonWidth = backwardImage.size.width * imgScaleFactor;
    float backwardButtonHeight = backwardImage.size.height * imgScaleFactor;
    //will be in between the play button and left side of screen
    xValue = (((screenWidth /2) - ((screenWidth /2) /2)) - backwardButtonWidth/2);
    //middle y value in the center of the play button
    float middlePointVertically = _playButton.center.y;
    yValue = (middlePointVertically - (backwardImage.size.height/1.5));
    _backwardButton.frame = CGRectMake(xValue, yValue -1, backwardButtonWidth, backwardButtonHeight);
    [_backwardButton setImage:backwardImage forState:UIControlStateNormal];
    [_backwardButton setImage:[UIImage imageNamed:BACKWARD_IMAGE_UNFILLED] forState: UIControlStateHighlighted];
    
    //see forward button
    UIImage *forwardImage = [UIImage imageNamed:FORWARD_IMAGE_FILLED];
    float forwardButtonWidth = forwardImage.size.width * imgScaleFactor;
    float forwardButtonHeight = forwardImage.size.height * imgScaleFactor;
    //will be in between the play button and right side of screen
    xValue = (((screenWidth /2) + ((screenWidth /2) /2)) - forwardButtonWidth/2);
    yValue = (middlePointVertically - (forwardImage.size.height/1.5));
    _forwardButton.frame = CGRectMake(xValue +3, yValue -1, forwardButtonWidth, forwardButtonHeight);
    [_forwardButton setImage:forwardImage forState:UIControlStateNormal];
    [_forwardButton setImage:[UIImage imageNamed:FORWARD_IMAGE_UNFILLED] forState: UIControlStateHighlighted];
    
    //add buttons to the viewControllers view
    for(UIButton *aButton in _musicButtons){
        [self.view addSubview:aButton];
    }
}

#pragma mark - Playback Time Slider
- (void)setupPlaybackTimeSlider
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CMTime cmTime = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer].currentItem.asset.duration;
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
        
        dispatch_async( dispatch_get_main_queue(), ^{
            _playbackTimeSlider.minimumValue = 0.0f;
            _playbackTimeSlider.maximumValue = durationInSeconds;
            _playbackTimeSlider.popUpViewCornerRadius = 12.0;
            [_playbackTimeSlider setMaxFractionDigitsDisplayed:0];
            _playbackTimeSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
            _playbackTimeSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:24];
            _playbackTimeSlider.textColor = [UIColor whiteColor];
            _playbackTimeSlider.minimumTrackTintColor = [UIColor defaultSystemTintColor];
            
            //set duration label
            if(_needsToDisplayNewVideo)
                [_totalDurationLabel.layer addAnimation:animation forKey:@"changeTextTransition"];  //animates the duration once its determined
            _totalDurationLabel.text = [self convertSecondsToPrintableNSStringWithSliderValue:durationInSeconds];  //just sets duration, already known.
        });
    });
}

- (void)positionPlaybackSliderOnScreen
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    //setup current time label
    float xValue = screenWidth * 0.02f;
    float yValue = ceil(screenHeight * 0.74f);
    float widthValue = 43.0f;  //hardcoded because i counted how wide it needs to be to fit our text
    //67 for including hours
    float heightValue = 21.0f;
    [_currentTimeLabel setFrame:CGRectMake(xValue, yValue, widthValue, heightValue)];
    float currentTimeLabelxValue = xValue;
    float currentTimeLabelWidthValue = widthValue;

    //setup slider
    xValue = _playbackTimeSlider.frame.origin.x;  //taken from autolayout
    yValue = yValue;
    widthValue = _playbackTimeSlider.frame.size.width; //taken from autolayout
    heightValue = heightValue;
    [_playbackTimeSlider setFrame:CGRectMake(xValue, yValue, widthValue, heightValue)];
    
    //setup total duration label
    xValue = xValue + widthValue + (currentTimeLabelxValue / 2.0f);
    yValue = yValue;
    widthValue = currentTimeLabelWidthValue;
    heightValue = heightValue;
    [_totalDurationLabel setFrame:CGRectMake(xValue, yValue, widthValue, heightValue)];
    
    _currentTimeLabel.textAlignment = NSTextAlignmentRight;
    _totalDurationLabel.textAlignment = NSTextAlignmentLeft;
}

- (void)playbackStarted
{
    _playbackTimeSlider.enabled = YES;
    [self updatePlaybackTimeSlider];
    
    //videoLayer is ready, start showing it on screen, hide the loading placeholder!
    [MRProgressOverlayView dismissAllOverlaysForView:self.playerView animated:YES];
}

- (IBAction)playbackSliderValueHasChanged:(id)sender
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        CMTime newTime = CMTimeMakeWithSeconds(_playbackTimeSlider.value, 1);
        [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] seekToTime:newTime];
    });
}

static BOOL playAfterMovingSlider = YES;
static BOOL sliderIsBeingTouched = NO;
- (IBAction)playbackSliderEditingHasBegun:(id)sender
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
        if(player.rate == 0)
            playAfterMovingSlider = NO;
        [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] pause];
        sliderIsBeingTouched = YES;
    });
}

- (IBAction)playbackSliderEditingHasEnded:(id)sender
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Add code here to do background processing
        if(playAfterMovingSlider)
            [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] play];
        playAfterMovingSlider = YES;  //reset value
        sliderIsBeingTouched = NO;
    });
}

//used to update WHILE playback is taking place (user is not touching slider)
- (void)updatePlaybackTimeSlider
{
    if(sliderIsBeingTouched)
        return;
    /**
    if(_playbackTimeSlider.value == _playbackTimeSlider.maximumValue){
        [_sliderTimer invalidate];
        _sliderTimer = nil;
        return;
    }
     */
    else if(_sliderTimer != nil)
    {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CMTime currentTime = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer].currentItem.currentTime;
            Float64 currentTimeValue = CMTimeGetSeconds(currentTime);
            
            dispatch_async( dispatch_get_main_queue(), ^{

                //sets the value directly from the value, since playback could stutter or pause! So you can't increment by 1 each second.
                [_playbackTimeSlider setValue:(currentTimeValue) animated:YES];
            });
        });
    } else{
        //timer not created yet...
        float everySecond = 1.0f;
        _sliderTimer = [NSTimer scheduledTimerWithTimeInterval:everySecond
                                                        target:self
                                                      selector:@selector(updatePlaybackTimeSlider)
                                                      userInfo:nil
                                                       repeats:YES];
    }
}

#pragma mark - Playback Time Slider Data Source
- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value
{
    NSString *returnString = [self convertSecondsToPrintableNSStringWithSliderValue:value];
    _currentTimeLabel.text = returnString;
    return returnString;
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

#pragma mark - Setting up Video Player size and setting up spinner
- (void)setupVideoPlayerViewDimensionsAndShowLoading
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //entering view controller in landscape, show fullscreen video
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGFloat screenWidth = screenRect.size.width;
            CGFloat screenHeight = screenRect.size.height;
            
            dispatch_async( dispatch_get_main_queue(), ^{
                //+1 is because the view ALMOST covered the full screen.
                [self.playerView setFrame:CGRectMake(0, 0, ceil(screenHeight +1), screenWidth)];
                //hide status bar
                toOrienation = orientation;  //value used in prefersStatusBarHidden
                [self prefersStatusBarHidden];
                [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
                
                if(_needsToDisplayNewVideo)
                    [MRProgressOverlayView showOverlayAddedTo:self.playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
                [self.playerView setBackgroundColor:[UIColor blackColor]];
            });
        });
        
    }
    else
    {
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //show portrait player
            float widthOfScreenRoationIndependant;
            float  a = [[UIScreen mainScreen] bounds].size.height;
            float b = [[UIScreen mainScreen] bounds].size.width;
            if(a < b)
                widthOfScreenRoationIndependant = a;
            else
                widthOfScreenRoationIndependant = b;
            float frameHeight = [self videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];

            dispatch_async( dispatch_get_main_queue(), ^{
                [self.playerView setFrame:CGRectMake(0, STATUS_AND_NAV_BAR_OFFSET, self.view.frame.size.width, frameHeight)];
                
                if(_needsToDisplayNewVideo)
                    [MRProgressOverlayView showOverlayAddedTo:self.playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
                [self.playerView setBackgroundColor:[UIColor blackColor]];
            });
        });
    }
}

#pragma mark - 16:9 Aspect ratio helper
- (float)videoHeightInSixteenByNineAspectRatioGivenWidth:(float)width
{
    float tempVar = width;
    tempVar = ceil(width * 9.0f);
    return ceil(tempVar / 16.0f);
}

#pragma mark - AVPlayer stuff
- (void)startPlayback:(NSURL *)videoUrl
{
    AVPlayer *player;
    if(_needsToDisplayNewVideo){
        YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
        [singleton setAVPlayerInstance:[AVPlayer playerWithURL:videoUrl]];
        player = [singleton AVPlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStarted) name:@"PlaybackStartedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPlaybackTimeSlider) name:@"PlaybackStartedNotification" object:nil];
    } else{  //same video
        //if song is already playing, we have to manually trigger these methods
        [self playbackStarted];
        [self setupPlaybackTimeSlider];
    }
    
    player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    [self.playerView setMovieToPlayer: player];
    [player play];
    
    [self setupNSNotificationVideoPlaybackListenerUsingAVPlayer:player andNSURL:videoUrl];
    
    //begin observing for player notifications
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:kRateDidChangeKVO];
    [player addObserver:self forKeyPath:@"currentItem.loadedTimeRanges"    options:NSKeyValueObservingOptionNew context:kTimeRangesKVO];
    
    CMTime endTime = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer].currentItem.asset.duration;
    endOfSongObserver = [player addBoundaryTimeObserverForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:endTime]] queue:NULL
                                                     usingBlock:^(void)            {
                                                    [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] removeTimeObserver:endOfSongObserver];
                                                    endOfSongObserver = nil;
                                                         
                                                              //jump to next song
#warning incomplete implementation HERE!!!
                                                              
                                                    //if this is the last song in the queue, then do this...
                                                    YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
                                                    [[singleton AVPlayer] pause];
                                                    [singleton setAVPlayerInstance:nil];
                                                    [singleton setAVPlayerLayerInstance:nil];
                                                              
                                                    [PlaybackModelSingleton createSingleton].lastSongHasEnded = YES;
                                                    }];
}

static BOOL playWhenBufferReturns = NO;
//does the observing for AVPlayer notifications
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(kRateDidChangeKVO == context)
    {
        AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
        if(player.rate == 0.0f && [PlaybackModelSingleton createSingleton].userWantsPlaybackPaused == NO)
        {
            playWhenBufferReturns = YES;
            
            //change play button to pause button, if the pause button isnt already on screen
            
        }
    }
    else if (kTimeRangesKVO == context)
    {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            if (CMTIME_COMPARE_INLINE(timerange.duration, >, CMTimeMakeWithSeconds(10, timerange.duration.timescale))) {
                AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
                if (player.rate == 0.0f && playWhenBufferReturns && ![PlaybackModelSingleton createSingleton].userWantsPlaybackPaused) {
                    if(!sliderIsBeingTouched){
                        [player play];
                    }
                    playWhenBufferReturns = NO;
                }
            }
        }
    }
}

//code block below sets up a block that sends out a NSNotification when playback actually starts
- (void)setupNSNotificationVideoPlaybackListenerUsingAVPlayer:(AVPlayer *)player andNSURL:(NSURL *)playbackUrl
{
    // Declare block scope variables to avoid retention cycles from references inside the block
    __block AVPlayer* blockPlayer = player;
    __block id obs;
    
    // Setup boundary time observer to trigger when audio really begins (specifically after 1/10 of a second of playback)
    obs = [player addBoundaryTimeObserverForTimes:
           @[[NSValue valueWithCMTime:CMTimeMake(1, 10)]]
                                           queue:NULL
                                      usingBlock:^{
                                          // Raise a notificaiton when playback has started
                                          [[NSNotificationCenter defaultCenter]
                                           postNotificationName:@"PlaybackStartedNotification"
                                           object:playbackUrl];
                                          
                                          // Remove the boundary time observer
                                          [blockPlayer removeTimeObserver:obs];
                                      }];

}

- (void)setUpVideoPlayerUsingVideoID:(NSString *)videoId
{
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
            BOOL allowedToPlayVideo = NO;  //not checking if we can physically play, but legally (apples 10 minute streaming rule)
            BOOL usingWifi = NO;
            Reachability *reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            NetworkStatus status = [reachability currentReachabilityStatus];
            if (status == ReachableViaWiFi){
                //WiFi
                allowedToPlayVideo = YES;
                usingWifi = YES;
            }
            else if (status == ReachableViaWWAN)
            {
                //3G
                if(video.duration >= 600)  //user cant watch video longer than 10 minutes without wifi
                    allowedToPlayVideo = NO;
                else
                    allowedToPlayVideo = YES;
            }
            if(allowedToPlayVideo){
                //find video quality closest to setting preferences
                NSDictionary *vidQualityDict = video.streamURLs;
                NSURL *url;
                if(usingWifi){
                    short maxDesiredQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
                    url =[YouTubeMoviePlayerSingleton closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                    
                }else{
                    short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                    url =[YouTubeMoviePlayerSingleton closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }
                
                //Now that we have the url, start playing the video
                [self startPlayback:url];
            }
            else{
                NSString *title = @"Long Video Without Wifi";
                NSString *msg = @"Sorry, playback of long videos (ie: more than 10 minutes) is restricted to Wifi.";
                [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            }
        }
        else
        {
            // Handle error
            NSString *title = @"Trouble Loading Video";
            NSString *msg = @"Sorry, something whacky is going on, please try again.";
            [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
        }
    }];
}

#pragma mark - Lock Screen Song Info & Art
- (void)setUpLockScreenInfoAndArt
{
    Song *nowPlayingSong = [PlaybackModelSingleton createSingleton].nowPlayingSong;
    NSURL *url = [AlbumArtUtilities albumArtFileNameToNSURL:nowPlayingSong.albumArtFileName];
    
    // do something with image
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter) {
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        
        UIImage *albumArtImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        if(albumArtImage != nil){
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: albumArtImage];
            [songInfo setObject:nowPlayingSong.songName forKey:MPMediaItemPropertyTitle];
            if(nowPlayingSong.artist.artistName != nil)
                [songInfo setObject:nowPlayingSong.artist.artistName forKey:MPMediaItemPropertyArtist];
            if(nowPlayingSong.album.albumName != nil)
                [songInfo setObject:nowPlayingSong.album.albumName forKey:MPMediaItemPropertyAlbumTitle];
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
        }
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
        [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Rotation methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        [self.playerView setFrame:CGRectMake(0, 0, ceil(screenHeight +1), screenWidth)];  //+1 is because the view ALMOST covered the full screen.
    }
    else{
        float widthOfScreenRoationIndependant;
        float  a = [[UIScreen mainScreen] bounds].size.height;
        float b = [[UIScreen mainScreen] bounds].size.width;
        if(a < b)
            widthOfScreenRoationIndependant = a;
        else
            widthOfScreenRoationIndependant = b;
        float frameHeight = [self videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
        [self.playerView setFrame:CGRectMake(0, STATUS_AND_NAV_BAR_OFFSET, screenWidth, frameHeight)];
    }
    
    toOrienation = toInterfaceOrientation;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

static UIInterfaceOrientation toOrienation;
- (BOOL)prefersStatusBarHidden
{
    if(toOrienation == UIInterfaceOrientationLandscapeLeft || toOrienation == UIInterfaceOrientationLandscapeRight){
        [self.navigationController setNavigationBarHidden:YES];
        return YES;
    }
    else{
        [self.navigationController setNavigationBarHidden:NO];
        return NO;
    }
}

@end
