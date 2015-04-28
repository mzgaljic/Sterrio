//
//  YouTubeSongAdderViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "YouTubeSongAdderViewController.h"
#import "YouTubeVideoSearchService.h"


@interface YouTubeSongAdderViewController ()
{
    YouTubeVideo *ytVideo;
    MPMoviePlayerController *videoPlayerViewController;
    UIImage *lockScreenImg;
    BOOL enoughSongInformationGiven;
    BOOL doneTappedInVideo;
    BOOL pausedBeforePopAttempt;
    BOOL userCreatedHisSong;
    BOOL dontPreDealloc;
    BOOL playbackBegan;
    NSDictionary *videoDetails;
    
    BOOL currentlySeeking;
    
    NSTimer *timer;  //used to check if the video started playing (spinner, etc)
    
    BOOL musicWasPlayingBeforePreviewBegan;
    BOOL prevMusicPlaybackStateAlreadySaved;
    __block NSURL *url;
}

@property (nonatomic, strong) MZSongModifierTableView *tableView;
@end

@implementation YouTubeSongAdderViewController
#pragma mark - Custom Initializer
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject thumbnail:(UIImage *)img
{
    if (self = [super init]) {
        if(youtubeVideoObject == nil)
            return nil;
        
        #warning WARNING, should post notification to init audio session after playback begins. Do after chaning preview player to AVPlayer.
        [[NSNotificationCenter defaultCenter] postNotificationName:MZInitAudioSession object:nil];

        
        
        ytVideo = youtubeVideoObject;
        
        //fire off network request for video duration ASAP
        [[YouTubeVideoSearchService sharedInstance] setVideoDetailLookupDelegate:self];
        [[YouTubeVideoSearchService sharedInstance] fetchDetailsForVideo:ytVideo];
        
        pausedBeforePopAttempt = YES;
        MZSongModifierTableView *songEditTable;
        lockScreenImg = img;
        songEditTable = [[MZSongModifierTableView alloc] initWithFrame:self.view.frame
                                                                 style:UITableViewStyleGrouped];
        songEditTable.VC = self;
        self.tableView = songEditTable;
        self.tableView.theDelegate = self;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                            UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:self.tableView];
        [self.tableView initWasCalled];
    
        NSString *playbackStateChangedConst = MPMoviePlayerPlaybackStateDidChangeNotification;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerPlaybackStateChanged:)
                                                     name:playbackStateChangedConst
                                                   object:nil];
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(hasPlaybackStartedTimerCheck)
                                       userInfo:nil
                                        repeats:YES];
        //provide default album art (making deep copy of album art)
        [self.tableView provideDefaultAlbumArt:lockScreenImg];
    }
    return self;
}

#pragma mark - VC life cycle
- (void)dealloc
{
    numberTimesViewHasBeenShown = 0;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(videoPlayerViewController){
        [videoPlayerViewController stop];
        videoPlayerViewController = nil;
    }
    [[YouTubeVideoSearchService sharedInstance] removeVideoDetailLookupDelegate];
    if(musicWasPlayingBeforePreviewBegan){
        [MusicPlaybackController resumePlayback];
        [MusicPlaybackController explicitlyPausePlayback:NO];
    }
    [[SongPlayerCoordinator sharedInstance] enablePlayerAgain];
    
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([YouTubeSongAdderViewController class]));
}

- (void)preDealloc
{
    if(dontPreDealloc)
        return;
    //VC is actually being popped. Must delete the song the user somewhat created
    if(!userCreatedHisSong)
        [self.tableView cancelEditing];
    [self.tableView preDealloc];
    self.tableView = nil;
    lockScreenImg = nil;
    url = nil;
    [timer invalidate];
    timer = nil;
    [AppEnvironmentConstants setUserIsPreviewingAVideo:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppMovingToBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppMovingToBackground)
                                                 name:MZAppWasBackgrounded
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationHasChanged)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockscreenPauseTapped)
                                                 name:MZPreviewPlayerPause
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockscreenPlayTapped)
                                                 name:MZPreviewPlayerPlay
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockscreenTogglePlayPause)
                                                 name:MZPreviewPlayerTogglePlayPause
                                               object:nil];
}

static short numberTimesViewHasBeenShown = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView viewWillAppear:animated];
    dontPreDealloc = NO;
    
    //hack to hide back button text.
    self.navigationController.navigationBar.topItem.title = @"";
    self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                          target:self
                                                          action:@selector(shareButtonTapped)];
    
    self.navigationController.toolbarHidden = YES;
    
    //set nav bar title
    if(numberTimesViewHasBeenShown == 0){
        self.navigationItem.title = ytVideo.videoName;
    } else{
        CATransition *fade = [CATransition animation];
        fade.type = kCATransitionFade;
        fade.duration = 1.0;
        [self.navigationController.navigationBar.layer addAnimation: fade forKey: @"fadeText"];
        self.navigationItem.title = ytVideo.videoName;
    }
    
    if(numberTimesViewHasBeenShown == 0)
        [self setPlaceHolderImageForVideoPlayer];  //would do this in viewDidLoad but self.view.frame has incorrect values until viewWillAppear
    
    if(videoPlayerViewController){
        [self setUpVideoView];
        //this sequence avoids a bug when user cancels "swipe to pop" gesture
        if(pausedBeforePopAttempt){
            [videoPlayerViewController pause];
        }
        [self checkCurrentPlaybackState];
    }
    if(numberTimesViewHasBeenShown == 0){
        //makes the tableview start below the nav bar, not behind it.
        [self setViewFrameBasedOnOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
    numberTimesViewHasBeenShown++;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView viewDidAppear:animated];
    playerStateBeforeEnteringBackground = videoPlayerViewController.playbackState;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self checkCurrentPlaybackState];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    BOOL newVcHasBeenPushed = ![self isMovingFromParentViewController];
    if(newVcHasBeenPushed)
        return;
    else
        if(! dontPreDealloc)
            [self preDealloc];
}

- (void)checkCurrentPlaybackState
{
    if(videoPlayerViewController){
        if(videoPlayerViewController.playbackState == MPMoviePlaybackStatePaused)
            pausedBeforePopAttempt = YES;
        else if(videoPlayerViewController.playbackState == MPMoviePlaybackStatePlaying)
            pausedBeforePopAttempt = NO;
        else
            pausedBeforePopAttempt = YES;
    }
}

#pragma mark - Loading video
- (void)loadVideo
{
    videoPlayerViewController = [[MPMoviePlayerController alloc] init];
    
    __weak NSNumber *weakDuration = [videoDetails valueForKey:MZKeyVideoDuration];
    __weak YouTubeVideo *weakVideo = ytVideo;
    __weak YouTubeSongAdderViewController *weakSelf = self;
    __weak __block MPMoviePlayerController *weakVideoPlayerViewController = videoPlayerViewController;
    __weak SongPlayerCoordinator *weakAvplayerCoordinator = [SongPlayerCoordinator sharedInstance];
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    BOOL usingWifi = NO;
    //not checking if we can physically play, but legally (Apple's 10 minute streaming rule)
    BOOL allowedToPlayVideo = YES;
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == ReachableViaWiFi)
        usingWifi = YES;
    
    if(! usingWifi && status != NotReachable){
        if([weakDuration integerValue] >= MZLongestCellularPlayableDuration)
            //user cant watch video longer than 10 minutes without wifi
            allowedToPlayVideo = NO;
    } else if(! usingWifi && status == NotReachable){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        [MRProgressOverlayView dismissAllOverlaysForView:weakSelf.tableView.tableHeaderView
                                                animated:YES];
    }
    if(! allowedToPlayVideo){
        if(status != NotReachable){
            [self videoPreviewCannotBeShownDurationTooLong];
        }
        else{
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
            [MRProgressOverlayView dismissAllOverlaysForView:weakSelf.tableView.tableHeaderView
                                                    animated:YES];
        }
        return;
    }
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakVideo.videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if(video){
            //find video quality closest to setting preferences
            NSDictionary *vidQualityDict = video.streamURLs;
            if(usingWifi){
                short maxDesiredQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
                url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
            }else{
                short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
            }
        }else{
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
            [MRProgressOverlayView dismissAllOverlaysForView:weakSelf.tableView.tableHeaderView
                                                    animated:YES];
            return;
        }
        
        if(allowedToPlayVideo && video != nil){
            [weakVideoPlayerViewController setRepeatMode:(MPMovieRepeatModeNone)];
            [weakVideoPlayerViewController setControlStyle:MPMovieControlStyleEmbedded];
            [weakVideoPlayerViewController setScalingMode:MPMovieScalingModeAspectFit];
            [weakVideoPlayerViewController setMovieSourceType:(MPMovieSourceTypeStreaming)];
            [weakVideoPlayerViewController setContentURL:url];
            [weakVideoPlayerViewController prepareToPlay];
            [weakSelf setUpVideoView];
            [weakVideoPlayerViewController play];
            [weakAvplayerCoordinator temporarilyDisablePlayer];
        }
    }];
}

#pragma mark - Video Player problems encountered code
- (void)videoPreviewCannotBeShownDurationTooLong
{
    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongPreviewVideoSkippedOnCellular];
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView
                                            animated:YES];
    self.tableView.tableHeaderView.backgroundColor = [UIColor grayColor];
}

#pragma mark - Video frame and player setup
- (void)setUpVideoView
{
    int widthOfScreenRoationIndependant;
    int heightOfScreenRotationIndependant;
    int  a = [[UIScreen mainScreen] bounds].size.height;
    int b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b){
        widthOfScreenRoationIndependant = a;
        heightOfScreenRotationIndependant = b;
    }else{
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    int frameHeight;
    int frameWidth;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        frameWidth = heightOfScreenRotationIndependant;
        frameHeight = widthOfScreenRoationIndependant * (2/3.0);
    } else{
        frameWidth = widthOfScreenRoationIndependant;
        frameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:frameWidth];
    }
    
    CGRect viewFrame = self.view.frame;
    UIView *rootHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, frameHeight)];
    UIView *videoFrameView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, frameHeight)];
    [videoFrameView setBackgroundColor:[UIColor blackColor]];
    self.tableView.tableHeaderView = rootHeaderView;

    [[videoPlayerViewController view] setFrame:videoFrameView.frame]; // player's frame size must match parent's
    [rootHeaderView addSubview:videoFrameView];
    [videoFrameView addSubview: [videoPlayerViewController view]];
    [videoFrameView bringSubviewToFront:[videoPlayerViewController view]];
    
    if(! playbackBegan)
        [MRProgressOverlayView showOverlayAddedTo:self.tableView.tableHeaderView
                                            title:@"Loading preview"
                                             mode:MRProgressOverlayViewModeIndeterminateSmall
                                         animated:YES];
}

- (void)setPlaceHolderImageForVideoPlayer
{
    int widthOfScreenRoationIndependant;
    int heightOfScreenRotationIndependant;
    int  a = [[UIScreen mainScreen] bounds].size.height;
    int b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b){
        widthOfScreenRoationIndependant = a;
        heightOfScreenRotationIndependant = b;
    }else{
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    int frameHeight;
    int frameWidth;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        frameWidth = heightOfScreenRotationIndependant * (2/3.0);
        frameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:frameWidth];
    } else{
        frameWidth = widthOfScreenRoationIndependant;
        frameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:frameWidth];
    }
    
    int offset = [AppEnvironmentConstants statusBarHeight]+[AppEnvironmentConstants navBarHeight];
    UIView *placeHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, offset, frameWidth, frameHeight)];
    [placeHolderView setBackgroundColor:[UIColor colorWithPatternImage:
                                         [UIImage imageWithColor:[UIColor clearColor] width:placeHolderView.frame.size.width height:placeHolderView.frame.size.height]]];
    self.tableView.tableHeaderView = placeHolderView;
    
    [MRProgressOverlayView showOverlayAddedTo:self.tableView.tableHeaderView
                                        title:@"Loading preview"
                                         mode:MRProgressOverlayViewModeIndeterminateSmall
                                     animated:YES];
}

#pragma mark - Responding to video player events
- (void)hasPlaybackStartedTimerCheck
{
    //this is called by the timer and done here because if the app goes into the foreground
    //while the video is loading, the spinner will never go away! This could have easily been
    //reproduced by simply opening control center
    if(playbackBegan){
        [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView
                                                animated:YES];
        [self setUpLockScreenInfoAndArt];
        [timer invalidate];
    }
}

- (void)playerPlaybackStateChanged:(NSNotification *)notif
{
    if(videoPlayerViewController.playbackState == MPMoviePlaybackStatePlaying && [AppEnvironmentConstants currrentPreviewPlayerState] != PREVIEW_PLAYBACK_STATE_Paused){
        [AppEnvironmentConstants setUserIsPreviewingAVideo:YES];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
        playbackBegan = YES;
        
        if(! prevMusicPlaybackStateAlreadySaved){
            AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
            if(player){
                if(player.rate == 1){
                    [player performSelector:@selector(pause) withObject:nil afterDelay:0.3];
                    [MusicPlaybackController pausePlayback];
                    [MusicPlaybackController explicitlyPausePlayback:YES];
                    musicWasPlayingBeforePreviewBegan = YES;
                }
                else
                    musicWasPlayingBeforePreviewBegan = NO;
                prevMusicPlaybackStateAlreadySaved = YES;
            }
        }
    } else if(videoPlayerViewController.playbackState == MPMoviePlaybackStatePaused){
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
    }
    if([AppEnvironmentConstants currrentPreviewPlayerState] != PREVIEW_PLAYBACK_STATE_Paused)
        [videoPlayerViewController pause];
    
    if(videoPlayerViewController.playbackState == MPMoviePlaybackStateSeekingForward ||
       videoPlayerViewController.playbackState == MPMoviePlaybackStateSeekingBackward)
        currentlySeeking = YES;
    else if(lockScreenImg != nil)
        [self setUpLockScreenInfoAndArt];
}

#pragma mark - Handling all background interaction (playback, lockscreen, etc)
static MPMoviePlaybackState playerStateBeforeEnteringBackground;
- (void)handleAppMovingToBackground
{
    if(playerStateBeforeEnteringBackground == MPMoviePlaybackStatePlaying){
        [self performSelector:@selector(forcePlayOfVideoInBackground)
                   withObject:nil
                   afterDelay:0.15];
    }
    playerStateBeforeEnteringBackground = videoPlayerViewController.playbackState;
}

- (void)forcePlayOfVideoInBackground
{
    if(playerStateBeforeEnteringBackground == MPMoviePlaybackStatePaused)
        return;
    [videoPlayerViewController play];
}

- (void)setUpLockScreenInfoAndArt
{
    //lockScreenImg
    // do something with image
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter) {
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        UIImage *art = lockScreenImg;
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:art];
        
        [songInfo setObject:ytVideo.videoName forKey:MPMediaItemPropertyTitle];
        if(ytVideo.channelTitle)
            [songInfo setObject:ytVideo.channelTitle forKey:MPMediaItemPropertyArtist];
        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        NSInteger duration = [[videoDetails valueForKey:MZKeyVideoDuration] integerValue];
        [songInfo setObject:[NSNumber numberWithInteger:duration]
                     forKey:MPMediaItemPropertyPlaybackDuration];
        
        NSNumber *currentTime = [NSNumber numberWithDouble:[videoPlayerViewController currentPlaybackTime]];
        [songInfo setObject:currentTime forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
}

- (void)lockscreenPlayTapped
{
    [videoPlayerViewController play];
    [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
}

- (void)lockscreenPauseTapped
{
    [videoPlayerViewController pause];
    [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
}

- (void)lockscreenTogglePlayPause
{
    if(videoPlayerViewController.playbackState == MPMoviePlaybackStatePlaying){
        [videoPlayerViewController pause];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
    } else if(videoPlayerViewController.playbackState == MPMoviePlaybackStatePaused){
        [videoPlayerViewController play];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
    } else
        return;
}


#pragma mark - Share Button Tapped
- (void)shareButtonTapped
{
    YouTubeVideo *currentVideo = ytVideo;
    if(currentVideo){
        NSString *youtubeLinkBeginning = @"www.youtube.com/watch?v=";
        NSMutableString *shareString = [NSMutableString stringWithString:@"\n"];
        [shareString appendString:youtubeLinkBeginning];
        [shareString appendString:currentVideo.videoId];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, nil];
        
        __block MZActivityViewController *activityVC = [[MZActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:nil];
        __weak MZActivityViewController *weakActivityVC = activityVC;
        
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop];
        //set tint color specifically for this VC so that the cancel buttons are visible
        [activityVC.view setTintColor:[[UIColor defaultAppColorScheme] lighterColor]];
        [self presentViewController:activityVC
                           animated:YES
                         completion:^{
                             //fixes memory leak
                             weakActivityVC.excludedActivityTypes = nil;
                             activityVC = nil;
                         }];
        
    } else{
        // Handle error
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_TroubleSharingVideo];
    }
}

#pragma mark - Rotation Stuff
- (void)orientationHasChanged
{
    [self setUpVideoView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView interfaceIsAboutToRotate];
}

- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else{
        return NO;
    }
}

- (void)setViewFrameBasedOnOrientation:(UIInterfaceOrientation)orientation
{
    //this method is called only once each time this view is instantiated. setting tableview
    //inset based on the orientation this viewcontroller was "opened" in.
    int navBarHeight = self.navigationController.navigationBar.frame.size.height;
    int offset;
    if(orientation == UIInterfaceOrientationLandscapeLeft ||
       orientation == UIInterfaceOrientationLandscapeRight){
        offset = navBarHeight;
        UIEdgeInsets inset = UIEdgeInsetsMake(offset, 0, 0, 0);
        self.tableView.contentInset = inset;
        self.tableView.scrollIndicatorInsets = inset;
        
        //for some reason in landscape the tableview is not scrolled to the top by default. doing this manually...
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    } else{
        offset = navBarHeight + [AppEnvironmentConstants statusBarHeight];
        UIEdgeInsets inset = UIEdgeInsetsMake(offset, 0, 0, 0);
        self.tableView.contentInset = inset;
        self.tableView.scrollIndicatorInsets = inset;
    }
}

#pragma mark - Managing video detail fetch response
- (void)detailsHaveBeenFetchedForYouTubeVideo:(YouTubeVideo *)video details:(NSDictionary *)details
{
    if([video.videoId isEqualToString:ytVideo.videoId]){
        if(details){
            NSNumber *duration = [details objectForKey:MZKeyVideoDuration];
            NSUInteger twenty_four_hours = 86400;
            if([duration integerValue] > twenty_four_hours){
                [self launchAlertViewWithDialogTitle:@"Video Duration Exceeded"
                                          andMessage:@"Unfortunately, this App only supports videos with a total duration of 24 hours or less."];
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else{
                videoDetails = [details copy];
                details = nil;
                [self.tableView canShowAddToLibraryButton];
                [self loadVideo];
            }
        }
    }else
        return;
}

- (void)networkErrorHasOccuredFetchingVideoDetailsForVideo:(YouTubeVideo *)video
{
    if([video.videoId isEqualToString:ytVideo.videoId]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_PotentialVideoDurationFetchFail];
        [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
    }else
        //false alarm about a problem that occured with a previous fetch?
        //who knows when this would happen lol. Disregard this case.
        return;
}

#pragma mark - Custom song tableview editor delegate stuff
- (void)pushThisVC:(UIViewController *)vc
{
    dontPreDealloc = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)performCleanupBeforeSongIsSaved:(Song *)newLibSong
{
    NSNumber *duration = [videoDetails valueForKey:MZKeyVideoDuration];
    newLibSong.duration = duration;
    newLibSong.youtube_id = ytVideo.videoId;
    userCreatedHisSong = YES;
    [self performSelector:@selector(destructThisVCDelayed) withObject:nil afterDelay:0.2];
    [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerCanIgnoreToolbar];
}

- (void)destructThisVCDelayed
{
    [self preDealloc];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if([MusicPlaybackController nowPlayingSong])
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
    }];
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialogTitle:(NSString *)title andMessage:(NSString *)message
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.buttonTextColor = [UIColor defaultAppColorScheme];
    [alert show];
}

@end
