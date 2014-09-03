//
//  AppDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegate.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@implementation AppDelegate

static BOOL PRODUCTION_MODE;
static const int APP_LAUNCHED_FIRST_TIME = 0;
static const int APP_LAUNCHED_ALREADY = 1;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[SDImageCache sharedImageCache] setMaxCacheSize:2000000];  //2 mb cache size
    
    //set app global-tint color
    //self.window.tintColor = [UIColor defaultSystemTintColor];
    self.window.tintColor = Rgb2UIColor(255, 143, 47);  //orange tint color based on splash screen
    
    [self setProductionModeValue];
    
    if(! PRODUCTION_MODE)
        [AppDelegateSetupHelper logGlobalAppTintColor];
    
    [AppDelegateSetupHelper setAppSettingsAppLaunchedFirstTime:[self appLaunchedFirstTime]];
    if([self appLaunchedFirstTime]){
        //do stuff that you'd want to see the first time you launch!
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:APP_LAUNCHED_ALREADY forKey:APP_ALREADY_LAUNCHED_KEY];
    
    [self activateAudioSession];
    
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

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    if(player != nil)
        if(player.rate == 1.0f)
            [player performSelector:@selector(play) withObject:nil afterDelay:0.01];

    //Release all possible objects!
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

#pragma mark - AVAudio Player delegate stuff
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    switch (event.subtype)
    {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if([player rate] == 0){
                [PlaybackModelSingleton createSingleton].userWantsPlaybackPaused = NO;
                [player play];
            }
            else{
                [PlaybackModelSingleton createSingleton].userWantsPlaybackPaused = YES;
                [player pause];
            }
            
            break;
        case UIEventSubtypeRemoteControlPlay:
            [PlaybackModelSingleton createSingleton].userWantsPlaybackPaused = NO;
            [player play];
            break;
        case UIEventSubtypeRemoteControlPause:
            [PlaybackModelSingleton createSingleton].userWantsPlaybackPaused = YES;
            [player pause];
            break;
        default:
            break;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - AVAudioSession delegate stuff
static BOOL resumePlaybackAfterInterruption = NO;
- (void)beginInterruption
{
    //send out call to all delegates telling them the player has paused.
    AVPlayer *player = [[YouTubeMoviePlayerSingleton createSingleton] AVPlayer];
    if([player rate] == 1){  //only works in foreground or when app is on screen
        resumePlaybackAfterInterruption = YES;
    }
}

- (void)endInterruption
{
    [self activateAudioSession];
    if(resumePlaybackAfterInterruption){
        [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] play];
        resumePlaybackAfterInterruption = NO;
        //update gui, about to play audio again
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
    if(flags == AVAudioSessionInterruptionOptionShouldResume){
        [self activateAudioSession];
        if(resumePlaybackAfterInterruption){
            [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] play];
            resumePlaybackAfterInterruption = NO;
            //update gui, about to play audio again
        }
    }
}

#pragma mark - General Helper methods
- (void)activateAudioSession
{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setDelegate: self];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}


@end
