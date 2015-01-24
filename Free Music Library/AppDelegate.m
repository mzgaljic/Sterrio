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
    
    
    [AppDelegateSetupHelper setAppSettingsAppLaunchedFirstTime:[self appLaunchedFirstTime]];
    if([self appLaunchedFirstTime]){
        //do stuff that you'd want to see the first time you launch!
        [PreloadedCoreDataModelUtility createCoreDataSampleMusicData];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:APP_LAUNCHED_ALREADY
                                               forKey:APP_ALREADY_LAUNCHED_KEY];
    [self setupAudioSession];
    [self setupAudioSessionNotifications];
    
    return YES;
}

- (BOOL)appLaunchedFirstTime
{
    NSInteger code = [[NSUserDefaults standardUserDefaults] integerForKey:APP_ALREADY_LAUNCHED_KEY];
    if(code == APP_LAUNCHED_FIRST_TIME)
        return YES;
    else
        return NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
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
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if(player != nil)
        if(resumePlaybackAfterInterruption){
            [player performSelector:@selector(play) withObject:nil afterDelay:0.03];
            resumePlaybackAfterInterruption = NO;
        }
}

#pragma mark - AVAudio Player delegate stuff
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    switch (event.subtype)
    {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if([player rate] == 0){
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
            if([MusicPlaybackController didPlaybackStopDueToInternetProblemLoadingSong]){
                [player startPlaybackOfSong:[MusicPlaybackController nowPlayingSong] goingForward:YES];
            } else{
                [MusicPlaybackController explicitlyPausePlayback:NO];
                [player play];
            }
            break;
        case UIEventSubtypeRemoteControlPause:
            [MusicPlaybackController explicitlyPausePlayback:YES];
            [player pause];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [MusicPlaybackController skipToNextTrack];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
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
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    if([player rate] == 1){  //only works in foreground or when app is on screen
        resumePlaybackAfterInterruption = YES;
        [player pause];
    }
}

- (void)endInterruption
{
    [self setupAudioSession];
    if(resumePlaybackAfterInterruption){
        [[MusicPlaybackController obtainRawAVPlayer] play];
        resumePlaybackAfterInterruption = NO;
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
    if(flags == AVAudioSessionInterruptionOptionShouldResume){
        [self setupAudioSession];
        if(resumePlaybackAfterInterruption){
            [[MusicPlaybackController obtainRawAVPlayer] play];
            resumePlaybackAfterInterruption = NO;
        }
    }
}

- (void)handleMediaServicesReset
{
    [self setupAudioSession];
    if(resumePlaybackAfterInterruption){
        AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
        if(player){
            [player play];
        }
    }
}

@end
