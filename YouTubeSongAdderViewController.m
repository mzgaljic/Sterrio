//
//  YouTubeSongAdderViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "YouTubeSongAdderViewController.h"
#import "YouTubeService.h"
#import "SDCAlertController.h"
#import "SSBouncyButton.h"
#import "DiscogsSearchService.h"
#import "DiscogsItem.h"
#import "DiscogsResultsUtils.h"
#import "MZPlayer.h"
#import <TUSafariActivity.h>
#import "MZInterstitialAd.h"
#import "FetchVideoInfoOperation.h"

@interface YouTubeSongAdderViewController ()
{
    YouTubeVideo *ytVideo;
    UIImage *lockScreenImg;
    UIView *placeHolderView;
    BOOL enoughSongInformationGiven;
    BOOL userCreatedHisSong;
    BOOL preDeallocedAlready;
    
    BOOL didPresentVc;
    BOOL swipeToDismissInProgress;
    
    //fixes bug where player is invisible in view if it was added while the user was doing something else
    //(changing song name, etc)
    BOOL addPlayerToViewUponVcAppearance;
    
    NSDictionary *videoDetails;
    
    BOOL previewPlaybackBegan;
    BOOL previewIsUnplayable;
    
    BOOL leftAppDuePoweredByYtLogoClick;
    BOOL playerWasPlayingBeforeTappingPoweredByYt;
    
    BOOL musicWasPlayingBeforePreviewBegan;
    BOOL previousAllowsExternalPlayback;
    __block NSURL *url;
}

@property (nonatomic, strong) SSBouncyButton *poweredByYtBtn;
@property (nonatomic, strong) MZPlayer *player;
@property (nonatomic, strong) MZSongModifierTableView *tableView;
@property (nonatomic, strong) DiscogsItem *suggestedItem;  //nil until retrieved from API call.
@end

@implementation YouTubeSongAdderViewController

static BOOL skipCertainInitStepsFlag = NO;

#pragma mark - Custom Initializers
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject
                 thumbnail:(UIImage *)img
        existingSongToEdit:(Song *)song
{
    skipCertainInitStepsFlag = YES;
    self = [self initWithYouTubeVideo:youtubeVideoObject thumbnail:img];
    self.tableView.userPickingNewYtVideo = YES;
    self.tableView.songIAmEditing = song;
    [self.tableView initWasCalled];
    //provide default album art (making deep copy of album art)
    [self.tableView provideDefaultAlbumArt:lockScreenImg];
    skipCertainInitStepsFlag = NO;
    return self;
}
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject thumbnail:(UIImage *)img
{
    if (self = [super init]) {
        if(youtubeVideoObject == nil)
            return nil;
    
        //copying since certain internal ivars are cached, can mess up behavior of program if reused
        //across multiple inits of YouTubeSongAdderViewController.
        ytVideo = [youtubeVideoObject copy];
        NSString *sanitizedTitle = [ytVideo sanitizedTitle];
        
        if(! skipCertainInitStepsFlag) {
            [[DiscogsSearchService sharedInstance] queryWithTitle:sanitizedTitle
                                                          videoId:ytVideo.videoId
                                                 callbackDelegate:self];
        }

        MZSongModifierTableView *songEditTable;
        lockScreenImg = img;
        int navAndStatusHeight = [AppEnvironmentConstants navBarHeight];
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            navAndStatusHeight += [AppEnvironmentConstants statusBarHeight];
        }
        CGRect rect = CGRectMake(0, 0 - navAndStatusHeight, self.view.bounds.size.width, self.view.bounds.size.height + navAndStatusHeight);
        songEditTable = [[MZSongModifierTableView alloc] initWithFrame:rect
                                                                 style:UITableViewStyleGrouped];
        songEditTable.VC = self;
        self.tableView = songEditTable;
        self.tableView.theDelegate = self;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                            UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:self.tableView];
        if(! skipCertainInitStepsFlag) {
            [self.tableView initWasCalled];
        }
        
        //fire off network request for video duration ASAP
        [[YouTubeService sharedInstance] setVideoDetailLookupDelegate:self];
        [[YouTubeService sharedInstance] fetchDetailsForVideo:ytVideo];

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
    
    [[SongPlayerCoordinator sharedInstance] enablePlayerAgain];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.previewPlayer = nil;
    
    [self.player pause];
    [self.player destroyPlayer];
    preDeallocedAlready = YES;
    
    //VC is actually being popped. Must delete the song the user somewhat created
    if(!userCreatedHisSong)
        [self.tableView cancelEditing];
    
    self.tableView = nil;  //tableView will pre-dealloc itself.
    lockScreenImg = nil;
    _suggestedItem = nil;
    url = nil;
    [AppEnvironmentConstants setUserIsPreviewingAVideo:NO];
    [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Uninitialized];
    
    [[YouTubeService sharedInstance] removeVideoDetailLookupDelegate];
    [[DiscogsSearchService sharedInstance] cancelAllPendingRequests];
    
    [MusicPlaybackController obtainRawAVPlayer].allowsExternalPlayback = previousAllowsExternalPlayback;
    if(musicWasPlayingBeforePreviewBegan){
        [MusicPlaybackController resumePlayback];
        [MusicPlaybackController explicitlyPausePlayback:NO];
    }
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
            if(swipeToDismissInProgress) {
                //if player was playing and we just returned to this VC, pause and play again.
                //this fixes a bug where cancelling a "slide to pop" gesture would make the player appear "stuck".
                [self.player pause];
                [self.player play];
            }
            [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
        }
    }
    
    [self showOrUpdatePoweredByYtLogoGivenScreenWidth:self.view.frame.size.width];
    swipeToDismissInProgress = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([self isBeingDismissed] || [self isMovingFromParentViewController]) {
        swipeToDismissInProgress = YES;
    }
    [super viewWillDisappear:animated];
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
    
    BOOL allowedToPlayVideo = YES;
    ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
    
    if(duration >= MZLongestCellularPlayableDuration && [AppEnvironmentConstants limitVideoLengthOnCellular]){
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
    __block BOOL usingWifi = [[ReachabilitySingleton sharedInstance] isConnectedToWifi];
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakVideo.videoId
                                           completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        //block returns on main thread.
                   
        __weak ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
        BOOL videoDoesntExistOrApiChanged = (error.code == 150);
        __block NSURL *fullVideoUrl = nil;
        if([[ReachabilitySingleton sharedInstance] isConnectionCompletelyGone]){
            [weakSelf performSelectorOnMainThread:@selector(videoPreviewCannotBeShownNoYoutubeConnection)
                                       withObject:nil
                                    waitUntilDone:NO];
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //CAREFUL, don't access instance vars or call [weakSelf ...] from this background thread!
            
            if(videoDoesntExistOrApiChanged || video == nil) {
                //looks like XCDYouTubeKit needs to be updated, attempt to contact Sterrio.com rest endpoint
                //for a temporary url lookup.
                short maxVideoRes = [FetchVideoInfoOperation maxDesiredVideoQualityForConnectionTypeWifi:usingWifi];
                fullVideoUrl = [FetchVideoInfoOperation fullVideoUrlFromSterrioServer:weakVideo.videoId maxVideoResolution:maxVideoRes];
            }
            if(fullVideoUrl == nil && video) {
                //find video quality closest to setting preferences
                short maxDesiredQuality = [FetchVideoInfoOperation maxDesiredVideoQualityForConnectionTypeWifi:usingWifi];
                fullVideoUrl =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:video.streamURLs];
            } else {
                if([reachability isConnectionCompletelyGone]){
                    [weakSelf performSelectorOnMainThread:@selector(videoPreviewCannotBeShownNoYoutubeConnection)
                                               withObject:nil
                                            waitUntilDone:NO];
                } else {
                    //internet connection is very weak, or looks like some videos may not be loading properly anymore.
                    [weakSelf performSelectorOnMainThread:@selector(videoPreviewCannotBeShownErrorGrabbingVideoUrl)
                                               withObject:nil
                                            waitUntilDone:NO];
                }
                return;
            }
            
            //before creating MZPlayer instance, make sure the internet is still active.
            if([reachability isConnectionCompletelyGone]) {
                [weakSelf performSelectorOnMainThread:@selector(videoPreviewCannotBeShownNoYoutubeConnection)
                                           withObject:nil
                                        waitUntilDone:NO];
                return;
            }
            
            if(fullVideoUrl != nil) {
                [weakSelf performSelectorOnMainThread:@selector(videoLoadDidCompleteWithFullVideoUrl:)
                                           withObject:fullVideoUrl
                                        waitUntilDone:NO];
                return;
            }
        });
    }];
}

- (void)videoLoadDidCompleteWithFullVideoUrl:(NSURL *)fullVideoUrl
{
    url = fullVideoUrl;
    [self setUpVideoViewAndOrPlayerAboutToRotate:NO];
    [[SongPlayerCoordinator sharedInstance] temporarilyDisablePlayer];

}

#pragma mark - Video Player problems encountered code
- (void)videoPreviewCannotBeShownDurationTooLong
{
    previewIsUnplayable = YES;
    [self displayErrorOntopOfVideoWithMsg:@"This video is too long to preview on a cellular connection.\n\nTo change this behavior, go into 'Advanced' in the App settings."];
}

- (void)videoPreviewCannotBeShownNoYoutubeConnection
{
    previewIsUnplayable = YES;
    [self displayErrorOntopOfVideoWithMsg:@"Could not connect to YouTube."];
}

- (void)videoPreviewCannotBeShownErrorGrabbingVideoUrl
{
    previewIsUnplayable = YES;
    [self displayErrorOntopOfVideoWithMsg:@"A problem occurred loading this video, we've been notified of the problem."];
}

- (void)displayErrorOntopOfVideoWithMsg:(NSString *)msg
{
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView
                                            animated:YES];
    UILabel *label = [self createLabelForPlacementOnTableHeaderWithText:msg];
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
    label.numberOfLines = 0;
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
            self.player = [[MZPlayer alloc] initWithFrame:CGRectZero
                                                 videoURL:url
                                       useControlsOverlay:YES];
            [self.player setStallValueChangedDelegate:self];
            [self.player play];
            [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
            
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
        self.player = [[MZPlayer alloc] initWithFrame:videoFrameView.frame
                                             videoURL:url
                                   useControlsOverlay:YES];
        [self.player setStallValueChangedDelegate:self];
        [self.player play];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
        
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
        
        if(_suggestedItem && _suggestedItem.songName) {
            [songInfo setObject:_suggestedItem.songName forKey:MPMediaItemPropertyTitle];
        } else {
            [songInfo setObject:ytVideo.videoName forKey:MPMediaItemPropertyTitle];
        }
        if(_suggestedItem) {
            NSString *artistAndAlbum = [NSString stringWithFormat:@"%@ - %@", _suggestedItem.artistName, _suggestedItem.albumName];
            [songInfo setObject:artistAndAlbum forKey:MPMediaItemPropertyArtist];
        } else if(ytVideo.channelTitle)
            [songInfo setObject:ytVideo.channelTitle forKey:MPMediaItemPropertyArtist];
        
        if(albumArt)
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        
        NSNumber *duration = [videoDetails valueForKey:MZKeyVideoDuration];
        if(duration) {
            [songInfo setObject:[videoDetails valueForKey:MZKeyVideoDuration]
                         forKey:MPMediaItemPropertyPlaybackDuration];
            NSUInteger elapsedTime = [self.player elapsedTimeInSec];
            NSNumber *currentTime = [NSNumber numberWithInteger:elapsedTime];
            [songInfo setObject:currentTime forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            [songInfo setObject:[NSNumber numberWithFloat:self.player.avPlayer.rate]
                         forKey:MPNowPlayingInfoPropertyPlaybackRate];
        }
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
    __weak YouTubeVideo *weakCurrentVideo;
    if(currentVideo){
        NSString *youtubeLink = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", currentVideo.videoId];
        NSURL *shareUrl = [NSURL URLWithString:youtubeLink];
        NSArray *activityItems = @[shareUrl];
        
        //temporarily changing app default colors for the activityviewcontroller.
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.window.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[AppEnvironmentConstants appTheme].mainGuiTint, NSForegroundColorAttributeName, nil]];
        
        TUSafariActivity *openInSafariActivity = [[TUSafariActivity alloc] init];
        NSArray *activities = @[openInSafariActivity];
        __block UIActivityViewController *activityVC = [[UIActivityViewController alloc]
                                                        initWithActivityItems:activityItems
                                                        applicationActivities:activities];
        __weak UIActivityViewController *weakActivityVC = activityVC;
        __weak YouTubeSongAdderViewController *weakSelf = self;
        
        activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypeAirDrop,
                                             UIActivityTypeAddToReadingList];
        //set tint color specifically for this VC so that the text and buttons are visible
        [activityVC.view setTintColor:[AppEnvironmentConstants appTheme].mainGuiTint];
        [activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed,  NSArray *returnedItems, NSError *activityError) {
            if(activityType == nil) {
                activityType = @"";  //set it to an empty string just so we don't crash here.
            }
            NSString *regex = @"(UIActivityType)|(TU)|(Activity)|(.*\\.)";
            NSString *shareMethod = [MZCommons replaceCharsMatchingRegex:regex
                                                               withChars:@""
                                                             usingString:activityType];
            
            if(completed &&
               ([shareMethod caseInsensitiveCompare:@"Message"] == NSOrderedSame
                || [shareMethod caseInsensitiveCompare:@"Mail"] == NSOrderedSame
                || [shareMethod caseInsensitiveCompare:@"PostToFacebook"] == NSOrderedSame
                || [shareMethod caseInsensitiveCompare:@"PostToTwitter"] == NSOrderedSame
                || [shareMethod caseInsensitiveCompare:@"PostToWeibo"] == NSOrderedSame)) {
                   [Answers logShareWithMethod:shareMethod
                                   contentName:weakCurrentVideo.videoName
                                   contentType:@"YouTube Video"
                                     contentId:weakCurrentVideo.videoId
                              customAttributes:@{@"VideoFromLibrary" : [NSNumber numberWithBool:NO]}];
               }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                //restoring default button and title font colors in the app.
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.window.tintColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
                [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[AppEnvironmentConstants appTheme].navBarToolbarTextTint, NSForegroundColorAttributeName, nil]];
                [weakSelf.navigationController.navigationBar setTitleTextAttributes:
                 @{NSForegroundColorAttributeName:[AppEnvironmentConstants appTheme].navBarToolbarTextTint}];
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
    
    [self preDealloc];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if([MusicPlaybackController nowPlayingSong]) {
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
        }
    }];
    [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerCanIgnoreToolbar];
    
    [AppEnvironmentConstants incrementNumTimesUserAddedSongToLibCount];
    MainScreenViewController *mainScreenVc = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).mainVC;
    [[MZInterstitialAd sharedInstance] presentIfReadyWithRootVc:(UIViewController *)mainScreenVc
                                              withDismissAction:nil];
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
            previewPlaybackBegan = YES;
            [AppEnvironmentConstants setUserIsPreviewingAVideo:YES];
            if(self.player.isPlaying) {
                [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
            }
            
            [ReachabilitySingleton showCellularStreamingWarningIfApplicable];
            
            //needed to avoid causing an airplay conflict between the two avplayers
            previousAllowsExternalPlayback = [MusicPlaybackController obtainRawAVPlayer].allowsExternalPlayback;
            [MusicPlaybackController obtainRawAVPlayer].allowsExternalPlayback = NO;
            
            musicWasPlayingBeforePreviewBegan = ([MusicPlaybackController obtainRawAVPlayer].rate > 0);
            [MusicPlaybackController explicitlyPausePlayback:YES];
            [MusicPlaybackController pausePlayback];
            
            //first time we know that playback started, update album art now.
            [self setUpLockScreenInfoAndArt];
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            appDelegate.previewPlayer = self.player;
        }
        [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
    }
}

- (void)userHasPausedPlayback:(BOOL)paused
{
    if(paused) {
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
    } else {
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
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
    if(!self.player.playbackExplicitlyPaused && !self.player.isInStall) {
        playerWasPlayingBeforeTappingPoweredByYt = YES;
    }
    [self.player pause];
    [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Paused];
    
    NSString *youtubeLinkBeginning = @"https://www.youtube.com/watch?v=";
    NSMutableString *ytWebUrl = [NSMutableString stringWithString:youtubeLinkBeginning];
    [ytWebUrl appendString:ytVideo.videoId];
    
    NSURL *previewYtWebUrl = [NSURL URLWithString:ytWebUrl];
    leftAppDuePoweredByYtLogoClick = YES;
    if (![[UIApplication sharedApplication] openURL:previewYtWebUrl]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotOpenSafariError];
        leftAppDuePoweredByYtLogoClick = NO;
        playerWasPlayingBeforeTappingPoweredByYt = NO;
    }
}

- (void)appReturningToForeground
{
    if(leftAppDuePoweredByYtLogoClick && playerWasPlayingBeforeTappingPoweredByYt) {
        [self.player performSelector:@selector(play) withObject:nil afterDelay:0.2];
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Playing];
    }
    leftAppDuePoweredByYtLogoClick = NO;
    playerWasPlayingBeforeTappingPoweredByYt = NO;
}

#pragma mark - DiscogsSearchDelegate stuff
- (void)videoSongSuggestionsRequestComplete:(NSArray *)theItems
{
    [DiscogsResultsUtils applyConfidenceLevelsToDiscogsItemsForResults:&theItems youtubeVideo:ytVideo];
    NSUInteger bestMatchIndex = [DiscogsResultsUtils indexOfBestMatchFromResults:theItems];
    DiscogsItem *item = (bestMatchIndex == NSNotFound) ? nil : theItems[bestMatchIndex];
    
    if(item) {
        //good suggestion for user found!
        if(! item.itemGuranteedCorrect) {
            [DiscogsResultsUtils applySongNameToDiscogsItem:&item youtubeVideo:ytVideo];
            [DiscogsResultsUtils applyFinalArtistNameLogicForPresentation:&item];
        }
        [self.tableView newSongNameGuessed:item.songName
                               artistGuess:item.artistName
                                albumGuess:item.albumName];
        _suggestedItem = item;
        //now lock screen will show the new suggestion data
        [self setUpLockScreenInfoAndArt];
    }
}

- (void)videoSongSuggestionsRequestError:(NSError *)theError
{
    NSLog(@"request failed :(");
}

@end
