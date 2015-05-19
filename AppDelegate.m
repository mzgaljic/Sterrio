//
//  AppDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegate.h"
#import "GSTouchesShowingWindow.h"
#import "PreloadedCoreDataModelUtility.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@interface AppDelegate ()
{
    AVAudioSession *audioSession;
    UIBackgroundTaskIdentifier task;
    UIBackgroundTaskIdentifier mergeEnsembleTask;
    
    BOOL backgroundTaskIsRunning;
    BOOL ensembleBackgroundMergeIsRunning;
}
@end

@implementation AppDelegate

static NSDate *nextEarliestAlbumArtUpdateForceTime;
static NSString * const storyboardFileName = @"Main";
static NSString * const songsVcSbId = @"songs view controller storyboard ID";
static NSString * const albumsVcSbId = @"albums view controller storyboard ID";
static NSString * const artistsVcSbId = @"artists view controller storyboard ID";
static NSString * const playlistsVcSbId = @"playlists view controller storyboard ID";

- (void)dealloc
{
    [self.previewPlayer destroyPlayer];
    self.previewPlayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (GSTouchesShowingWindow *)windowShowingTouches
{
    static GSTouchesShowingWindow *window = nil;
    if (!window) {
        self.window = [GSTouchesShowingWindow alloc];
        [self.window makeKeyAndVisible];
        self.window.frame = [[UIScreen mainScreen] bounds];
    }
    return window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL showUserTouchesOnScreen = NO;
    if(showUserTouchesOnScreen)
        self.window = [self windowShowingTouches];
    else{
        self.window = [UIWindow new];
        [self.window makeKeyAndVisible];
        self.window.frame = [[UIScreen mainScreen] bounds];
    }
    
    [ReachabilitySingleton sharedInstance];  //init reachability class
    //[LQAlbumArtBackgroundUpdater beginWaitingForEfficientMomentsToUpdateAlbumArt];
    //[LQAlbumArtBackgroundUpdater forceCheckIfItsAnEfficientTimeToUpdateAlbumArt];
    
    [AppDelegateSetupHelper setupDiskAndMemoryWebCache];
    
    BOOL appLaunchedFirstTime = [AppDelegateSetupHelper appLaunchedFirstTime];
    [AppDelegateSetupHelper loadUsersSettingsFromNSUserDefaults];
    
    if(appLaunchedFirstTime){
        //do stuff that you'd want to see the first time you launch!
        [PreloadedCoreDataModelUtility createCoreDataSampleMusicData];
    }
    
    
    [[NSUserDefaults standardUserDefaults] setInteger:APP_LAUNCHED_ALREADY
                                               forKey:APP_ALREADY_LAUNCHED_KEY];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [AppDelegateSetupHelper setGlobalFontsAndColorsForAppGUIComponents];
    [self setupMainVC];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startupBackgroundTask)
                                                 name:MZStartBackgroundTaskHandlerIfInactive
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initAudioSession)
                                                 name:MZInitAudioSession
                                               object:nil];
    
    UIApplication *myApp = [UIApplication sharedApplication];
    [myApp setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [Fabric with:@[CrashlyticsKit]];
    
    return YES;
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
    [self startupBackgroundTask];
}

//background fetch when app is inactive
- (void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if(! [AppEnvironmentConstants icloudSyncEnabled]){
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    if(! ensemble.isLeeched)
    {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    __weak CDEPersistentStoreEnsemble *weakEnsemble = ensemble;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Ensembles is downloading new files (if any) during background app refresh. Will merge on app launch.");
        CDEICloudFileSystem *cloudFileSystem = (id)weakEnsemble.cloudFileSystem;
        completionHandler(cloudFileSystem.bytesRemainingToDownload > 0 ?
                          UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if([AppEnvironmentConstants isUserPreviewingAVideo]){
        [self.previewPlayer removePlayerFromLayer];
    }
    
    [self removePlayerFromPlayerLayer];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZAppWasBackgrounded object:nil];
    [self attemptEnsembleMergeInBackgroundTaskIfAppropriate];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //display how many songs were skipped while user was in background (long videos skipped)
    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
    [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
    
    if([AppEnvironmentConstants isUserPreviewingAVideo]){
        [self.previewPlayer reattachLayerWithPlayer];
    }
    [self reattachPlayerToPlayerLayer];
    
    if(! ensembleBackgroundMergeIsRunning){
        [self attemptEnsembleMergeInBackgroundTaskIfAppropriate];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if(nextEarliestAlbumArtUpdateForceTime == nil){
        nextEarliestAlbumArtUpdateForceTime = [NSDate date];
        nextEarliestAlbumArtUpdateForceTime = [self generateNextEarliestAlbumArtUpdateForceTime];
        [LQAlbumArtBackgroundUpdater forceCheckIfItsAnEfficientTimeToUpdateAlbumArt];
    }
    else
    {
        if ([self isNSDateObjInPast:nextEarliestAlbumArtUpdateForceTime]) {
            // Date and time have passed
            nextEarliestAlbumArtUpdateForceTime = [self generateNextEarliestAlbumArtUpdateForceTime];
        }
    }
}

//helpers for the above method
- (NSDate *)generateNextEarliestAlbumArtUpdateForceTime
{
    return [nextEarliestAlbumArtUpdateForceTime dateByAddingTimeInterval:20];
}

- (BOOL)isNSDateObjInPast:(NSDate *)date
{
    return ([date timeIntervalSinceNow] < 0.0) ? YES : NO;
}

#pragma mark - AVAudio Player delegate stuff
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    BOOL userCurrentlyOnCall = [AppEnvironmentConstants isUserCurrentlyOnCall];
    if(userCurrentlyOnCall)
        return;
    
    switch (event.subtype)
    {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerTogglePlayPause
                                                                    object:nil];
            else if([player rate] == 0 && ![SongPlayerCoordinator isPlayerInDisabledState])
            {
                [MusicPlaybackController explicitlyPausePlayback:NO];
                [player play];
            }
            else
            {
                [MusicPlaybackController explicitlyPausePlayback:YES];
                [player pause];
            }
            break;
            
        case UIEventSubtypeRemoteControlPlay:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
            else
            {
                if([player rate] == 0 && ![SongPlayerCoordinator isPlayerInDisabledState])
                {
                    [MusicPlaybackController explicitlyPausePlayback:NO];
                    [player play];
                }
            }
            break;
        case UIEventSubtypeRemoteControlPause:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPause object:nil];
            else
            {
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
- (void)initAudioSession
{
    audioSession = nil;
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback
              withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                            | AVAudioSessionCategoryOptionDefaultToSpeaker
                    error:nil];
    [audioSession setActive:YES error:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioSessionInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:audioSession];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:audioSession];
}

//incoming call, alarm clock, etc.
- (void)handleAudioSessionInterruption:(NSNotification*)notification
{
    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
    
    switch (interruptionType.unsignedIntegerValue)
    {
        case AVAudioSessionInterruptionTypeBegan:
        {
            // • Audio has stopped, already inactive
            // • Change state of UI, etc., to reflect non-playing state
            
            
            //this notification will also force the playerVC to check the apps playback rate...
            [[NSNotificationCenter defaultCenter] postNotificationName:MZAVPlayerStallStateChanged
                                                                object:nil];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded:
        {
            // • Make session active
            // • Update user interface
            // • AVAudioSessionInterruptionOptionShouldResume option
            if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume
                && ![AppEnvironmentConstants isUserCurrentlyOnCall])
            {
                // Here you should continue playback.
                
                if([AppEnvironmentConstants isUserPreviewingAVideo])
                    [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay
                                                                        object:nil];
                else
                    [MusicPlaybackController resumePlayback];
            }
            break;
        }
        default:
            break;
    }
}

//if the media server resets for any reason, you should handle this notification to reconfigure audio or do any
//housekeeping. By the way the notification dictionary won't contain any object.
- (void)handleMediaServicesReset
{
    // • No userInfo dictionary for this notification
    // • Audio streaming objects are invalidated (zombies)
    // • Handle this notification by fully reconfiguring audio
    [self initAudioSession];
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

- (void)attemptEnsembleMergeInBackgroundTaskIfAppropriate
{
    if(! [AppEnvironmentConstants icloudSyncEnabled])
        return;
    
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    if(! ensemble.isLeeched
       || [AppEnvironmentConstants isABadTimeToMergeEnsemble])
    {
        return;
    }
    
    mergeEnsembleTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
    ensembleBackgroundMergeIsRunning = YES;
    
    __weak CDEPersistentStoreEnsemble *weakEnsemble = ensemble;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSManagedObjectContext *managedObjectContext = [CoreDataManager context];
        
        [managedObjectContext performBlock:^{
            if (managedObjectContext.hasChanges) {
                [managedObjectContext save:NULL];
            }
            
            [weakEnsemble mergeWithCompletion:^(NSError *error) {
                if(error){
                   NSLog(@"Ensemble failed to merge in background.");
                }
                else{
                    [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                    NSLog(@"Ensemble merged in background.");
                }
                
                [[UIApplication sharedApplication] endBackgroundTask:mergeEnsembleTask];
                ensembleBackgroundMergeIsRunning = NO;
            }];
        }];
    });
}

- (void)startupBackgroundTask
{
    if(backgroundTaskIsRunning)
        return;
    
    //check if we should continue to allow the app to monitor network changes for a limited time
    NSOperationQueue *loadingSongsQueue;
    loadingSongsQueue = [[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue];
    if([SongPlayerCoordinator isPlayerOnScreen]
       || loadingSongsQueue.operationCount > 0
       || [AppEnvironmentConstants isUserPreviewingAVideo]){
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