//
//  AppEnvironmentConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//
#define APP_ALREADY_LAUNCHED_KEY @"AppLaunchedAlready"
#define LAST_INSTALLED_BUILD @"lastInstalledBuild"
#define LAST_WhatsNewMsg @"lastSavedWhatsNewMsg"  //prevents displaying a msg twice by accident
//settings keys
#define PREFERRED_SIZE_KEY @"preferredSizeValue"
#define PREFERRED_WIFI_VALUE_KEY @"preferredWifiStreamValue"
#define PREFERRED_CELL_VALUE_KEY @"preferredCellularStreamValue"
#define BOLD_NAME @"boldName"
#define SMART_SORT @"smartAlphabeticalSort"
#define ICLOUD_SYNC @"icloudSettingsSync"

#import <Foundation/Foundation.h>

//states of the preview player
typedef enum {
    PREVIEW_PLAYBACK_STATE_Uninitialized,
    PREVIEW_PLAYBACK_STATE_Playing,
    PREVIEW_PLAYBACK_STATE_Paused
} PREVIEW_PLAYBACK_STATE;

typedef enum{
    PLABACK_REPEAT_MODE_disabled,
    PLABACK_REPEAT_MODE_Song,
    PLABACK_REPEAT_MODE_All
} PLABACK_REPEAT_MODE;

@interface AppEnvironmentConstants : NSObject

//runtime configuration
+ (BOOL)isUserOniOS8OrAbove;

/**
 Returns YES if the user is currently on a phone call
 */
+ (BOOL)isUserCurrentlyOnCall;

+ (void)recordIndexOfPlayerView:(NSUInteger)index;
+ (NSUInteger)lastIndexOfPlayerView;

+ (BOOL)shouldDisplayWhatsNewScreen;
+ (void)markShouldDisplayWhatsNewScreenTrue;

+ (BOOL)shouldDisplayWelcomeScreen;
+ (void)markShouldDisplayWelcomeScreenTrue;

//used to avoid accidentally shipping an app with the same whats new message (and displaying it again)
+ (BOOL)whatsNewMsgIsActuallyNew;
+ (void)marksWhatsNewMsgAsNew;

+ (BOOL)isAppInProductionMode;
+ (BOOL)isFirstTimeAppLaunched;
+ (void)markAppAsLaunchedForFirstTime;

+ (BOOL)isTabBarHidden;
+ (void)setTabBarHidden:(BOOL)hidden;

+ (BOOL)isUserEditingSongOrAlbumOrArtist;
+ (void)setUserIsEditingSongOrAlbumOrArtist:(BOOL)aValue;

+ (BOOL)isUserPreviewingAVideo;
+ (void)setUserIsPreviewingAVideo:(BOOL)aValue;
+ (void)setCurrentPreviewPlayerState:(PREVIEW_PLAYBACK_STATE)state;
+ (PREVIEW_PLAYBACK_STATE)currrentPreviewPlayerState;


+ (void)setPlaybackTimerActive:(BOOL)active onThreadNum:(NSInteger)threadNum;
+ (BOOL)isPlaybackTimerActive;
+ (NSInteger)threadNumOfPlaybackSleepTimerThreadWhichShouldFire;

+ (PLABACK_REPEAT_MODE)playbackRepeatType;
+ (void)setPlaybackRepeatType:(PLABACK_REPEAT_MODE)type;
+ (NSString *)stringRepresentationOfRepeatMode;

//fonts
+ (NSString *)regularFontName;
+ (NSString *)boldFontName;
+ (NSString *)italicFontName;
+ (NSString *)boldItalicFontName;

//app settings
+ (short)preferredSizeSetting;
+ (void)setPreferredSizeSetting:(short)numUpToFive;

+ (short)preferredWifiStreamSetting;
+ (short)preferredCellularStreamSetting;
+ (void)setPreferredWifiStreamSetting:(short)resolutionValue;
+ (void)setPreferredCellularStreamSetting:(short)resolutionValue;

+ (BOOL)boldNames;
+ (void)setBoldNames:(BOOL)yesOrNo;

+ (BOOL)smartAlphabeticalSort;
+ (void)setSmartAlphabeticalSort:(BOOL)yesOrNo;

+ (BOOL)icloudSettingsSync;
+ (void)set_iCloudSettingsSync:(BOOL)yesOrNo;

+ (int)navBarHeight;
+ (void)setNavBarHeight:(int)height;
+ (int)statusBarHeight;
+ (void)setStatusBarHeight:(int)height;

+ (UIColor *)expandingCellGestureInitialColor;
+ (UIColor *)expandingCellGestureQueueItemColor;
+ (UIColor *)expandingCellGestureDeleteItemColor;

+ (UIColor *)nowPlayingItemColor;

@end
