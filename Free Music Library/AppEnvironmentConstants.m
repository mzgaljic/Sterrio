//
//  AppEnvironmentConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"
#import "AppDelegateSetupHelper.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#define Rgb2UIColor(r, g, b, a)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]

@implementation AppEnvironmentConstants

static const BOOL PRODUCTION_MODE = YES;
static BOOL shouldShowWhatsNewScreen = NO;
static BOOL shouldDisplayWelcomeScreen = NO;
static BOOL isFirstTimeAppLaunched = NO;
static BOOL whatsNewMsgIsNew = NO;
static BOOL USER_EDITING_MEDIA = YES;
static BOOL userIsPreviewingAVideo = NO;

static BOOL playbackTimerActive = NO;
static NSInteger activePlaybackTimerThreadNum;

static PLABACK_REPEAT_MODE repeatType;

static PREVIEW_PLAYBACK_STATE currentPreviewPlayerState = PREVIEW_PLAYBACK_STATE_Uninitialized;

static int preferredSongCellHeight;
static short preferredWifiStreamValue;
static short preferredCellularStreamValue;
static BOOL icloudSyncEnabled;

static BOOL tabBarIsHidden = NO;

static int navBarHeight;
static short statusBarHeight;
static NSInteger lastPlayerViewIndex = NSNotFound;


//runtime configuration
+ (BOOL)isUserOniOS8OrAbove
{
    // conditionally check for any version >= iOS 8 using 'isOperatingSystemAtLeastVersion'
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return YES;
    else
        return NO;
}


+ (BOOL)isUserCurrentlyOnCall
{    
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall *call in callCenter.currentCalls)  {
        if (call.callState == CTCallStateConnected) {
            return YES;
        }
    }
    return NO;
}

+ (void)recordIndexOfPlayerView:(NSUInteger)index
{
    lastPlayerViewIndex = index;
}

+ (NSUInteger)lastIndexOfPlayerView
{
    return lastPlayerViewIndex;
}


+ (BOOL)isAppInProductionMode
{
    return PRODUCTION_MODE;
}

+ (BOOL)shouldDisplayWhatsNewScreen
{
    return shouldShowWhatsNewScreen;
}

+ (void)markShouldDisplayWhatsNewScreenTrue
{
    shouldShowWhatsNewScreen = YES;
}

+ (BOOL)shouldDisplayWelcomeScreen
{
    return shouldDisplayWelcomeScreen;
}

+ (void)markShouldDisplayWelcomeScreenTrue
{
    shouldDisplayWelcomeScreen = YES;
}

+ (BOOL)whatsNewMsgIsActuallyNew
{
    return whatsNewMsgIsNew;
}

+ (void)marksWhatsNewMsgAsNew
{
    whatsNewMsgIsNew = YES;
}

+ (BOOL)isFirstTimeAppLaunched
{
    return isFirstTimeAppLaunched;
}

+ (void)markAppAsLaunchedForFirstTime
{
    isFirstTimeAppLaunched = YES;
}

+ (BOOL)isTabBarHidden
{
    return tabBarIsHidden;
}
+ (void)setTabBarHidden:(BOOL)hidden
{
    tabBarIsHidden = hidden;
}


+ (BOOL)isUserEditingSongOrAlbumOrArtist
{
    return USER_EDITING_MEDIA;
}

+ (void)setUserIsEditingSongOrAlbumOrArtist:(BOOL)aValue
{
    USER_EDITING_MEDIA = aValue;
}

+ (BOOL)isUserPreviewingAVideo
{
    return userIsPreviewingAVideo;
}

+ (void)setUserIsPreviewingAVideo:(BOOL)aValue
{
    userIsPreviewingAVideo = aValue;
    if(! userIsPreviewingAVideo)
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Uninitialized];
}

+ (void)setCurrentPreviewPlayerState:(PREVIEW_PLAYBACK_STATE)state
{
    currentPreviewPlayerState = state;
}

+ (PREVIEW_PLAYBACK_STATE)currrentPreviewPlayerState
{
    return currentPreviewPlayerState;
}


static NSLock *playbackTimerLock;
+ (void)setPlaybackTimerActive:(BOOL)active onThreadNum:(NSInteger)threadNum
{
    [playbackTimerLock lock];
    
    playbackTimerActive = active;
    activePlaybackTimerThreadNum = threadNum;
    
    [playbackTimerLock unlock];
}

+ (BOOL)isPlaybackTimerActive
{
    return playbackTimerActive;
}

+ (NSInteger)threadNumOfPlaybackSleepTimerThreadWhichShouldFire
{
    return activePlaybackTimerThreadNum;
}


+ (PLABACK_REPEAT_MODE)playbackRepeatType
{
    return repeatType;
}

+ (void)setPlaybackRepeatType:(PLABACK_REPEAT_MODE)type
{
    repeatType = type;
}

+ (NSString *)stringRepresentationOfRepeatMode
{
    switch (repeatType)
    {
        case PLABACK_REPEAT_MODE_disabled:
            return @"Repeat Off";
            break;
        case PLABACK_REPEAT_MODE_Song:
            return @"Repeat Song";
        case PLABACK_REPEAT_MODE_All:
            return @"Repeat All";
        default:
            return @"";
            break;
    }
}

//fonts
+ (NSString *)regularFontName
{
    return @"Ubuntu";
}
+ (NSString *)boldFontName
{
    return @"Ubuntu-Bold";
}
+ (NSString *)italicFontName
{
    return @"Ubuntu-Italic";
}
+ (NSString *)boldItalicFontName
{
    return @"Ubuntu-BoldItalic";
}

//app settings
+ (int)preferredSongCellHeight
{
    return preferredSongCellHeight;
}
+ (void)setPreferredSongCellHeight:(int)cellHeight
{
    preferredSongCellHeight = cellHeight;
}
+ (int)minimumSongCellHeight
{
    return 49;
}
+ (int)maximumSongCellHeight
{
    return 115;
}
+ (int)defaultSongCellHeight
{
    return 60;
}

+ (short)preferredWifiStreamSetting
{
    return preferredWifiStreamValue;
}

+ (short)preferredCellularStreamSetting
{
    return preferredCellularStreamValue;
}

+ (void)setPreferredWifiStreamSetting:(short)resolutionValue
{
    preferredWifiStreamValue = resolutionValue;
}

+ (void)setPreferredCellularStreamSetting:(short)resolutionValue
{
    preferredCellularStreamValue = resolutionValue;
}

+ (BOOL)icloudSyncEnabled
{
    return icloudSyncEnabled;
}

+ (void)set_iCloudSyncEnabled:(BOOL)enabled
{
    icloudSyncEnabled = enabled;
}

+ (void)setAppTheme:(UIColor *)appThemeColor
{
    const CGFloat* components = CGColorGetComponents(appThemeColor.CGColor);
    NSNumber *red = [NSNumber numberWithFloat:components[0]];
    NSNumber *green = [NSNumber numberWithFloat:components[1]];
    NSNumber *blue = [NSNumber numberWithFloat:components[2]];
    NSNumber *alpha = [NSNumber numberWithFloat:components[3]];
    
    NSArray *defaultColorRepresentation = @[red, green, blue, alpha];
    [[NSUserDefaults standardUserDefaults] setObject:defaultColorRepresentation
                                              forKey:APP_THEME_COLOR_VALUE_KEY];
    
    [UIColor defaultAppColorScheme:appThemeColor];
    [AppDelegateSetupHelper setGlobalFontsAndColorsForAppGUIComponents];
}

+ (UIColor *)defaultAppThemeBeforeUserPickedTheme
{
    return Rgb2UIColor(240, 110, 50, 1);
}

+ (int)navBarHeight
{
    return navBarHeight;
}

+ (void)setNavBarHeight:(int)height
{
    navBarHeight = height;
}

+ (int)statusBarHeight
{
    return statusBarHeight;
}

+ (void)setStatusBarHeight:(int)height
{
    statusBarHeight = height;
}



//color stuff
+ (UIColor *)expandingCellGestureInitialColor
{
    return [UIColor lightGrayColor];
}

+ (UIColor *)expandingCellGestureQueueItemColor
{
    return Rgb2UIColor(114, 218, 58, 1);
}

+ (UIColor *)expandingCellGestureDeleteItemColor
{
    return Rgb2UIColor(255, 39, 39, 1);
}

+ (UIColor *)nowPlayingItemColor
{
    return [[UIColor defaultAppColorScheme] lighterColor];
}

@end
