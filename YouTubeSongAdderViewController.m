//
//  YouTubeSongAdderViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "YouTubeSongAdderViewController.h"
#import "YouTubeVideoSearchService.h"
#import "SDCAlertController.h"
#import "SSBouncyButton.h"

@interface YouTubeSongAdderViewController ()
{
    YouTubeVideo *ytVideo;
    UIImage *lockScreenImg;
    UIView *placeHolderView;
    BOOL enoughSongInformationGiven;
    BOOL userCreatedHisSong;
    BOOL preDeallocedAlready;
    
    BOOL didPresentVc;
    
    //fixes bug where player is invisible in view if it was added while the user was doing something else
    //(changing song name, etc)
    BOOL addPlayerToViewUponVcAppearance;
    
    NSDictionary *videoDetails;
    
    BOOL previewPlaybackBegan;
    BOOL previewIsUnplayable;
    
    BOOL leftAppDuePoweredByYtLogoClick;
    
    BOOL musicWasPlayingBeforePreviewBegan;
    __block NSURL *url;
}

@property (nonatomic, strong) SSBouncyButton *poweredByYtBtn;
@property (nonatomic, strong) MZPreviewPlayer *player;
@property (nonatomic, strong) MZSongModifierTableView *tableView;
@end

@implementation YouTubeSongAdderViewController
#pragma mark - Custom Initializer
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject thumbnail:(UIImage *)img
{
    if (self = [super init]) {
        if(youtubeVideoObject == nil)
            return nil;
    
        ytVideo = youtubeVideoObject;
        
        //fire off network request for video duration ASAP
        [[YouTubeVideoSearchService sharedInstance] setVideoDetailLookupDelegate:self];
        [[YouTubeVideoSearchService sharedInstance] fetchDetailsForVideo:ytVideo];
        
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
    if(! preDeallocedAlready)
        [self preDealloc];
    self.player = nil;
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([YouTubeSongAdderViewController class]));
}

- (void)preDealloc
{
    if(preDeallocedAlready)
        return;
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.previewPlayer = nil;
    
    [self.player destroyPlayer];
    preDeallocedAlready = YES;
    
    //VC is actually being popped. Must delete the song the user somewhat created
    if(!userCreatedHisSong)
        [self.tableView cancelEditing];
    
    [self.tableView preDealloc];
    self.tableView = nil;
    lockScreenImg = nil;
    url = nil;
    [AppEnvironmentConstants setUserIsPreviewingAVideo:NO];
    
    [[YouTubeVideoSearchService sharedInstance] removeVideoDetailLookupDelegate];
    if(musicWasPlayingBeforePreviewBegan){
        [MusicPlaybackController resumePlayback];
        [MusicPlaybackController explicitlyPausePlayback:NO];
    }
    [[SongPlayerCoordinator sharedInstance] enablePlayerAgain];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appReturningToForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

static short numberTimesViewHasBeenShown = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView viewWillAppear:animated];
    
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
    
    if(numberTimesViewHasBeenShown == 0){
        //makes the tableview start below the nav bar, not behind it.
        [self setViewFrameBasedOnOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
    numberTimesViewHasBeenShown++;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    if(addPlayerToViewUponVcAppearance){
        [self setUpVideoViewAndOrPlayerAboutToRotate:NO];
        addPlayerToViewUponVcAppearance = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    didPresentVc = NO;
    [super viewDidAppear:animated];
    [self.tableView viewDidAppear:animated];
    if(self.player){
        if(! self.player.playbackExplicitlyPaused){
            //if player was playing and we just returned to this VC, pause and play again.
            //this fixes a bug where cancelling a "slide to pop" gesture would make the player appear "stuck".
            [self.player pause];
            [self.player play];
        }
    }
    
    [self showOrUpdatePoweredByYtLogoGivenScreenWidth:self.view.frame.size.width];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(! didPresentVc){
        [self navBarBackButtonTapped];
        [self.navigationController popViewControllerAnimated:NO];
    }
    [super viewDidDisappear:animated];
}

- (void)navBarBackButtonTapped
{
    [self preDealloc];
}

#pragma mark - Loading video
- (void)loadVideo
{
    NSNumber *durationObj = [videoDetails valueForKey:MZKeyVideoDuration];
    NSUInteger duration = [durationObj integerValue];
    __weak YouTubeVideo *weakVideo = ytVideo;
    __weak YouTubeSongAdderViewController *weakSelf = self;
    __weak SongPlayerCoordinator *weakAvplayerCoordinator = [SongPlayerCoordinator sharedInstance];
    
    BOOL allowedToPlayVideo = YES;
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    
    if(duration >= MZLongestCellularPlayableDuration){
        //videos of this length may only be played on wifi. Are we on wifi?
        if(! [reachability isConnectedToWifi])
            allowedToPlayVideo = NO;
    }
    
    //connection problems should take presedence first over the allowedToPlay code further down...
    if([reachability isConnectionCompletelyGone]){
        [self videoPreviewCannotBeShownNoYoutubeConnection];
        previewIsUnplayable = YES;
        return;
    }

    if(! allowedToPlayVideo){
        [self videoPreviewCannotBeShownDurationTooLong];
        previewIsUnplayable = YES;
        return;
    }
    
    BOOL usingWifi = [[ReachabilitySingleton sharedInstance] isConnectedToWifi];
    
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
            [weakSelf videoPreviewCannotBeShownNoYoutubeConnection];
            [MRProgressOverlayView dismissAllOverlaysForView:weakSelf.tableView.tableHeaderView
                                                    animated:YES];
            return;
        }
        
        if(allowedToPlayVideo && video != nil){
            [weakSelf setUpVideoViewAndOrPlayerAboutToRotate:NO];
            [weakAvplayerCoordinator temporarilyDisablePlayer];
        }
    }];
}

#pragma mark - Video Player problems encountered code
- (void)videoPreviewCannotBeShownDurationTooLong
{
    previewIsUnplayable = YES;
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView
                                            animated:YES];
    NSString *headerText = @"This video too long to preview on a cellular connection.";
    UILabel *label = [self createLabelForPlacementOnTableHeaderWithText:headerText];
    [self.tableView.tableHeaderView addSubview:label];
    [self.tableView.tableHeaderView bringSubviewToFront:label];
    [UIView animateWithDuration:2
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.tableView.tableHeaderView.backgroundColor = [UIColor darkGrayColor];
                         label.alpha = 1;
                     }
                     completion:nil];
}

- (void)videoPreviewCannotBeShownNoYoutubeConnection
{
    previewIsUnplayable = YES;
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView
                                            animated:YES];
    NSString *headerText = @"Could not connect to YouTube.";
    UILabel *label = [self createLabelForPlacementOnTableHeaderWithText:headerText];
    [self.tableView.tableHeaderView addSubview:label];
    [self.tableView.tableHeaderView bringSubviewToFront:label];
    [UIView animateWithDuration:2
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.tableView.tableHeaderView.backgroundColor = [UIColor darkGrayColor];
                         label.alpha = 1;
                     }
                     completion:nil];
}

- (UILabel *)createLabelForPlacementOnTableHeaderWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                 size:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    label.numberOfLines = 4;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin   |
                              UIViewAutoresizingFlexibleRightMargin  |
                              UIViewAutoresizingFlexibleTopMargin    |
                              UIViewAutoresizingFlexibleBottomMargin);
    CGRect headerRect = self.tableView.tableHeaderView.frame;
    label.frame = CGRectMake(0, 0, headerRect.size.width * 0.85, headerRect.size.height * 0.85);
    [label sizeToFit];
    label.center = self.tableView.tableHeaderView.center;
    label.textColor = [UIColor whiteColor];
    label.alpha = 0;
    return label;
}

#pragma mark - Video frame and player setup
- (void)setUpVideoViewAndOrPlayerAboutToRotate:(BOOL)goingToRotate
{
    if([[UIApplication sharedApplication].keyWindow visibleViewController] != self){
        addPlayerToViewUponVcAppearance = YES;
        
        if(self.player == nil && !preDeallocedAlready){
            // player's frame size must match parent's
            self.player = [[MZPreviewPlayer alloc] initWithFrame:CGRectZero
                                                        videoURL:url];
            [self.player setStallValueChangedDelegate:self];
            [self.player play];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MZInitAudioSession
                                                                object:nil];
        }
        
        return;
    }
    int widthOfScreenRoationIndependant;
    int heightOfScreenRotationIndependant;
    int  a = [[UIScreen mainScreen] bounds].size.height;
    int b = [[UIScreen mainScreen] bounds].size.width;
    if(goingToRotate){
        //swap the values since after rotation they will be inverted.
        int temp = a;
        a = b;
        b = temp;
    }
    
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
    BOOL isLandscape;
    if(goingToRotate){
        isLandscape = (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown);
    } else{
        isLandscape = (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft);
    }
    if(isLandscape){
        frameWidth = heightOfScreenRotationIndependant;
        frameHeight = widthOfScreenRoationIndependant * (5/6.0);
    } else{
        frameWidth = widthOfScreenRoationIndependant;
        frameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:frameWidth];
    }
    
    CGRect viewFrame = self.view.frame;
    if(previewIsUnplayable){
        placeHolderView.frame = CGRectMake(0, 0, viewFrame.size.width, frameHeight);
        return;
    }
    
    UIView *rootHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, frameHeight)];
    UIView *videoFrameView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, frameHeight)];
    [videoFrameView setBackgroundColor:[UIColor blackColor]];
    self.tableView.tableHeaderView = rootHeaderView;

    if(self.player == nil && !preDeallocedAlready){
                                                // player's frame size must match parent's
        self.player = [[MZPreviewPlayer alloc] initWithFrame:videoFrameView.frame
                                                    videoURL:url];
        [self.player setStallValueChangedDelegate:self];
        [self.player play];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MZInitAudioSession
                                                            object:nil];
    } else{
        self.player.frame = videoFrameView.frame;
    }
    
    if(! preDeallocedAlready){
        [rootHeaderView addSubview:videoFrameView];
        [videoFrameView addSubview: self.player];
        [videoFrameView bringSubviewToFront:self.player];
    }

    
    if(self.player.isInStall)
        [MRProgressOverlayView showOverlayAddedTo:self.tableView.tableHeaderView
                                            title:@"Loading Preview"
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
    placeHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, offset, frameWidth, frameHeight)];
    [placeHolderView setBackgroundColor:[UIColor colorWithPatternImage:
                                         [UIImage imageWithColor:[UIColor clearColor] width:placeHolderView.frame.size.width height:placeHolderView.frame.size.height]]];
    self.tableView.tableHeaderView = placeHolderView;
    
    [MRProgressOverlayView showOverlayAddedTo:self.tableView.tableHeaderView
                                        title:@"Loading preview"
                                         mode:MRProgressOverlayViewModeIndeterminateSmall
                                     animated:YES];
}

#pragma mark - Handling all background interaction (playback, lockscreen, etc)
- (void)setUpLockScreenInfoAndArt
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZStartBackgroundTaskHandlerIfInactive
                                                        object:nil];
    
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter) {
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        UIImage *art = lockScreenImg;
        MPMediaItemArtwork *albumArt;
        if(art){
            albumArt = [[MPMediaItemArtwork alloc] initWithImage:art];
        }
        
        [songInfo setObject:ytVideo.videoName forKey:MPMediaItemPropertyTitle];
        if(ytVideo.channelTitle)
            [songInfo setObject:ytVideo.channelTitle forKey:MPMediaItemPropertyArtist];
        if(albumArt)
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        
        [songInfo setObject:[videoDetails valueForKey:MZKeyVideoDuration]
                     forKey:MPMediaItemPropertyPlaybackDuration];
        
        NSUInteger elapsedTime = [self.player elapsedTimeInSec];
        NSNumber *currentTime = [NSNumber numberWithInteger:elapsedTime];
        [songInfo setObject:currentTime forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [songInfo setObject:[NSNumber numberWithFloat:self.player.avPlayer.rate]
                     forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
}

- (void)lockscreenPlayTapped
{
    [self.player play];
    [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
}

- (void)lockscreenPauseTapped
{
    [self.player pause];
    [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
}

- (void)lockscreenTogglePlayPause
{
    //possibly useful
    if(self.player.isPlaying){
        [self.player pause];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
    } else{
        [self.player play];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
    }
}


#pragma mark - Share Button Tapped
- (void)shareButtonTapped
{
    didPresentVc = YES;
    YouTubeVideo *currentVideo = ytVideo;
    if(currentVideo){
        NSString *youtubeLinkBeginning = @"www.youtube.com/watch?v=";
        NSMutableString *shareString = [NSMutableString stringWithString:@"\n"];
        [shareString appendString:youtubeLinkBeginning];
        [shareString appendString:currentVideo.videoId];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, nil];
        
        //temporarily changing app default colors for the activityviewcontroller.
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.window.tintColor = [UIColor defaultAppColorScheme];
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor defaultAppColorScheme], NSForegroundColorAttributeName, nil]];
        
        __block UIActivityViewController *activityVC = [[UIActivityViewController alloc]
                                                        initWithActivityItems:activityItems
                                                        applicationActivities:nil];
        __weak UIActivityViewController *weakActivityVC = activityVC;
        __weak YouTubeSongAdderViewController *weakSelf = self;
        
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop];
        //set tint color specifically for this VC so that the text and buttons are visible
        [activityVC.view setTintColor:[UIColor defaultAppColorScheme]];
        
        [activityVC setCompletionHandler:^(NSString *activityType, BOOL completed) {
            //finish your code when the user finish or dismiss...
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                //restoring default button and title font colors in the app.
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.window.tintColor = [UIColor defaultWindowTintColor];
                [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor defaultWindowTintColor], NSForegroundColorAttributeName, nil]];
                [weakSelf.navigationController.navigationBar setTitleTextAttributes:
                 @{NSForegroundColorAttributeName:[UIColor defaultWindowTintColor]}];
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
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_TroubleSharingVideo];
    }
}

#pragma mark - Rotation Stuff

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView interfaceIsAboutToRotate];
    [self setUpVideoViewAndOrPlayerAboutToRotate:YES];
    
    if(previewIsUnplayable)
        return;
    [self performSelector:@selector(reCenterLoadingSpinner) withObject:nil afterDelay:0.2];
    [self showOrUpdatePoweredByYtLogoGivenScreenWidth:self.tableView.frame.size.height];
}

- (void)reCenterLoadingSpinner
{
    [[MRProgressOverlayView overlayForView:self.tableView.tableHeaderView] manualLayoutSubviews];
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
                NSString *msg = @"Unfortunately, this App only supports videos with a total duration of 24 hours or less.";

                __weak YouTubeSongAdderViewController *weakself = self;
                SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK" style:SDCAlertActionStyleRecommended handler:^(SDCAlertAction *action) {
                    [weakself.navigationController popToRootViewControllerAnimated:YES];
                }];
                
                [self launchAlertViewWithDialogTitle:@"Video Duration Exceeded"
                                          andMessage:msg
                                        customAction:okAction];
                
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
        __weak YouTubeSongAdderViewController *weakself = self;
        SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                             style:SDCAlertActionStyleRecommended
                                                           handler:^(SDCAlertAction *action) {
                                                               [weakself.navigationController popToRootViewControllerAnimated:YES];
                                                           }];
        NSString *msg = @"This video can't be saved. Something went wrong fetching the video information.";
        [self launchAlertViewWithDialogTitle:@"Lacking Info"
                                  andMessage:msg
                                customAction:okAction];
        [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
    }else
        //false alarm about a problem that occured with a previous fetch?
        //who knows when this would happen lol. Disregard this case.
        return;
}

#pragma mark - Custom song tableview editor delegate stuff
- (void)pushThisVC:(UIViewController *)vc
{
    didPresentVc = YES;
    
    //using isKindOfClass because im not looking for an exact match! Just looking for
    //any descendant of these types.
    if([vc isKindOfClass:[UINavigationController class]])
        [self presentViewController:vc animated:YES completion:nil];
    else if([vc isKindOfClass:[UIViewController class]])
        [self.navigationController pushViewController:vc animated:YES];
    else
        didPresentVc = NO;
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

#pragma mark - Preview Player Delegate Implementation
- (void)previewPlayerStallStateChanged
{
    if(self.player.isInStall){
        [MRProgressOverlayView showOverlayAddedTo:self.tableView.tableHeaderView
                                            title:@""
                                             mode:MRProgressOverlayViewModeIndeterminateSmall
                                         animated:YES];
        [self setUpLockScreenInfoAndArt];
    }
    else{
        if(previewPlaybackBegan == NO){
            [AppEnvironmentConstants setUserIsPreviewingAVideo:YES];
            
            //first time we know that playback started, update album art now.
            [self setUpLockScreenInfoAndArt];
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            appDelegate.previewPlayer = self.player;
        }
        previewPlaybackBegan = YES;
        [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
        
        musicWasPlayingBeforePreviewBegan = ([MusicPlaybackController obtainRawAVPlayer].rate > 0);
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [MusicPlaybackController pausePlayback];
    }
}

- (void)previewPlayerNeedsNowPlayingInfoCenterUpdate
{
    [self setUpLockScreenInfoAndArt];
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialogTitle:(NSString *)title
                            andMessage:(NSString *)message
                          customAction:(SDCAlertAction *)customAction;
{
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                         style:SDCAlertActionStyleRecommended
                                                       handler:nil];
    if(customAction)
        [alert addAction:customAction];
    else
        [alert addAction:okAction];
    [alert presentWithCompletion:nil];
}

- (void)showOrUpdatePoweredByYtLogoGivenScreenWidth:(float)width
{
    BOOL animateOnScreen = NO;
    UIButton *btn = self.poweredByYtBtn;
    UIImage *logo = [UIImage imageNamed:@"poweredByYtDark"];
    if(btn == nil) {
        btn = [[SSBouncyButton alloc] initAsImage];
        [btn setImage:logo forState:UIControlStateNormal];
        animateOnScreen = YES;
    } else {
        self.tableView.tableFooterView = nil;
    }
    int yPadding = 20;
    btn.frame = CGRectMake(0, yPadding, logo.size.width, logo.size.height);
    [btn setImage:logo forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(poweredByYtTapped)
  forControlEvents:UIControlEventTouchUpInside];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(width/2 - (logo.size.width/2),
                                                                 0,
                                                                 logo.size.width,
                                                                 logo.size.height + yPadding)];
    [footerView addSubview:btn];
    footerView.alpha = 0;
    footerView.userInteractionEnabled = YES;
    [self.tableView setTableFooterView:footerView];
    if(animateOnScreen) {
        [UIView animateWithDuration:MZCellImageViewFadeDuration
                         animations:^{
                             footerView.alpha = 1;
                         }];
    }
}

static BOOL powerByYtHandled = NO;  //needed if user aggressively taps button more than once
- (void)poweredByYtTapped
{
    powerByYtHandled = NO;
    [self performSelector:@selector(handlePoweredByYtTapped) withObject:nil afterDelay:0.25];
}

- (void)handlePoweredByYtTapped
{
    if(powerByYtHandled)
        return;
    [self.player pause];
    
    NSString *youtubeLinkBeginning = @"https://www.youtube.com/watch?v=";
    NSMutableString *ytWebUrl = [NSMutableString stringWithString:youtubeLinkBeginning];
    [ytWebUrl appendString:ytVideo.videoId];
    
    NSURL *previewYtWebUrl = [NSURL URLWithString:ytWebUrl];
    leftAppDuePoweredByYtLogoClick = YES;
    if (![[UIApplication sharedApplication] openURL:previewYtWebUrl]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotOpenSafariError];
        leftAppDuePoweredByYtLogoClick = NO;
    }
}

- (void)appReturningToForeground
{
    if(leftAppDuePoweredByYtLogoClick) {
        [self.player performSelector:@selector(play) withObject:nil afterDelay:0.2];
    }
    leftAppDuePoweredByYtLogoClick = NO;
}

@end
