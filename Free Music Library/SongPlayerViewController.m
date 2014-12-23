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
}
@end

@implementation SongPlayerViewController
@synthesize navBar, playbackTimeSlider = _playbackTimeSlider, currentTimeLabel = _currentTimeLabel,
            totalDurationLabel = _totalDurationLabel;
static UIInterfaceOrientation toOrienation;  //used by "prefersStatusBarHidden" and other rotation code
static BOOL playAfterMovingSlider = YES;
static BOOL sliderIsBeingTouched = NO;
NSString * const NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
NSString * const AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";

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
    
    //hack for hiding back bttn text. (affects other back bttns if more VC's pushed)
    self.navigationController.navigationBar.topItem.title = @"";
}

static int numTimesVCLoaded = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Song *nowPlaying = [MusicPlaybackController nowPlayingSong];
    if(numTimesVCLoaded == 0){
        [self setUpFloatingImageViewAndPlayer];  //sets up the video GUI
        
        
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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

#pragma mark - Check and update GUI based on device orientation (or responding to events)
- (void)lastSongHasFinishedPlayback:(NSNotification *)object
{
#warning desired for behavior after queue finishes playing goes here
}

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

#pragma mark - Responding to Player Playback Events (rate, internet connection, etc.)
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
    if([MusicPlaybackController obtainRawAVPlayer].rate == 1)  //playing back
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
    [[SongPlayerCoordinator sharedInstance] beginShrinkingVideoPlayer];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
