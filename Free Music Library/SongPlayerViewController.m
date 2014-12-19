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
    PlayerView *playerView;
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
    
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    
    //begin loading player using video id
    
    [self updateScreenWithInfoForNewSong: nowPlaying];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(shareButtonTapped)];
    [self setupVideoPlayerViewDimensionsAndShowLoading];  //SET UP VIDEO PLAYER GUI HERE
    [self checkDeviceOrientation];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setUpLockScreenInfoAndArt];
    });
}

- (void)dealloc
{
    [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:timeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Check and update GUI based on device orientation (and respond to events)
//new song played from queue
- (void)newSongIsAboutToStartPlaying:(NSNotification *)object
{
    Song *songAboutToPlay = (Song *)object;
    
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


#pragma mark - GUI Initialization
//Setting up Video Player size and setting up spinner
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
        float playerFrameYTempalue = roundf(((heightOfScreenRotationIndependant / 2.0) /1.5));
        int playerYValue = nearestEvenInt((int)playerFrameYTempalue);
        [playerView setFrame:CGRectMake(0, playerYValue, self.view.frame.size.width, videoFrameHeight)];
        [playerView setBackgroundColor:[UIColor blackColor]];
    }
}


#pragma mark - Initiating Playback
- (void)playURL:(NSURL *)videoURL
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    
    if (!player) {
        player = [[MyAVPlayer alloc] initWithURL:videoURL];
        playerView = [[PlayerView alloc] init];
        [playerView setPlayer:player];  //attaches AVPlayer to AVPlayerLayer
        playerView.frame = CGRectInset(self.view.bounds, 20, 20);
        [self.view addSubview:playerView];
        
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
        
        [MusicPlaybackController setRawAVPlayer:player];
    }
    playingBack = NO;
    [MusicPlaybackController resumePlayback];  //starts playback
    
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, 600) queue:nil usingBlock:^(CMTime time) {
        //NSLog(@"Playback time %.5f", CMTimeGetSeconds(time));
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
        [self.navigationController popViewControllerAnimated:YES];
}


@end
