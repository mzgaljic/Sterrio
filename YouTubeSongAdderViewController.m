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
    BOOL enoughSongInformationGiven;
    BOOL doneTappedInVideo;
    BOOL pausedBeforePopAttempt;
    BOOL userCreatedHisSong;
    BOOL dontPreDealloc;
    BOOL playbackBegan;
    NSDictionary *videoDetails;
    
    BOOL musicWasPlayingBeforePreviewBegan;
    BOOL prevMusicPlaybackStateAlreadySaved;
}

@property (nonatomic, strong) MZSongModifierTableView *tableView;
@end

@implementation YouTubeSongAdderViewController
#pragma mark - Custom Initializer
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject
{
    if ([super init]) {
        if(youtubeVideoObject == nil)
            return nil;
        ytVideo = youtubeVideoObject;
        pausedBeforePopAttempt = YES;
        MZSongModifierTableView *songEditTable;
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
        [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];
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
    else   //VC is actually being popped. Must delete the song the user somewhat created
        [self.tableView cancelEditing];
    if(! userCreatedHisSong)
        [self.tableView songEditingWasSuccessful];
    else
        [self.tableView cancelEditing];
    [self.tableView preDealloc];
    self.tableView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadVideo];
    [[YouTubeVideoSearchService sharedInstance] setVideoDetailLookupDelegate:self];
    [[YouTubeVideoSearchService sharedInstance] fetchDetailsForVideo:ytVideo];
}

static short numberTimesViewHasBeenShown = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView viewWillAppear:animated];
    dontPreDealloc = NO;
    
    //hack to hide back button text.
    self.navigationController.navigationBar.topItem.title = @"";
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setUpLockScreenInfoAndArt)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationHasChanged)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                          target:self
                                                          action:@selector(shareButtonTapped)];
    
    self.navigationController.toolbarHidden = YES;
    
    //set nav bar title
    UINavigationController *navCon  = (UINavigationController*) [self.navigationController.viewControllers objectAtIndex:1];
    navCon.navigationItem.title = ytVideo.videoName;

    
    if(numberTimesViewHasBeenShown == 0)
        [self setPlaceHolderImageForVideoPlayer];  //would do this in viewDidLoad but self.view.frame has incorrect values until viewWillAppear
    
    if(videoPlayerViewController){
        [self setUpVideoView];
        //this sequence avoids a bug when user cancels "swipe to pop" gesture
        if(pausedBeforePopAttempt){
            [videoPlayerViewController pause];
            [videoPlayerViewController play];
        }
        [self checkCurrentPlaybackState];
    }
    if(numberTimesViewHasBeenShown == 0){
        //makes the tableview start AT the nav bar, not behind it.
        UIEdgeInsets inset = UIEdgeInsetsMake(44, 0, 0, 0);
        self.tableView.contentInset = inset;
        self.tableView.scrollIndicatorInsets = inset;
    }
    numberTimesViewHasBeenShown++;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView viewDidAppear:animated];
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

- (void)didReceiveMemoryWarning
{
    [self.tableView didReceiveMemoryWarning];
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
    __weak YouTubeVideo *weakVideo = ytVideo;
    __weak YouTubeSongAdderViewController *weakSelf = self;
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakVideo.videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
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
                    url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }else{
                    short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                    url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }
                
                videoPlayerViewController = [[MPMoviePlayerController alloc] init];
                [videoPlayerViewController setRepeatMode:(MPMovieRepeatModeNone)];
                [videoPlayerViewController setControlStyle:MPMovieControlStyleEmbedded];
                [videoPlayerViewController setScalingMode:MPMovieScalingModeAspectFit];
                [videoPlayerViewController setMovieSourceType:(MPMovieSourceTypeStreaming)];
                [videoPlayerViewController setContentURL:url];
                [videoPlayerViewController prepareToPlay];
                [weakSelf setUpVideoView];
                [videoPlayerViewController play];
            }
            else{
                [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
            }
        }
        else
        {
            // Handle error
            NSString *title = @"Trouble Loading Video";
            NSString *msg = @"Sorry, something whacky is going on, please try again.";
            //[self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
        }
    }];
}

#pragma mark - Video frame and player setup
- (void)setUpVideoView
{
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:NO];
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
        frameHeight = widthOfScreenRoationIndependant * (1/2.0);
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
                                            title:@""
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
        frameWidth = heightOfScreenRotationIndependant * (3/4.0);
        frameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:frameWidth];
    } else{
        frameWidth = widthOfScreenRoationIndependant;
        frameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:frameWidth];
    }
    
    UIView *placeHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, frameHeight)];
    [placeHolderView setBackgroundColor:[UIColor colorWithPatternImage:
                                         [UIImage imageWithColor:[UIColor clearColor] width:placeHolderView.frame.size.width height:placeHolderView.frame.size.height]]];
    
    [MRProgressOverlayView showOverlayAddedTo:placeHolderView
                                        title:@""
                                         mode:MRProgressOverlayViewModeIndeterminateSmall
                                     animated:YES];
    self.tableView.tableHeaderView = placeHolderView;
}

#pragma mark - Responding to video player events
- (void)playerPlaybackStateChanged:(NSNotification *)notif
{
    if (videoPlayerViewController.playbackState == MPMoviePlaybackStatePlaying){
        [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
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
    }
}

#pragma mark - Lock Screen Song Info & Art
- (void)setUpLockScreenInfoAndArt
{
    __weak YouTubeVideo *weakVideo = ytVideo;
    [SDWebImageDownloader.sharedDownloader downloadImageWithURL:[NSURL URLWithString:weakVideo.videoThumbnailUrlHighQuality]
                                                        options:0
                                                       progress:^(NSInteger receivedSize, NSInteger expectedSize) {}
                                                      completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
     {
         if (image && finished)
         {
             // do something with image
             Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
             if (playingInfoCenter) {
                 NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
                 
                 MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: image];
                 
                 [songInfo setObject:weakVideo.videoName forKey:MPMediaItemPropertyTitle];
                 if(weakVideo.channelTitle)
                     [songInfo setObject:weakVideo.channelTitle forKey:MPMediaItemPropertyArtist];
                 [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                 [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
             }
         }
     }];
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
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop];
        //set tint color specifically for this VC so that the cancel buttons are visible
        [activityVC.view setTintColor:[[UIColor defaultAppColorScheme] lighterColor]];
        [self presentViewController:activityVC animated:YES completion:nil];
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

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Managing video detail fetch response
- (void)detailsHaveBeenFetchedForYouTubeVideo:(YouTubeVideo *)video details:(NSDictionary *)details
{
    if([video.videoId isEqualToString:ytVideo.videoId]){
        if(details){
            videoDetails = [details copy];
            details = nil;
            [self.tableView canShowAddToLibraryButton];
        }
    }else
        return;
}

- (void)networkErrorHasOccuredFetchingVideoDetailsForVideo:(YouTubeVideo *)video
{
    if([video.videoId isEqualToString:ytVideo.videoId])
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_PotentialVideoDurationFetchFail];
    else
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
    [self preDealloc];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
