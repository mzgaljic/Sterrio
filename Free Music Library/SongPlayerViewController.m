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
    BOOL playingBack;
    
    //for key value observing
    id timeObserver;
    int totalVideoDuration;
    int mostRecentLoadedDuration;
    
    NSArray *musicButtons;
    UIButton *playButton;
    UIButton *forwardButton;
    UIButton *backwardButton;
    NSString *songLabel;
    NSString *artistAlbumLabel;
    NSTimer *sliderTimer;
}
@end

@implementation SongPlayerViewController
@synthesize navBar, playbackTimeSlider = _playbackTimeSlider, currentTimeLabel = _currentTimeLabel, totalDurationLabel = _totalDurationLabel;
static UIInterfaceOrientation toOrienation;  //used by "prefersStatusBarHidden" and other rotation code
static BOOL playAfterMovingSlider = YES;
static BOOL sliderIsBeingTouched = NO;

#pragma mark - VC Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newSongIsAboutToStartPlaying:)
                                                 name:NEW_SONG_IN_AVPLAYER
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastSongHasFinishedPlayback:)
                                                 name:AVPLAYER_DONE_PLAYING
                                               object:nil];
    mostRecentLoadedDuration = 0;
    _playbackTimeSlider.enabled = NO;
    _playbackTimeSlider.dataSource = self;
    sliderTimer = nil;
    
    _currentTimeLabel.text = @"--:--";
    _totalDurationLabel.text = @"--:--";
    _currentTimeLabel.textColor = [UIColor blackColor];
    _totalDurationLabel.textColor = [UIColor blackColor];
    
    //hack for hiding back bttn text. (affects other back bttns if more VC's pushed)
    self.navigationController.navigationBar.topItem.title = @"";
}

static int numTimesVCLoaded = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(numTimesVCLoaded == 0)
        [self setUpFloatingImageViewAndPlayer];  //sets up the video GUI
    numTimesVCLoaded++;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(shareButtonTapped)];
    [self checkDeviceOrientation];
    
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    [player startPlaybackOfSong:nowPlaying goingForward:YES];
    //avplayer will control itself for the most part now...
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setUpLockScreenInfoAndArt];
    });
    
    [self updateScreenWithInfoForNewSong: nowPlaying];
}

- (void)dealloc
{
    [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:timeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Obtaining a link for a given 

#pragma mark - Setup Floating ImgView
- (void)setUpFloatingImageViewAndPlayer
{
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    
    if(playerView == nil){
        playerView = [[PlayerView alloc] init];
        player = [[MyAVPlayer alloc] init];
        [playerView setPlayer:player];  //attaches AVPlayer to AVPlayerLayer
        playerView.frame = CGRectInset(appWindow.bounds, 20, 20);
        [MusicPlaybackController setRawAVPlayer:player];
        [MusicPlaybackController setRawPlayerView:playerView];
    } else
        return;  //this case should never happen
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        //entering view controller in landscape, show fullscreen video
        CGRect screenRect = [appWindow bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        //+1 is because the view ALMOST covered the full screen.
        [playerView setFrame:CGRectMake(0, 0, ceil(screenHeight +1), screenWidth)];
        //hide status bar
        toOrienation = orientation;  //value used in prefersStatusBarHidden
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    else
    {
        //show portrait player
        float widthOfScreenRoationIndependant;
        float heightOfScreenRotationIndependant;
        float  a = [appWindow bounds].size.height;
        float b = [appWindow bounds].size.width;
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
        float videoFrameHeight = [SongPlayerViewDisplayHelper videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
        float playerFrameYTempalue = roundf(((heightOfScreenRotationIndependant / 2.0) /1.5));
        int playerYValue = nearestEvenInt((int)playerFrameYTempalue);
        [playerView setFrame:CGRectMake(0, playerYValue, self.view.frame.size.width, videoFrameHeight)];
        [playerView setBackgroundColor:[UIColor blackColor]];
    }

    [appWindow addSubview:playerView];
}

#pragma mark - Check and update GUI based on device orientation (and respond to events)
//new song played from queue
- (void)newSongIsAboutToStartPlaying:(NSNotification *)object
{
    //Song *songAboutToPlay = (Song *)object;
    
    #warning need to update GUI text and info displayed to user
}

- (void)lastSongHasFinishedPlayback:(NSNotification *)object
{
#warning desired for behavior after queue finishes playing goes here
}

- (void)checkDeviceOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self.navigationController setNavigationBarHidden:NO];
}

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        [playerView setFrame:CGRectMake(0, 0, ceil(screenHeight +1), screenWidth)];  //+1 is because the view ALMOST covered the full screen.
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
        float videoFrameHeight = [SongPlayerViewDisplayHelper videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
        float playerFrameYTempValue = roundf(((heightOfScreenRotationIndependant / 2.0) /1.5));
        int playerYValue = nearestEvenInt((int)playerFrameYTempValue);
        [playerView setFrame:CGRectMake(0,   playerYValue,
                                             widthOfScreenRoationIndependant,
                                             videoFrameHeight)];
    }
    
    toOrienation = toInterfaceOrientation;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {  //selector works on iOS7+
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

#pragma mark - Initiating Playback
- (void)setupKeyValueObservers
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
    

    playingBack = NO;
    [MusicPlaybackController resumePlayback];  //starts playback
    
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, 100) queue:nil usingBlock:^(CMTime time) {
        //code will be called each 1/10th second....  NSLog(@"Playback time %.5f", CMTimeGetSeconds(time));
        [self updatePlaybackTimeSlider];
    }];
}

#pragma mark - Responding to Player Playback Events (rate, internet connection, etc.)
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
        
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        if ([networkReachability currentReachabilityStatus] == NotReachable)
            internetConnectionPresent = NO;
        else
            internetConnectionPresent = YES;
        
        if(rate != 0 && mostRecentLoadedDuration != 0 &&internetConnectionPresent){  //playing
            playingBack = YES;
            NSLog(@"Playing");
            
        } else if(rate == 0 && !videoCompletelyBuffered &&!internetConnectionPresent){  //stopped
            //Playback has stopped due to an internet connection issue.
            
            playingBack = NO;
            NSLog(@"Video stopped, no connection.");
            
        }else{  //paused
            playingBack = NO;
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
                    NSLog(@"Min buffer reached, ready to continue playing.");
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
            if(!playingBack && ![MusicPlaybackController playbackExplicitlyPaused]){
                [MusicPlaybackController resumePlayback];
            }
        }
    }
}

- (IBAction)playbackSliderEditingHasBegun:(id)sender
{
    // Add code here to do background processing
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(player.rate == 0)
        playAfterMovingSlider = NO;
    [player pause];
    sliderIsBeingTouched = YES;
}

- (IBAction)playbackSliderValueHasChanged:(id)sender
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Add code here to do background processing
        CMTime newTime = CMTimeMakeWithSeconds(_playbackTimeSlider.value, 1);
        [(MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer] seekToTime:newTime];
    });
}

- (IBAction)playbackSliderEditingHasEnded:(id)sender
{
    // Add code here to do background processing
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
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
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

#pragma mark - Responding to Button Events
//BACK BUTTON
- (void)backwardsButtonTappedOnce
{
    //code to rewind to previous song
    
    [self backwardsButtonLetGo];
}

- (void)backwardsButtonBeingHeld{ [self addShadowToButton:backwardButton]; }

- (void)backwardsButtonLetGo{ [self removeShadowForButton:backwardButton]; }

//PLAY BUTTON
- (void)playOrPauseButtonTapped
{
    UIColor *color = [UIColor blackColor];
    UIImage *tempImage;
    if(playingBack)
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
    
    [self forwardsButtonLetGo];
}

- (void)forwardsButtonBeingHeld{ [self addShadowToButton:forwardButton]; }

- (void)forwardsButtonLetGo{ [self removeShadowForButton:forwardButton]; }

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

- (IBAction)minimizePlayerButtonTapped:(id)sender
{
#warning complex code to minimize the VC but keep it visible on screen will go here probably.
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Presenting Song Information On Screen
- (void)updateScreenWithInfoForNewSong:(Song *)mySong
{
    /*
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

#pragma mark - Lock Screen Song Info & Art
- (void)setUpLockScreenInfoAndArt
{
    Song *nowPlayingSong = [MusicPlaybackController nowPlayingSong];
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
        [self minimizePlayerButtonTapped:nil];
}


@end
