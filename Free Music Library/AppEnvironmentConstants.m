//
//  AppEnvironmentConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@implementation AppEnvironmentConstants

static const BOOL PRODUCTION_MODE = YES;
static BOOL shouldShowWhatsNewScreen = NO;
static BOOL shouldDisplayWelcomeScreen = NO;
static BOOL isFirstTimeAppLaunched = NO;
static BOOL whatsNewMsgIsNew = NO;
static BOOL USER_EDITING_MEDIA = YES;
static BOOL userIsPreviewingAVideo = NO;
static PREVIEW_PLAYBACK_STATE currentPreviewPlayerState = PREVIEW_PLAYBACK_STATE_Uninitialized;

static short preferredSizeValue;
static short preferredWifiStreamValue;
static short preferredCellularStreamValue;
static BOOL boldName;
static BOOL smartAlphabeticalSort;
static BOOL icloudSettingsSync;

static int navBarHeight;
static short statusBarHeight;

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

//app settings
+ (short)preferredSizeSetting
{
    return preferredSizeValue;
}

//integer between [1,6]
+ (void)setPreferredSizeSetting:(short)numUpToSix
{
    [[NSUserDefaults standardUserDefaults] setInteger:numUpToSix forKey:PREFERRED_SIZE_KEY];
    if(numUpToSix <= 6 && numUpToSix > 0)
        preferredSizeValue = numUpToSix;
    else{
        NSLog(@"Font Size setting has become corrupt, setting default value.");
        preferredSizeValue = 3;
        return;
    }
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
    [[NSUserDefaults standardUserDefaults] setInteger:resolutionValue forKey:PREFERRED_WIFI_VALUE_KEY];
    preferredWifiStreamValue = resolutionValue;
}

+ (void)setPreferredCellularStreamSetting:(short)resolutionValue
{
    [[NSUserDefaults standardUserDefaults] setInteger:resolutionValue forKey:PREFERRED_CELL_VALUE_KEY];
    preferredCellularStreamValue = resolutionValue;
}

+ (BOOL)boldNames
{
    return boldName;
}

+ (void)setBoldNames:(BOOL)yesOrNo
{
    [[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:BOLD_NAME];
    boldName = yesOrNo;
}

+ (BOOL)smartAlphabeticalSort
{
    return smartAlphabeticalSort;
}

+ (void)setSmartAlphabeticalSort:(BOOL)yesOrNo
{
    [[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:SMART_SORT];
    smartAlphabeticalSort = yesOrNo;
}

+ (BOOL)icloudSettingsSync
{
    return icloudSettingsSync;
}

+ (void)set_iCloudSettingsSync:(BOOL)yesOrNo
{
    [[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:ICLOUD_SYNC];
    icloudSettingsSync = yesOrNo;
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
    return Rgb2UIColor(114, 218, 58);
}

+ (UIColor *)expandingCellGestureDeleteItemColor
{
    return Rgb2UIColor(255, 39, 39);
}

@end
