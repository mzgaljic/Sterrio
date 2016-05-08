//
//  AppDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegate.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "GSTouchesShowingWindow.h"
#import "PreloadedCoreDataModelUtility.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SDCAlertControllerView.h"
#import "SpotlightHelper.h"
#import "InAppPurchaseUtils.h"
#import "EAIntroView.h"
#import "AppDelegateUtils.h"
#import "MZPlayer.h"
#import "MainScreenViewController.h"
#import "MZLaunchScreen.h"
#import "IntroVideoView.h"
#import "InAppProductPriceHelper.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@interface AppDelegate () <EAIntroDelegate>
{
    AVAudioSession *audioSession;
    UIBackgroundTaskIdentifier task;
    UIBackgroundTaskIdentifier mergeEnsembleTask;
    
    BOOL backgroundTaskIsRunning;
    BOOL ensembleBackgroundMergeIsRunning;
}
@property (nonatomic, strong) EAIntroView *intro;
@property (nonatomic, strong, readwrite) MainScreenViewController *mainVC;
@property (nonatomic, strong) MZLaunchScreen *mzLaunchScreen;
@end

@implementation AppDelegate

static NSDate *nextEarliestAlbumArtUpdateForceTime;
static MRProgressOverlayView *hud;
static NSString * const songsVcSbId = @"songs view controller storyboard ID";
static NSString * const albumsVcSbId = @"albums view controller storyboard ID";
static NSString * const artistsVcSbId = @"artists view controller storyboard ID";
static NSString * const playlistsVcSbId = @"playlists view controller storyboard ID";

- (void)dealloc
{
    [self.previewPlayer destroyPlayer];
    self.previewPlayer = nil;
    self.intro.delegate = nil;
    self.intro = nil;
    self.mainVC = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (GSTouchesShowingWindow *)windowShowingTouches
{
    return [[GSTouchesShowingWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[AppEnvironmentConstants adsHaveBeenRemoved:NO];   //ONLY FOR DEVELOPMENT!!
    //[AppEnvironmentConstants setUserHasRatedMyApp:NO];  ONLY FOR DEVELOPMENT!!
    
    BOOL showUserTouchesOnScreen = NO;
    if(showUserTouchesOnScreen) {
        self.window = [self windowShowingTouches];
    } else {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    self.window.backgroundColor = [UIColor whiteColor];
    
    [AppDelegateSetupHelper loadAppThemeUserSettingFromNSUserDefaults];
    self.mzLaunchScreen = [[MZLaunchScreen alloc] init];
    UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:self.mzLaunchScreen];
    [self.window setRootViewController:navVc];
    [self.window makeKeyAndVisible];
    [self performSelectorOnMainThread:@selector(setupApplicationAndMainVc)
                           withObject:nil waitUntilDone:NO];
    return YES;
}

- (void)setupApplicationAndMainVc
{
    //set up Crashlytics immediately so any crashes are recorded.
    [Fabric with:@[[Answers class], [Crashlytics class]]];
    [AppDelegateSetupHelper loadUsersSettingsFromNSUserDefaults];
    [self setupMainVC];
    
    [AppDelegateSetupHelper setupDiskAndMemoryWebCache];
    if([AppDelegateSetupHelper appLaunchedFirstTime]){
        //do stuff that you'd want to see the first time you launch!
        [PreloadedCoreDataModelUtility createCoreDataSampleMusicData];
    }
    
    //must be after the previous if statement, otherwise not all colors are applied correctly.
    [AppDelegateSetupHelper setGlobalFontsAndColorsForAppGUIComponents];
    
    //create all contexts up front to avoid any funny business later (thread issues, etc.)
    [CoreDataManager context];
    [CoreDataManager backgroundThreadContext];
    [CoreDataManager stackControllerThreadContext];
    
    [AppDelegate upgradeLibraryToUseSpotlightIfApplicable];
    [ReachabilitySingleton sharedInstance];  //init reachability class
    [InAppPurchaseUtils sharedInstance];  //sets up transaction observers
    
    UIApplication *myApp = [UIApplication sharedApplication];
    [myApp setIdleTimerDisabled:NO];
    [myApp setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startupBackgroundTask)
                                                 name:MZStartBackgroundTaskHandlerIfInactive
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initAudioSession)
                                                 name:MZInitAudioSession
                                               object:nil];
    
    [LQAlbumArtBackgroundUpdater beginWaitingForEfficientMomentsToUpdateAlbumArt];
    [LQAlbumArtBackgroundUpdater forceCheckIfItsAnEfficientTimeToUpdateAlbumArt];
    [[InAppProductPriceHelper new] beginFetchingAdRemovalPriceInfoAndSetWhenDone];
}

- (void)setupMainVC
{
    UIStoryboard *sb = [MZCommons mainStoryboard];
    MasterSongsTableViewController *vc1 = [sb instantiateViewControllerWithIdentifier:songsVcSbId];
    MasterAlbumsTableViewController *vc2 = [sb instantiateViewControllerWithIdentifier:albumsVcSbId];
    MasterArtistsTableViewController *vc3 = [sb instantiateViewControllerWithIdentifier:artistsVcSbId];
    MasterPlaylistTableViewController *vc4 = [sb instantiateViewControllerWithIdentifier:playlistsVcSbId];
    
    vc1.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:0];
    UINavigationController *nav1 = [[UINavigationController alloc]initWithRootViewController:vc1];
    vc2.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:1];
    UINavigationController *nav2 = [[UINavigationController alloc]initWithRootViewController:vc2];
    vc3.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:2];
    UINavigationController *nav3 = [[UINavigationController alloc]initWithRootViewController:vc3];
    vc4.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:3];
    UINavigationController *nav4 = [[UINavigationController alloc]initWithRootViewController:vc4];
    
    NSArray *navControllers = @[nav1, nav2, nav3, nav4];
    NSArray *selectedImgNames = @[@"song_note_select", @"albums", @"artists", @"playlist_select"];
    NSArray *unselectedImgNames = @[@"song_note_unselect", @"albums", @"artists", @"playlist_unselect"];
    self.mainVC = [[MainScreenViewController alloc] initWithNavControllers:navControllers
                                         correspondingViewControllers:@[vc1, vc2, vc3, vc4]
                                           tabBarUnselectedImageNames:unselectedImgNames
                                             tabBarselectedImageNames:selectedImgNames];
    self.mainVC.view.alpha = 0;  //UIViewControllers lazy-load views. Forces load.
    [self.mzLaunchScreen dismissAnimatedAndDealloc];
    self.mzLaunchScreen = nil;
    [self.window setRootViewController:self.mainVC];
    [UIView animateWithDuration:0.65
                          delay:0
                        options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.mainVC.view.alpha = 1;
                     }
                     completion:nil];
    if([AppEnvironmentConstants shouldDisplayWelcomeScreen]) {
        self.mainVC.introOnScreen = YES;
        [self performSelector:@selector(showIntroTutorial) withObject:nil afterDelay:0.4];
    }
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
    if([AppEnvironmentConstants isUserPreviewingAVideo]){
        [self.previewPlayer reattachLayerWithPlayer];
    }
    [self reattachPlayerToPlayerLayer];
    
    if(! ensembleBackgroundMergeIsRunning){
        [self attemptEnsembleMergeInBackgroundTaskIfAppropriate];
    }
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
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
    
    [MyAlerts showAlertWithNumSkippedSongs];
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
            if([[AVAudioSession sharedInstance] isOtherAudioPlaying]) {
                return;
            }
            
            // • Make session active
            // • Update user interface
            // • AVAudioSessionInterruptionOptionShouldResume option
            if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume
                && ![AppEnvironmentConstants isUserCurrentlyOnCall])
            {
                // Here you should maybe continue playback...
                if([AppEnvironmentConstants isUserPreviewingAVideo]
                   && [AppEnvironmentConstants currrentPreviewPlayerState] == PREVIEW_PLAYBACK_STATE_Playing) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay
                                                                        object:nil];
                } else if(! [MusicPlaybackController playbackExplicitlyPaused]) {
                    [MusicPlaybackController resumePlayback];
                }
                break;
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

#pragma mark - Random
- (void)attemptEnsembleMergeInBackgroundTaskIfAppropriate
{
    if(! [AppEnvironmentConstants icloudSyncEnabled])
        return;

    NSDate *lastSuccessfulSyncDate = [AppEnvironmentConstants lastSuccessfulSyncDate];
    //did we already sync with icloud recently? If so, don't resync so soon!
    if([AppDelegateUtils daysBetweenDate:lastSuccessfulSyncDate andDate:[NSDate date]] <= 1) {
        NSTimeInterval distanceBetweenDates = [lastSuccessfulSyncDate timeIntervalSinceDate:[NSDate date]];
        double secondsInAnHour = 3600;  //not perfect but good enough here.
        NSInteger hoursBetweenDates = distanceBetweenDates / secondsInAnHour;
        if(hoursBetweenDates <= 1) {
            return;
        }
    }
    
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    if(! ensemble.isLeeched
       || [AppEnvironmentConstants isABadTimeToMergeEnsemble]) {
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
            
            float batteryLevel = [[UIDevice currentDevice] batteryLevel];
            batteryLevel *= 100;
            
            if(batteryLevel >= 35
               || [[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {
                [weakEnsemble mergeWithCompletion:^(NSError *error) {
                    if(error){
                        NSLog(@"Ensemble failed to merge in background.");
                    }
                    else{
                        [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                        NSLog(@"Ensemble merged in background.");
                    }
                }];
            } else {
                // processPendingChangesWithCompletion is a less expensive operation.
                [weakEnsemble processPendingChangesWithCompletion:^(NSError *error) {
                    if(error){
                        NSLog(@"Ensemble failed to complete queued tasks and save data to disk (in background.)");
                    } else{
                        [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                        NSLog(@"Ensemble completed queued tasks and saved data to disk (in background.)");
                    }
                }];
            }
            [[UIApplication sharedApplication] endBackgroundTask:mergeEnsembleTask];
            ensembleBackgroundMergeIsRunning = NO;
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
            pthread_setname_np([[NSString stringWithFormat:@"%@: Bckgrnd long video state checker", MZAppName] UTF8String]);
            [weakApplication beginReceivingRemoteControlEvents];
            int sleepInterval = 3;
            Song *nowPlaying;
            while (true){
                sleep(sleepInterval);
                if([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground || ![AppEnvironmentConstants limitVideoLengthOnCellular]){
                    //user not in background anymore or setting changed, this task is pointless.
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

#pragma mark - Spotlight Search
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler
{
    //This activity represents an item indexed using Core Spotlight, so restore the context
    //related to the unique identifier.
    if ([[userActivity activityType] isEqualToString:CSSearchableItemActionType]){
        NSString *uniqueId = [userActivity.userInfo objectForKey:CSSearchableItemActivityIdentifier];
        Song *songFromSpotlight = [AppDelegate songObjectGivenSongId:uniqueId];
        if(songFromSpotlight == nil)
            return NO;
        PlaybackContext *context = [AppDelegate contextForSpecificSongInAllSongsPage:songFromSpotlight];
    
        PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
        [playerView userKilledPlayer];
        [MusicPlaybackController newQueueWithSong:songFromSpotlight withContext:context];
    }
    
    return YES;
}

+ (Song *)songObjectGivenSongId:(NSString *)songId
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Song"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", songId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSArray *results = [[CoreDataManager context] executeFetchRequest:fetchRequest error:nil];
    if(results.count == 1)
        return results[0];
    else
        return nil;
}

+ (PlaybackContext *)contextForSpecificSongInAllSongsPage:(Song *)theSong
{
    NSString *allSongsPageVcName = @"MasterSongsTableViewController";

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", theSong.uniqueId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:allSongsPageVcName];
}

#pragma mark - Local notifications
- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif
{
    [app cancelAllLocalNotifications];
    
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:notif.alertTitle
                                                                    message:notif.alertBody
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                         style:SDCAlertActionStyleRecommended
                                                       handler:nil];
    [alert addAction:okAction];
    [alert presentWithCompletion:nil];
}

//----Spotlight upgrade helper code----
+ (void)upgradeLibraryToUseSpotlightIfApplicable
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove]) {
        return;  //users device is below ios 9 right now. no change in spotlight is possible.
    }
    
    int lastKnownUserIosVersionNumber = (int)[[NSUserDefaults standardUserDefaults] integerForKey:USERS_LAST_KNOWN_MAJOR_IOS_VERS_VALUE_KEY];
    
    if(lastKnownUserIosVersionNumber >= 9) {
        return;  //user has already upgraded library to use spotlight.
    }
    
    //if this point is reached, we need to get users songs into spotlight.
    [[NSUserDefaults standardUserDefaults] setInteger:[AppEnvironmentConstants usersMajorIosVersion]
                                               forKey:USERS_LAST_KNOWN_MAJOR_IOS_VERS_VALUE_KEY];
    
    [AppDelegate startTimingExecution];
    //shows progress bar (its updated below)
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    hud = [MRProgressOverlayView showOverlayAddedTo:keyWindow
                                              title:@"Spotlight is indexing your music."
                                               mode:MRProgressOverlayViewModeDeterminateHorizontalBar
                                           animated:YES];
    
    
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = nil;  //means i want all of the songs
    NSSortDescriptor *sortDescriptor;
    NSFetchedResultsController *fetchedRC;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    request.sortDescriptors = @[sortDescriptor];
    fetchedRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                    managedObjectContext:context
                                                      sectionNameKeyPath:nil
                                                               cacheName:nil];
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    if(fetchedRC.sections.count > 0) {
        sectionInfo = [fetchedRC.sections objectAtIndex:0];
    } else {
        fetchedRC = nil;
        return;  //no songs in library, nothing to update lol.
    }
    NSUInteger numTotalSongs = sectionInfo.numberOfObjects;
    NSUInteger numSongsIterated = 0;
    for(NSUInteger i = 0; i < numTotalSongs; i++) {
        //SpotlightHelper API only supports adding songs, but supports removing all 3 music types.
        //this is by design...
        Song *song = [fetchedRC objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [SpotlightHelper addSongToSpotlightIndex:song];
        song = nil;  //possible we might iterate through a huge # of songs. Should help with memory...
        [AppDelegate setHudProgressTo:(float)++numSongsIterated / (float)numTotalSongs];
    }
}
+ (void)setHudProgressTo:(float)value
{
    hud.progress = value;
    
    if(value == 1) {
        //at 100%
        NSUInteger minDesiredDuration = 2.3;
        NSTimeInterval time = [AppDelegate timeOnExecutionTimer];
        
        //ensure the hud doesn't dissapear instantly, which would look really bad.
        if(time < minDesiredDuration){
            [NSThread sleepForTimeInterval:fabs(time - minDesiredDuration)];
        }
        
        [hud dismiss:YES];
        hud = nil;
    }
}
static NSDate *start;
static NSDate *finish;
+ (void)startTimingExecution
{
    start = [NSDate date];
}
+ (NSTimeInterval)timeOnExecutionTimer
{
    if(start == nil)
        return 0;
    finish = [NSDate date];
    NSTimeInterval executionTime = [finish timeIntervalSinceDate:start];
    start = nil;
    finish = nil;
    
    return executionTime;
}
//----/End/ of Spotlight upgrade helper code----

#pragma mark - App Intro
- (void)showIntroTutorial
{
    //Mix audio with other apps for now...don't want intro videos to turn other audio off that the user may
    //have playing right now. If user decides to play an actual video from YouTube, MZInitAudiSession
    //notification will be fired, causing audio from other apps to be paused at that time.
    
    audioSession = nil;
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
     | AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:nil];
    [audioSession setActive:YES error:nil];
    
    NSArray *pages = @[[EAIntroPage page], [EAIntroPage page], [EAIntroPage page], [EAIntroPage page]];
    NSArray *desiredThemes = @[@"Sunrise", @"Forest", @"Sapphire", @"Bumblebee"];
    NSArray *introAppThemes = [MZAppTheme appThemesMatchingThemeNames:desiredThemes];
    NSAssert(introAppThemes.count == desiredThemes.count, @"An app theme name has changed, causing showIntroTutorial() to break.");
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *videoUrl = nil;
    for(int i = 0; i < pages.count; i++) {
        EAIntroPage *page = pages[i];
        MZAppTheme *theme = introAppThemes[i];
        page.bgColor = theme.mainGuiTint;
        
        switch (i) {
            case 0:
            {
                page.customView = [self viewForFirstPageOfIntro];
            }
                break;
            case 1:
            {
                NSString *desc = @"Queue songs to make a playlist on the fly!";
                videoUrl = [NSURL fileURLWithPath:[mainBundle pathForResource:@"Queue Songs"
                                                                       ofType:@"mp4"]];
                page.customView = [[IntroVideoView alloc] initWithFrame:self.mainVC.view.frame
                                                                  title:@"Queing Up Songs"
                                                            description:desc
                                                               videoUrl:videoUrl
                                                             mzAppTheme:theme];
            }
                break;
            case 2:
            {
                NSString *desc = [NSString stringWithFormat:@"%@ makes editing songs easy.", MZAppName];
                videoUrl = [NSURL fileURLWithPath:[mainBundle pathForResource:@"Editing A Song"
                                                                       ofType:@"mp4"]];
                page.customView = [[IntroVideoView alloc] initWithFrame:self.mainVC.view.frame
                                                                  title:@"Editing a Song"
                                                            description:desc
                                                               videoUrl:videoUrl
                                                             mzAppTheme:theme];
            }
                break;
            case 3:
            {
                NSString *desc = @"When you're finished, swipe the player off the screen.";
                videoUrl = [NSURL fileURLWithPath:[mainBundle pathForResource:@"Killing Player"
                                                                       ofType:@"mp4"]];
                page.customView = [[IntroVideoView alloc] initWithFrame:self.mainVC.view.frame
                                                                  title:@"Closing the Player"
                                                            description:desc
                                                               videoUrl:videoUrl
                                                             mzAppTheme:theme];
            }
                break;
            default:
                break;
        }
    }
    self.intro = [[EAIntroView alloc] initWithFrame:self.mainVC.view.frame
                                           andPages:pages];
    self.intro.hideSkipButton = NO;
    self.intro.delegate = self;
    [self.intro showInView:self.mainVC.view animateDuration:1.5];
}

- (UIView *)viewForFirstPageOfIntro
{
    //IMPORTANT NOTE: EAIntroView is WEIRD. Y coordinates are backwards. 0 is at bottom.
    float width = self.mainVC.view.frame.size.width;
    float height = self.mainVC.view.frame.size.height;
    UIView *customView1 = [[UIView alloc] initWithFrame:self.mainVC.view.frame];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15,
                                                                height/3,
                                                                width - 15,
                                                                70)];
    title.text = [NSString stringWithFormat:@"Welcome to %@.", MZAppName];
    title.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                  size:30];
    title.textColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
    title.numberOfLines = 0;
    title.textAlignment = NSTextAlignmentCenter;
    int descLabelY = [IntroVideoView descriptionYValueForViewSize:CGSizeMake(width, height)];
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(15,
                                                                     descLabelY,
                                                                     width - 15,
                                                                     height / 4)];
    description.text = @"Swipe for introduction.";
    description.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                       size:20];
    description.textColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
    description.numberOfLines = 0;
    description.textAlignment = NSTextAlignmentCenter;
    
    [customView1 addSubview:title];
    [customView1 addSubview:description];
    return customView1;
}

//delegates
static BOOL introAlreadyFinished = NO;
//intro did finish is called MANY times. prob has a bug lol.
- (void)introDidFinish:(EAIntroView *)introView
{
    self.mainVC.introOnScreen = NO;
    if(introAlreadyFinished)
        return;
    else
        introAlreadyFinished = YES;
    [self.intro hideWithFadeOutDuration:2];
    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_TosAndPrivacyPolicy];
}

static NSUInteger lastScrollingPageIndex = -1;
- (void)intro:(EAIntroView *)introView pageEndScrolling:(EAIntroPage *)page withIndex:(NSUInteger)pageIndex
{
    BOOL userNeverFullyScrolledAwayFromThisPage = (lastScrollingPageIndex == pageIndex);
    if(userNeverFullyScrolledAwayFromThisPage) {
        [self intro:introView pageAppeared:page withIndex:pageIndex];
    }
}
- (void)intro:(EAIntroView *)introView pageStartScrolling:(EAIntroPage *)page withIndex:(NSUInteger)pageIndex
{
    //user is beginning to swipe away from this page. Pause playback.
    UIView *customView = page.customView;
    if([customView respondsToSelector:@selector(stopPlaybackAndResetToBeginning)]) {
        [customView performSelector:@selector(stopPlaybackAndResetToBeginning)];
    }
    lastScrollingPageIndex = pageIndex;
}
- (void)intro:(EAIntroView *)introView pageAppeared:(EAIntroPage *)page withIndex:(NSUInteger)pageIndex
{
    //page appeared, start playing!
    UIView *customView = page.customView;
    if([customView respondsToSelector:@selector(startVideoLooping)]) {
        [customView performSelector:@selector(startVideoLooping)];
    }
    lastScrollingPageIndex = pageIndex;
}

@end
