//
//  AppDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegate.h"
#import "PreloadedCoreDataModelUtility.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@interface AppDelegate ()
{
    AVAudioSession *aSession;
    UIView *playerSnapshot;  //used to make it appear as if the playerlayer is still attached to the player in backgrounded mode.
    UIBackgroundTaskIdentifier task;
}
@end

@implementation AppDelegate

static BOOL PRODUCTION_MODE;
static NSString * const storyboardFileName = @"Main";
static NSString * const songsVcSbId = @"songs view controller storyboard ID";
static NSString * const albumsVcSbId = @"albums view controller storyboard ID";
static NSString * const artistsVcSbId = @"artists view controller storyboard ID";
static NSString * const playlistsVcSbId = @"playlists view controller storyboard ID";

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupMainVC
{
    UINavigationController *navController;
    MainScreenViewController *mainVC;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardFileName bundle: nil];
    
    MasterSongsTableViewController *vc1 = [storyboard instantiateViewControllerWithIdentifier:songsVcSbId];
    MasterAlbumsTableViewController *vc2 = [storyboard instantiateViewControllerWithIdentifier:albumsVcSbId];
    MasterArtistsTableViewController *vc3 = [storyboard instantiateViewControllerWithIdentifier:artistsVcSbId];
    MasterPlaylistTableViewController *vc4 = [storyboard instantiateViewControllerWithIdentifier:playlistsVcSbId];
    
    SegmentedControlItem *item1 = [[SegmentedControlItem alloc] initWithViewController:vc1
                                                                              itemName:[vc1 titleOfNavigationBar]];
    SegmentedControlItem *item2 = [[SegmentedControlItem alloc] initWithViewController:vc2
                                                                              itemName:[vc2 titleOfNavigationBar]];
    SegmentedControlItem *item3 = [[SegmentedControlItem alloc] initWithViewController:vc3
                                                                              itemName:[vc3 titleOfNavigationBar]];
    SegmentedControlItem *item4 = [[SegmentedControlItem alloc] initWithViewController:vc4
                                                                              itemName:[vc4 titleOfNavigationBar]];
    NSArray *segmentedControls = @[item1, item2, item3, item4];
    mainVC = [[MainScreenViewController alloc] initWithSegmentedControlItems:segmentedControls];
    
    navController = [[UINavigationController alloc] initWithRootViewController:mainVC];
    [self.window setRootViewController:navController];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setProductionModeValue];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [ReachabilitySingleton sharedInstance];  //init reachability class
    
    [AppDelegateSetupHelper setupDiskAndMemoryWebCache];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    //set global default "AppColorScheme"
    self.window.tintColor = [UIColor whiteColor];
    [UIColor defaultAppColorScheme:Rgb2UIColor(32, 69, 124)];  // original blue
    //[UIColor defaultAppColorScheme:Rgb2UIColor(0, 199, 248)];   blue inspired by finder
    //[UIColor defaultAppColorScheme:Rgb2UIColor(77, 167, 36)];   green color
    //[UIColor defaultAppColorScheme:Rgb2UIColor(234, 68, 56)];  redish color
    //[UIColor defaultAppColorScheme:Rgb2UIColor(32, 69, 124)];
    
    //set cancel button color of all uisearchbars
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
                            setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                [[UIColor defaultAppColorScheme] lighterColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    //set nav bar title color of all navbars
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor defaultWindowTintColor],NSForegroundColorAttributeName,nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
    BOOL appLaunchedFirstTime = [AppDelegateSetupHelper appLaunchedFirstTime];
    [AppDelegateSetupHelper setAppSettingsAppLaunchedFirstTime: appLaunchedFirstTime];
    
    if(appLaunchedFirstTime){
        //do stuff that you'd want to see the first time you launch!
        [PreloadedCoreDataModelUtility createCoreDataSampleMusicData];
        
        [AppDelegateSetupHelper reduceEncryptionStrengthOnRelevantDirs];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:APP_LAUNCHED_ALREADY
                                               forKey:APP_ALREADY_LAUNCHED_KEY];
    [self setupAudioSession];
    [self setupAudioSessionNotifications];
    
    [self setupMainVC];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [Fabric with:@[CrashlyticsKit]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    
    playerSnapshot = [playerView snapshotViewAfterScreenUpdates:NO];
    playerSnapshot.frame = playerView.frame;
    [self.window addSubview:playerSnapshot];
    [playerView removeFromSuperview];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self removePlayerFromPlayerLayer];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZAppWasBackgrounded object:nil];
    [self startupBackgroundTask];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //display how many songs were skipped while user was in background (long videos skipped)
    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
    [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //animate player back from snapshot
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    float animationDuration = 0.70f;
    [UIView animateWithDuration:animationDuration animations:^{
        playerSnapshot.alpha = 0.0;
    }];
    if([MusicPlaybackController obtainRawAVPlayer].rate == 1)
        playerView.alpha = 0;
    else
        playerView.alpha = 1;
    [self reattachPlayerToPlayerLayer];
    [self.window addSubview:playerView];
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         if([SongPlayerCoordinator isPlayerEnabled])
                             playerView.alpha = 1.0f;
                         else
                             playerView.alpha = [SongPlayerCoordinator alphaValueForDisabledPlayer];
                     } completion:^(BOOL finished) {
                         if(playerSnapshot){
                             [playerSnapshot removeFromSuperview];
                             playerSnapshot = nil;
                         }
                     }];

    //non-snapshot code below...
    if([AppEnvironmentConstants isUserPreviewingAVideo]){
        if(resumePlaybackAfterInterruptionPreviewPlayer){
            [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
            resumePlaybackAfterInterruptionPreviewPlayer = NO;
        }
    }
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player != nil){
        if(resumePlaybackAfterInterruption){
            [player play];
            resumePlaybackAfterInterruption = NO;
        }
    }
}

#pragma mark - AVAudio Player delegate stuff
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    switch (event.subtype)
    {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
               [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerTogglePlayPause object:nil];
            else if([player rate] == 0 && ![SongPlayerCoordinator isPlayerInDisabledState]){
                [MusicPlaybackController explicitlyPausePlayback:NO];
                [player play];
            } else if([player rate] == 0 && [SongPlayerCoordinator isPlayerInDisabledState]){
                break;
            }else{
                [MusicPlaybackController explicitlyPausePlayback:YES];
                [player pause];
            }
            
            break;
        case UIEventSubtypeRemoteControlPlay:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
            else{
                if([player rate] == 0 && ![SongPlayerCoordinator isPlayerInDisabledState]){
                    [MusicPlaybackController explicitlyPausePlayback:NO];
                    [player play];
                }
            }
            break;
        case UIEventSubtypeRemoteControlPause:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPause object:nil];
            else{
                [MusicPlaybackController explicitlyPausePlayback:YES];
                [player pause];
            }
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                return;
            [MusicPlaybackController skipToNextTrack];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                return;
            [MusicPlaybackController returnToPreviousTrack];
            break;
        default:
            break;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


#pragma mark - AVAudioSession stuff
/*
 useful link talking about the following methods:
 http://stackoverflow.com/questions/20736809/avplayer-handle-when-incoming-call-come
 */

static BOOL resumePlaybackAfterInterruption = NO;
static BOOL resumePlaybackAfterInterruptionPreviewPlayer = NO;

- (void)setupAudioSession
{
    NSError *error;
    aSession = [AVAudioSession sharedInstance];
    [aSession setCategory:AVAudioSessionCategoryPlayback
              withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                    error:&error];
    [aSession setMode:AVAudioSessionModeDefault error:&error];
    
    double sampleRate = 44100.0;  //44.1 Khz
    [aSession setPreferredSampleRate:sampleRate error:&error];
    
    [aSession setActive:YES error: &error];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [aSession setDelegate: self];
    #pragma GCC diagnostic warning "-Wdeprecated-declarations"
}

- (void)setupAudioSessionNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:aSession];
}

- (void)beginInterruption
{
    if([AppEnvironmentConstants isUserPreviewingAVideo]){
        if([AppEnvironmentConstants currrentPreviewPlayerState] == PREVIEW_PLAYBACK_STATE_Playing)
            resumePlaybackAfterInterruptionPreviewPlayer = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPause object:nil];
    }
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if([player rate] == 1){  //only works in foreground or when app is on screen
        resumePlaybackAfterInterruption = YES;
        [player pause];
    }
}

- (void)endInterruption
{
    [self setupAudioSession];
    if(resumePlaybackAfterInterruptionPreviewPlayer){
        [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
        resumePlaybackAfterInterruptionPreviewPlayer = NO;
    }
    if(resumePlaybackAfterInterruption){
        [[MusicPlaybackController obtainRawAVPlayer] play];
        resumePlaybackAfterInterruption = NO;
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
    if(flags == AVAudioSessionInterruptionOptionShouldResume){
        [self setupAudioSession];
        if(resumePlaybackAfterInterruptionPreviewPlayer){
            [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
            resumePlaybackAfterInterruptionPreviewPlayer = NO;
        }
        if(resumePlaybackAfterInterruption){
            [[MusicPlaybackController obtainRawAVPlayer] play];
            resumePlaybackAfterInterruption = NO;
        }
    }
}

- (void)handleMediaServicesReset
{
    [self setupAudioSession];
    if(resumePlaybackAfterInterruptionPreviewPlayer){
        [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
        resumePlaybackAfterInterruptionPreviewPlayer = NO;
    }
    if(resumePlaybackAfterInterruption){
        AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
        if(player){
            [player play];
        }
    }
}

#pragma mark - AVPlayer layer code
- (void)removePlayerFromPlayerLayer
{
    PlayerView *view = [MusicPlaybackController obtainRawPlayerView];
    [view removeLayerFromPlayer];
}

- (void)reattachPlayerToPlayerLayer
{
    PlayerView *view = [MusicPlaybackController obtainRawPlayerView];
    [view reattachLayerToPlayer];
}

- (void)startupBackgroundTask
{
    //check if we should continue to allow the app to monitor network changes for a limited time
    NSOperationQueue *loadingSongsQueue;
    loadingSongsQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
    if([SongPlayerCoordinator isPlayerOnScreen] || loadingSongsQueue.operationCount > 0){
        UIApplication *app = [UIApplication sharedApplication];
        __weak UIApplication *weakApp = app;
        __weak AppDelegate *weakSelf = self;
        task = [app beginBackgroundTaskWithExpirationHandler:^{
            
            [weakApp endBackgroundTask:task];
            task = UIBackgroundTaskInvalid;
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground){
                if(! [[AVAudioSession sharedInstance] isOtherAudioPlaying]){
                    //start a new task if it makes sense to do so.
                    [weakSelf startupBackgroundTask];
                }
            }
        }];
        
        //Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            pthread_setname_np("Bckgrnd long vid state checker");
            int sleepInterval = 3;
            Song *nowPlaying;
            while (true){
                sleep(sleepInterval);
                if([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground){
                    //user not in background anymore, this task is pointless.
                    [app endBackgroundTask:task];
                    task = UIBackgroundTaskInvalid;
                    break;
                }
                if([[AVAudioSession sharedInstance] isOtherAudioPlaying]){
                    //user will not want our app to continue playback if he/she already went to
                    //a different app to play other music. just kill the task and break.
                    [app endBackgroundTask:task];
                    task = UIBackgroundTaskInvalid;
                    break;
                }
                nowPlaying = [MusicPlaybackController nowPlayingSong];
                if([nowPlaying.duration integerValue] >= MZLongestCellularPlayableDuration){
                    if([SongPlayerCoordinator isPlayerInDisabledState]){
                        if([[ReachabilitySingleton sharedInstance] isConnectedToWifi]){
                            //connection to wifi restored, notify that playback can continue
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:MZInterfaceNeedsToBlockCurrentSongPlayback object:[NSNumber numberWithBool:NO]];
                            });
                        }
                    }
                }
            }  //end while
        });  //end async dispatch
    }
}

@end
