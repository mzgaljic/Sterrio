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
    //self.window.tintColor = Rgb2UIColor(255, 143, 47);  //orange tint color based on splash screen
    self.window.tintColor = Rgb2UIColor(255, 149, 0);
    
    [self setProductionModeValue];
    if(! PRODUCTION_MODE)
        [AppDelegateSetupHelper logGlobalAppTintColor];
    
    [AppDelegateSetupHelper setAppSettingsAppLaunchedFirstTime:[self appLaunchedFirstTime]];
    if([self appLaunchedFirstTime]){
        //do stuff that you'd want to see the first time you launch!
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:APP_LAUNCHED_ALREADY
                                               forKey:APP_ALREADY_LAUNCHED_KEY];
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

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if(player != nil)
        if(player.rate == 1.0f)
            [player performSelector:@selector(play) withObject:nil afterDelay:0.01];
}

#pragma mark - AVAudio Player delegate stuff
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    switch (event.subtype)
    {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            if([player rate] == 0){
                [MusicPlaybackController explicitlyPausePlayback:NO];
                [player play];
            }else{
                [MusicPlaybackController explicitlyPausePlayback:YES];
                [player pause];
            }
            
            break;
        case UIEventSubtypeRemoteControlPlay:
            [MusicPlaybackController explicitlyPausePlayback:NO];
            [player play];
            break;
        case UIEventSubtypeRemoteControlPause:
            [MusicPlaybackController explicitlyPausePlayback:YES];
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
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if([player rate] == 1){  //only works in foreground or when app is on screen
        resumePlaybackAfterInterruption = YES;
    }
}

- (void)endInterruption
{
    [self activateAudioSession];
    if(resumePlaybackAfterInterruption){
        [(MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer] play];
        resumePlaybackAfterInterruption = NO;
        //update gui if needed, about to play audio again
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
    if(flags == AVAudioSessionInterruptionOptionShouldResume){
        [self activateAudioSession];
        if(resumePlaybackAfterInterruption){
            [(MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer] play];
            resumePlaybackAfterInterruption = NO;
            //update gui if needed, about to play audio again
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
