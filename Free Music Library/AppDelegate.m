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
}
@end

@implementation AppDelegate

static BOOL PRODUCTION_MODE;
static const short APP_LAUNCHED_FIRST_TIME = 0;
static const short APP_LAUNCHED_ALREADY = 1;

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
    
    // Override point for customization after application launch.
    [[SDImageCache sharedImageCache] setMaxCacheSize:1000000];  //1 mb cache size
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    //set global default "AppColorScheme"
    self.window.tintColor = [UIColor whiteColor];
    [UIColor defaultAppColorScheme:Rgb2UIColor(32, 69, 124)];
    
    //set cancel button color of all uisearchbars
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
                            setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                [[UIColor defaultAppColorScheme] lighterColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    //set nav bar title color of all navbars
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor defaultWindowTintColor],NSForegroundColorAttributeName,nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
    BOOL appLaunchedFirstTime = [self appLaunchedFirstTime];
    [AppDelegateSetupHelper setAppSettingsAppLaunchedFirstTime: appLaunchedFirstTime];
    
    if(appLaunchedFirstTime){
        //do stuff that you'd want to see the first time you launch!
        [PreloadedCoreDataModelUtility createCoreDataSampleMusicData];
        
        [self reduceEncryptionStrengthOnRelevantDirs];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:APP_LAUNCHED_ALREADY
                                               forKey:APP_ALREADY_LAUNCHED_KEY];
    [self setupAudioSession];
    [self setupAudioSessionNotifications];
    
    return YES;
}


/*The Album Art dir must have an encryption level of
 NSFileProtectionCompleteUntilFirstUserAuthentication, otherwise the images for the lockscreen
 will not be able to load. */
- (void)reduceEncryptionStrengthOnRelevantDirs
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //now set documents dir encryption to a weaker value
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:documentsPath error:nil]];
    [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
}

static short appLaunchedFirstTimeDefensiveCount = 0;
- (BOOL)appLaunchedFirstTime
{
    //this counter helps us prevent the code beneath from being executed more than once per app launch.
    //doing so would cause the "whats new screen" to be messed up...displayed at wrong times.
    if(appLaunchedFirstTimeDefensiveCount > 0)
        return [AppEnvironmentConstants isFirstTimeAppLaunched];
    appLaunchedFirstTimeDefensiveCount++;
    
    //determine if "whats new" constant in this build is actually new.
    NSString *lastWhatsNewMsg = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_WhatsNewMsg];
    if(lastWhatsNewMsg == nil)
        [AppEnvironmentConstants marksWhatsNewMsgAsNew];
    else{
        if(! [lastWhatsNewMsg isEqualToString:MZWhatsNewUserMsg])
            [AppEnvironmentConstants marksWhatsNewMsgAsNew];
    }
    [[NSUserDefaults standardUserDefaults] setObject:MZWhatsNewUserMsg
                                              forKey:LAST_WhatsNewMsg];
    
    //determining whether or not "whats new" screen should be shown on this run of the app
    NSString *lastBuild = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_INSTALLED_BUILD];
    NSString *currentBuild = [UIDevice appBuildString];
    if(lastBuild == nil){
        lastBuild = currentBuild;
        [[NSUserDefaults standardUserDefaults] setObject:currentBuild
                                                  forKey:LAST_INSTALLED_BUILD];
    } else if(! [lastBuild isEqualToString:currentBuild] &&
                [AppEnvironmentConstants whatsNewMsgIsActuallyNew]){
        [AppEnvironmentConstants markShouldDisplayWhatsNewScreenTrue];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger code = [[NSUserDefaults standardUserDefaults] integerForKey:APP_ALREADY_LAUNCHED_KEY];
    if(code == APP_LAUNCHED_FIRST_TIME){
        
        //I want to only display one or the either, never the same on. Placement of this
        //if must stay exactly here, placement matters!
        if(! [AppEnvironmentConstants shouldDisplayWhatsNewScreen])
            [AppEnvironmentConstants markShouldDisplayWelcomeScreenTrue];
        
        [AppEnvironmentConstants markAppAsLaunchedForFirstTime];
        return YES;
    }
    else
        return NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZAppWasBackgrounded object:nil];
    
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player != nil){
        if(player.rate == 1 && !resumePlaybackAfterInterruption)
            [player performSelector:@selector(play) withObject:nil afterDelay:0.01];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //display how many songs were skipped while user was in background (long videos skipped)
    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
    [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if([AppEnvironmentConstants isUserPreviewingAVideo]){
        if(resumePlaybackAfterInterruptionPreviewPlayer){
            [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
            resumePlaybackAfterInterruptionPreviewPlayer = NO;
        }
    }
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player != nil){
        if(resumePlaybackAfterInterruption){
            [player performSelector:@selector(play) withObject:nil afterDelay:0.03];
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
            else if([player rate] == 0){
                if([MusicPlaybackController didPlaybackStopDueToInternetProblemLoadingSong]){
                    [player startPlaybackOfSong:[MusicPlaybackController nowPlayingSong] goingForward:YES];
                } else{
                    [MusicPlaybackController explicitlyPausePlayback:NO];
                    [player play];
                }
            }else{
                [MusicPlaybackController explicitlyPausePlayback:YES];
                [player pause];
            }
            
            break;
        case UIEventSubtypeRemoteControlPlay:
            if([AppEnvironmentConstants isUserPreviewingAVideo])
                [[NSNotificationCenter defaultCenter] postNotificationName:MZPreviewPlayerPlay object:nil];
            else if([MusicPlaybackController didPlaybackStopDueToInternetProblemLoadingSong]){
                [player startPlaybackOfSong:[MusicPlaybackController nowPlayingSong] goingForward:YES];
            } else{
                [MusicPlaybackController explicitlyPausePlayback:NO];
                [player play];
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
              withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                    error:&error];
    [aSession setMode:AVAudioSessionModeMoviePlayback error:&error];
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

@end
