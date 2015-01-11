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
    UIView *placeHolderView;
    UIBarButtonItem *addToLibraryButton;
    BOOL enoughSongInformationGiven;
    BOOL playbackFinished;
    BOOL doneTappedInVideo;
    BOOL pausedBeforePopAttempt;
    NSUInteger videoDuration;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;
@end

@implementation YouTubeSongAdderViewController

#pragma mark - Custom Initializer
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    YouTubeSongAdderViewController* vc = [sb instantiateViewControllerWithIdentifier:@"ytVideoFieldEntryAndVideoPlayer"];
    self = vc;
    if (self) {
        if(youtubeVideoObject == nil)
            return nil;
        ytVideo = youtubeVideoObject;
        pausedBeforePopAttempt = YES;
        videoDuration = 0;
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
    [[YouTubeVideoSearchService sharedInstance] removeVideoDurationDelegate];
    
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([YouTubeSongAdderViewController class]));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadVideo];
    [[YouTubeVideoSearchService sharedInstance] setVideoDurationDelegate:self];
    [[YouTubeVideoSearchService sharedInstance] fetchDurationInSecondsForVideo:ytVideo];
}

static short numberTimesViewHasBeenShown = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    _navBar.title = ytVideo.videoName;
     _navBar.backBarButtonItem.title = @"";

    
    if(numberTimesViewHasBeenShown == 0)
        [self setPlaceHolderImageForVideoPlayer];  //would do this in viewDidLoad but self.view.frame has incorrect values until viewWillAppear
    numberTimesViewHasBeenShown++;
    
    if(videoPlayerViewController){
        [self setUpVideoView];
        //this sequence avoids a bug when user cancels "swipe to pop" gesture
        if(pausedBeforePopAttempt){
            [videoPlayerViewController pause];
            [videoPlayerViewController play];
        }
        [self checkCurrentPlaybackState];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self checkCurrentPlaybackState];
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
                [self setUpVideoView];
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
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
    
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
    
    CGRect viewFrame = self.view.frame;
    UIView *rootHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, frameHeight)];
    UIView *videoFrameView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, frameHeight)];
    [videoFrameView setBackgroundColor:[UIColor blackColor]];
    [self.tableView setTableHeaderView:rootHeaderView];

    [[videoPlayerViewController view] setFrame:videoFrameView.frame]; // player's frame size must match parent's
    [rootHeaderView addSubview:videoFrameView];
    [videoFrameView addSubview: [videoPlayerViewController view]];
    [videoFrameView bringSubviewToFront:[videoPlayerViewController view]];
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
    
    placeHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, frameHeight)];
    [placeHolderView setBackgroundColor:[UIColor colorWithPatternImage:
                                         [UIImage imageWithColor:[UIColor clearColor] width:placeHolderView.frame.size.width height:placeHolderView.frame.size.height]]];
    
    [MRProgressOverlayView showOverlayAddedTo:placeHolderView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
    self.tableView.tableHeaderView = placeHolderView;
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

#pragma mark - Toolbar button code
- (void)setUpAddToLibraryButton
{
    addToLibraryButton = [[UIBarButtonItem alloc] initWithTitle:@"Add To Library"
                                                           style:UIBarButtonItemStyleDone
                                                          target:self
                                                          action:@selector(addToLibraryButtonTapped)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [self makeBarButtonItemGrey:addToLibraryButton];
    [self.navigationController.toolbar setItems:@[flexibleSpace, addToLibraryButton] animated:YES];
}

- (void)makeBarButtonItemGrey:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = false;
}

- (void)makeBarButtonItemNormal:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStyleDone;
    barButton.enabled = true;
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
        //set tint color specifically for this VC so that the cancel buttons arent invisible
        [activityVC.view setTintColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
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

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Managing video duration fetching
- (void)ytVideoDurationHasBeenFetched:(NSUInteger)durationInSeconds forVideo:(YouTubeVideo *)video;
{
    if([video.videoId isEqualToString:ytVideo.videoId])
        videoDuration = durationInSeconds;
    else
        return;
}

- (void)networkErrorHasOccuredFetchingVideoDurationForVideo:(YouTubeVideo *)video
{
    if([video.videoId isEqualToString:ytVideo.videoId]){
        //notify user about the problem
#warning not implemented
    } else
        //false alarm about a problem that occured with a previous fetch? Disregard.
        return;
}

@end
