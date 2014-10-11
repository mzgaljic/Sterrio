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
@property (weak, nonatomic) IBOutlet AutoScrollLabel *scrollingSongView;
@property (weak, nonatomic) IBOutlet AutoScrollLabel *scrollingArtistAlbumView;
@property (nonatomic, strong) NSTimer *sliderTimer;
@property (nonatomic, assign) BOOL needToLoadPlayer;  //used to determine if user went all the way 'back' using slide gesture
@property (nonatomic, assign) BOOL needsToDisplayNewVideo;  //used to determine if user is tapping on 'now playing', or a new song.
@property (nonatomic, assign) BOOL playbackOccuring;
@property (nonatomic, assign) BOOL userWantsPlaybackPaused;

@property (nonatomic, strong) NSArray *musicButtons;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *backwardButton;

@property (nonatomic, strong) NSString *songLabel;
@property (nonatomic, strong) NSString *artistAlbumLabel;
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
    
    [_backwardButton addTarget:self action:@selector(backwardsButtonTappedOnce)
              forControlEvents:UIControlEventTouchUpInside];
    [_backwardButton addTarget:self action:@selector(backwardsButtonBeingHeld) forControlEvents:UIControlEventTouchDown];
    [_backwardButton addTarget:self action:@selector(backwardsButtonLetGo) forControlEvents:UIControlEventTouchUpOutside];
    [_playButton addTarget:self action:@selector(playOrPauseButtonTapped)
          forControlEvents:UIControlEventTouchUpInside];
    [_playButton addTarget:self action:@selector(playOrPauseButtonBeingHeld) forControlEvents:UIControlEventTouchDown];
    [_playButton addTarget:self action:@selector(playOrPauseButtonLetGo) forControlEvents:UIControlEventTouchUpOutside];
    [_forwardButton addTarget:self action:@selector(forwardsButtonTappedOnce)
             forControlEvents:UIControlEventTouchUpInside];
    [_forwardButton addTarget:self action:@selector(forwardsButtonBeingHeld) forControlEvents:UIControlEventTouchDown];
    [_forwardButton addTarget:self action:@selector(forwardsButtonLetGo) forControlEvents:UIControlEventTouchUpOutside];
    
    _musicButtons = @[_backwardButton, _playButton, _forwardButton];
    
    _needToLoadPlayer = YES;
    _needsToDisplayNewVideo = [YouTubeMoviePlayerSingleton needsToDisplayNewVideo];
    _playbackTimeSlider.enabled = NO;
    _playbackTimeSlider.dataSource = self;
    _sliderTimer = nil;
    
    _currentTimeLabel.text = @"--:--";
    _totalDurationLabel.text = @"--:--";
    _currentTimeLabel.textColor = [UIColor blackColor];
    _totalDurationLabel.textColor = [UIColor blackColor];
    
    //hack to hide back button text. This ALSO changes future back buttons if more stuff is pushed. BEWARE.
    self.navigationController.navigationBar.topItem.title = @"";
    
    Song *nowPlayingSong = [self fetchNowPlayingSong];
    //dont check for error fetching here (nil song) because it will fail to play the video and prompt the user anyway
    if(_needsToDisplayNewVideo)
        [self setUpVideoPlayerUsingVideoID:nowPlayingSong.youtube_id];
    else
        [self startPlayback:nil];
    
    //set song/album details for currently selected song
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
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didEnterForeground:)
                                                name:@"UIApplicationWillEnterForegroundNotification" object:nil];
    
    
    NSString *navBarTitle = [NSString stringWithFormat:@"%i of %i",
                             [[self printFriendlySongIndex] intValue],
                             [self numberOfSongsInCoreDataModel]];
    self.navBar.title = navBarTitle;
}

- (void)didEnterForeground:(NSNotification*)sender;
{
    self.scrollingSongView.text = _songLabel;
    self.scrollingArtistAlbumView.text = _artistAlbumLabel;
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
}

- (void)dealloc
{
    _needToLoadPlayer = YES;
    _sliderTimer = nil;
    _musicButtons = nil;
    _playButton = nil;
    _forwardButton = nil;
    _backwardButton = nil;
    _printFriendlySongIndex = nil;
}

#pragma mark - Fetch Now Playing Song
- (Song *)fetchNowPlayingSong
{
    Song *nowPlayingSong;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"nowPlaying = %@", [NSNumber numberWithBool:YES]];
    NSError *error;
    NSArray *matches = [[CoreDataManager context] executeFetchRequest:request error:&error];
    if(matches){
        if([matches count] == 1){
            nowPlayingSong = [matches firstObject];
        } else if([matches count] > 1){
            //handle error where more than one song is marked as 'now playing'
            //let fectching the video silently fail, and set all of the false positives back to NO.
            for(Song *aSong in matches)
                aSong.nowPlaying = [NSNumber numberWithBool:NO];
            [[CoreDataManager sharedInstance] saveContext];
        }
    }
    return nowPlayingSong;
}

#pragma mark - Memory Warning
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}
                                              
#pragma mark - Share Button Tapped
- (void)shareButtonTapped
{
    Song *nowPlayingSong = [self fetchNowPlayingSong];
    if(nowPlayingSong){
        NSString *youtubeLinkBeginning = @"youtube.com/watch?v=";
        NSMutableString *shareString = [NSMutableString stringWithString:@"Check out this song:\n"];
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
        NSString *msg = @"Sorry, we had some trouble getting the song details. Please try again.";
        [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
    }
}

#pragma mark - Music Button actions
- (void)backwardsButtonTappedOnce
{
    //code to rewind to previous song
    
    [self backwardsButtonLetGo];
}

- (void)backwardsButtonBeingHeld{ [self addShadowToButton:_backwardButton]; }

- (void)backwardsButtonLetGo{ [self removeShadowForButton:_backwardButton]; }

- (void)playOrPauseButtonTapped
{
    AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    UIColor *appTint = [UIColor blackColor];
    if(player.rate == 0)
    {
        UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:appTint
                                                              :[UIImage imageNamed:PAUSE_IMAGE_FILLED]];
        
        [_playButton setImage:pauseFilled forState:UIControlStateNormal];
        _userWantsPlaybackPaused = NO;
         [player play];
    }
    else
    {
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:appTint
                                                              :[UIImage imageNamed:PLAY_IMAGE_FILLED]];

        [_playButton setImage:playFilled forState:UIControlStateNormal];
        _userWantsPlaybackPaused = YES;
        [player pause];
    }
    _playButton.enabled = YES;
    
    [self playOrPauseButtonLetGo];
}

- (void)playOrPauseButtonBeingHeld{ [self addShadowToButton:_playButton]; }

- (void)playOrPauseButtonLetGo{ [self removeShadowForButton:_playButton]; }

- (void)forwardsButtonTappedOnce
{
    //code to fast forward
    
    [self forwardsButtonLetGo];
}

- (void)forwardsButtonBeingHeld{ [self addShadowToButton:_forwardButton]; }

- (void)forwardsButtonLetGo{ [self removeShadowForButton:_forwardButton]; }

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

#pragma mark - Positioning Music Buttons
- (void)positionMusicButtonsOnScreenAndSetThemUp  //buttons are initialized in viewDidLoad
{
    //make images fill up frame, change button hit area
    for(UIButton *aButton in _musicButtons){
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
    if(_needsToDisplayNewVideo){
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:appTint
                                                             :[UIImage imageNamed:PLAY_IMAGE_FILLED]];
        
        float playButtonWidth = playFilled.size.width * imgScaleFactor;
        float playButtonHeight = playFilled.size.height * imgScaleFactor;
        yValue = ceil(screenHeight * percentDownScreen);  //want the play button to be 84% of the way down the screen
        //want play button to be in the middle of the screen horizontally
        xValue = (screenWidth * 0.5) - (playButtonWidth/2);
        _playButton.frame = CGRectMake(xValue +2, yValue, playButtonWidth, playButtonHeight);
        [_playButton setImage:playFilled forState:UIControlStateNormal];
        _playButton.enabled = NO;
    } else{
        UIImage *playFilled = [UIImage colorOpaquePartOfImage:appTint
                                                             :[UIImage imageNamed:PAUSE_IMAGE_FILLED]];
        
        float playButtonWidth = playFilled.size.width * imgScaleFactor;
        float playButtonHeight = playFilled.size.height * imgScaleFactor;
        yValue = ceil(screenHeight * percentDownScreen);  //want the play button to be 84% of the way down the screen
        //want play button to be in the middle of the screen horizontally
        xValue = (screenWidth * 0.5) - (playButtonWidth/2);
        _playButton.frame = CGRectMake(xValue +2, yValue, playButtonWidth, playButtonHeight);
        [_playButton setImage:playFilled forState:UIControlStateNormal];
        _playButton.enabled = YES;
    }
    
    
    //seek backward button
    UIImage *backFilled = [UIImage colorOpaquePartOfImage:appTint
                                                         :[UIImage imageNamed:BACKWARD_IMAGE_FILLED]];
    
    float backwardButtonWidth = backFilled.size.width * imgScaleFactor;
    float backwardButtonHeight = backFilled.size.height * imgScaleFactor;
    //will be in between the play button and left side of screen
    xValue = (((screenWidth /2) - ((screenWidth /2) /2)) - backwardButtonWidth/2);
    //middle y value in the center of the play button
    float middlePointVertically = _playButton.center.y;
    yValue = (middlePointVertically - (backFilled.size.height/1.5));
    _backwardButton.frame = CGRectMake(xValue, yValue -1, backwardButtonWidth, backwardButtonHeight);
    [_backwardButton setImage:backFilled forState:UIControlStateNormal];
    
    //see forward button
    UIImage *forwardFilled = [UIImage colorOpaquePartOfImage:appTint
                                                         :[UIImage imageNamed:FORWARD_IMAGE_FILLED]];

    float forwardButtonWidth = forwardFilled.size.width * imgScaleFactor;
    float forwardButtonHeight = forwardFilled.size.height * imgScaleFactor;
    //will be in between the play button and right side of screen
    xValue = (((screenWidth /2) + ((screenWidth /2) /2)) - forwardButtonWidth/2);
    yValue = (middlePointVertically - (forwardFilled.size.height/1.5));
    _forwardButton.frame = CGRectMake(xValue +3, yValue -1, forwardButtonWidth, forwardButtonHeight);
    [_forwardButton setImage:forwardFilled forState:UIControlStateNormal];
    
    //add buttons to the viewControllers view
    for(UIButton *aButton in _musicButtons){
        [self.view addSubview:aButton];
    }
}

#pragma mark - Playback Time Slider
- (void)setupPlaybackTimeSlider
{
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
    
    _playbackTimeSlider.minimumValue = 0.0f;
    _playbackTimeSlider.maximumValue = durationInSeconds;
    _playbackTimeSlider.popUpViewCornerRadius = 12.0;
    [_playbackTimeSlider setMaxFractionDigitsDisplayed:0];
    _playbackTimeSlider.popUpViewColor = [[UIColor defaultSystemTintColor] lighterColor];
    _playbackTimeSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:24];
    _playbackTimeSlider.textColor = [UIColor whiteColor];
    _playbackTimeSlider.minimumTrackTintColor = [UIColor defaultSystemTintColor];
    
    //set duration label
    if(_needsToDisplayNewVideo)
        [_totalDurationLabel.layer addAnimation:animation forKey:@"changeTextTransition"];  //animates the duration once its determined
    _totalDurationLabel.text = [self convertSecondsToPrintableNSStringWithSliderValue:durationInSeconds];  //just sets duration, already known.
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
    [AppEnvironmentConstants setSongHasBeenPlayedSinceLaunch];
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
    // Add code here to do background processing
    AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    if(player.rate == 0)
        playAfterMovingSlider = NO;
    [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] pause];
    sliderIsBeingTouched = YES;
}

- (IBAction)playbackSliderEditingHasEnded:(id)sender
{
    // Add code here to do background processing
    if(playAfterMovingSlider)
        [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] play];
    playAfterMovingSlider = YES;  //reset value
    sliderIsBeingTouched = NO;
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
        //entering view controller in landscape, show fullscreen video
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        //+1 is because the view ALMOST covered the full screen.
        [self.playerView setFrame:CGRectMake(0, 0, ceil(screenHeight +1), screenWidth)];
        //hide status bar
        toOrienation = orientation;  //value used in prefersStatusBarHidden
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        
        if(_needsToDisplayNewVideo)
            [MRProgressOverlayView showOverlayAddedTo:self.playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
        [self.playerView setBackgroundColor:[UIColor blackColor]];
        
    }
    else
    {
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
        float videoFrameHeight = [self videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
        float playerFrameYTempalue = roundf(((heightOfScreenRotationIndependant / 2.0) /1.5));
        int playerYValue = nearestEvenInt((int)playerFrameYTempalue);
        [self.playerView setFrame:CGRectMake(0, playerYValue, self.view.frame.size.width, videoFrameHeight)];
        
        if(_needsToDisplayNewVideo)
            [MRProgressOverlayView showOverlayAddedTo:self.playerView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
        [self.playerView setBackgroundColor:[UIColor blackColor]];
    }
}

//tiny helper function for the setupVideoPlayerViewDimensionsAndShowLoading method
int nearestEvenInt(int to)
{
    return (to % 2 == 0) ? to : (to + 1);
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStarted) name:@"PlaybackStartedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPlaybackTimeSlider) name:@"PlaybackStartedNotification" object:nil];
    } else{  //same video
        //if song is already playing, we have to manually trigger these methods
        [self playbackStarted];
        [self setupPlaybackTimeSlider];
    }
    
    player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    [self.playerView setMovieToPlayer: player];
    [self playOrPauseButtonTapped];
    
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
        if(player.rate == 0.0f && _userWantsPlaybackPaused == NO)
        {
            playWhenBufferReturns = YES;
            
            //change play button to pause button, if the pause button isnt already on screen
            UIColor *appTint = [UIColor blackColor];
            UIImage *pauseFilled = [UIImage colorOpaquePartOfImage:appTint
                                                            :[UIImage imageNamed:PAUSE_IMAGE_FILLED]];
            
            [_playButton setImage:pauseFilled forState:UIControlStateNormal];
        }
    }
    else if (kTimeRangesKVO == context)
    {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            if (CMTIME_COMPARE_INLINE(timerange.duration, >, CMTimeMakeWithSeconds(10, timerange.duration.timescale))) {
                AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
                if (player.rate == 0.0f && playWhenBufferReturns && !_userWantsPlaybackPaused) {
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
        float videoFrameHeight = [self videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
        float playerFrameYTempValue = roundf(((heightOfScreenRotationIndependant / 2.0) /1.5));
        int playerYValue = nearestEvenInt((int)playerFrameYTempValue);
        [self.playerView setFrame:CGRectMake(0,
                                             playerYValue,
                                             widthOfScreenRoationIndependant,
                                             videoFrameHeight)];
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
                             
#pragma mark - Counting Songs in core data
- (int)numberOfSongsInCoreDataModel
{
    //count how many instances there are of the Song entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];
    NSError *error = nil;
    NSUInteger tempCount = [context countForFetchRequest: fetchRequest error: &error];
    if(error == nil){
        count = (int)tempCount;
    }
    return count;
}

@end
