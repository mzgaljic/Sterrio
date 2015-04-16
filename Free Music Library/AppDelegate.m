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
    
    BOOL backgroundTaskIsRunning;
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setProductionModeValue];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [ReachabilitySingleton sharedInstance];  //init reachability class
    
    [AppDelegateSetupHelper setupDiskAndMemoryWebCache];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [self setGlobalFontsAndColors];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startupBackgroundTask)
                                                 name:MZStartBackgroundTaskHandlerIfInactive
                                               object:nil];
    return YES;
}

- (void)setGlobalFontsAndColors
{
    //set global default "AppColorScheme"
    self.window.tintColor = [UIColor whiteColor];
    //vibrant orange
    [UIColor defaultAppColorScheme:Rgb2UIColor(240, 110, 50)];
    
    //emerald green
    //[UIColor defaultAppColorScheme:[Rgb2UIColor(74, 153, 118) darkerColor]];
    //bright pink
    //[UIColor defaultAppColorScheme:[Rgb2UIColor(233, 91, 152) lighterColor]];
    //regular blue
    //[UIColor defaultAppColorScheme:Rgb2UIColor(57, 104, 190)];
    //purple
    //[UIColor defaultAppColorScheme:Rgb2UIColor(111, 91, 164)];
    //yellow
    //[UIColor defaultAppColorScheme:Rgb2UIColor(254, 200, 45)];
    
    //cancel button color of all uisearchbars
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             [[UIColor defaultAppColorScheme] lighterColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    
    //tab bar font
    UIFont *tabBarFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                         size:10];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:tabBarFont, NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    UIFont *barButtonFonts = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:17];
    NSDictionary *barButtonAttributes = @{
                                        NSForegroundColorAttributeName : [UIColor defaultWindowTintColor],
                                        NSFontAttributeName : barButtonFonts
                                            };
    
    //toolbar button colors
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]
     setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             [[UIColor defaultAppColorScheme] lighterColor],
                             NSForegroundColorAttributeName,
                             barButtonFonts, NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    //nav bar attributes
    UIFont *navBarFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:20];
    NSDictionary *navBarTitleAttributes = @{
                                       NSForegroundColorAttributeName : [UIColor defaultWindowTintColor],
                                       NSFontAttributeName : navBarFont
                                       };
    [[UINavigationBar appearance] setTitleTextAttributes:navBarTitleAttributes];
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAttributes
                                                forState:UIControlStateNormal];
    //search bar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:@{NSFontAttributeName:barButtonFonts} forState:UIControlStateNormal];
    
    //particulary useful for alert views.
    [[UITextField appearance] setTintColor:[UIColor darkGrayColor]];
}

- (void)setupMainVC
{
    MainScreenViewController *mainVC;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardFileName bundle: nil];
    
    MasterSongsTableViewController *vc1 = [storyboard instantiateViewControllerWithIdentifier:songsVcSbId];
    MasterAlbumsTableViewController *vc2 = [storyboard instantiateViewControllerWithIdentifier:albumsVcSbId];
    MasterArtistsTableViewController *vc3 = [storyboard instantiateViewControllerWithIdentifier:artistsVcSbId];
    MasterPlaylistTableViewController *vc4 = [storyboard instantiateViewControllerWithIdentifier:playlistsVcSbId];
    
    vc1.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:0];
    UINavigationController *navController1 = [[UINavigationController alloc]initWithRootViewController:vc1];
    vc2.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:1];
    UINavigationController *navController2 = [[UINavigationController alloc]initWithRootViewController:vc2];
    vc3.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:2];
    UINavigationController *navController3 = [[UINavigationController alloc]initWithRootViewController:vc3];
    vc4.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:3];
    UINavigationController *navController4 = [[UINavigationController alloc]initWithRootViewController:vc4];
    
    NSArray *navControllers = @[navController1, navController2, navController3, navController4];
    NSArray *selectedImgNames = @[@"song_note_select", @"albums", @"", @"playlist_select"];
    NSArray *unselectedImgNames = @[@"song_note_unselect", @"albums", @"", @"playlist_unselect"];
    mainVC = [[MainScreenViewController alloc] initWithNavControllers:navControllers
                                         correspondingViewControllers:@[vc1, vc2, vc3, vc4]
                                           tabBarUnselectedImageNames:unselectedImgNames
                                             tabBarselectedImageNames:selectedImgNames];
    
    [self.window setRootViewController:mainVC];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    if(! [SongPlayerCoordinator screenShottingVideoPlayerNotAllowed]){
        playerSnapshot = [playerView snapshotViewAfterScreenUpdates:NO];
        playerSnapshot.frame = playerView.frame;
        playerSnapshot.userInteractionEnabled = NO;
        [self.window addSubview:playerSnapshot];
    }
    playerView.alpha = 0;
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
    
    [self reattachPlayerToPlayerLayer];
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
    float animationDuration = 0.74f;
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         playerSnapshot.alpha = 0.0;
                         if([SongPlayerCoordinator isPlayerEnabled])
                             playerView.alpha = 1;
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
    if(backgroundTaskIsRunning)
        return;
    
    //check if we should continue to allow the app to monitor network changes for a limited time
    NSOperationQueue *loadingSongsQueue;
    loadingSongsQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
    if([SongPlayerCoordinator isPlayerOnScreen] || loadingSongsQueue.operationCount > 0){
        backgroundTaskIsRunning = YES;
        UIApplication *app = [UIApplication sharedApplication];
        __weak UIApplication *weakApp = app;
        __weak AppDelegate *weakSelf = self;
        task = [app beginBackgroundTaskWithExpirationHandler:^{
            
            backgroundTaskIsRunning = NO;
            [weakApp endBackgroundTask:task];
            task = UIBackgroundTaskInvalid;
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground){
                if(! [[AVAudioSession sharedInstance] isOtherAudioPlaying]){
                    //start a new task if it makes sense to do so.
                    [weakSelf startupBackgroundTask];
                }
                else
                    [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
            }
        }];
        
        __weak UIApplication *weakApplication = [UIApplication sharedApplication];
        //Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            pthread_setname_np("MZMusic: Bckgrnd long video state checker");
            [weakApplication beginReceivingRemoteControlEvents];
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
