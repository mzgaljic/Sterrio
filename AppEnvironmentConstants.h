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
#define PREFERRED_SONG_CELL_HEIGHT_KEY @"preferredSongCellHeight"
#define PREFERRED_WIFI_VALUE_KEY @"preferredWifiStreamValue"
#define PREFERRED_CELL_VALUE_KEY @"preferredCellularStreamValue"
#define APP_THEME_COLOR_VALUE_KEY @"appThemeColorValue"
#define ICLOUD_SYNC @"icloudSettingsSync"
#define ONLY_AIRPLAY_AUDIO_VALUE_KEY @"shouldOnlyAirplayAudio"
#define USER_HAS_SEEN_CELLULAR_WARNING @"alreadyShowedUserCellDataUsageWarning"
#define LAST_SUCCESSFUL_ICLOUD_SYNC_KEY @"last date icloud synced"

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

typedef enum{
    SHUFFLE_STATE_Disabled,
    SHUFFLE_STATE_Enabled
} SHUFFLE_STATE;

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

//possibly useful stuff to use to avoid merging ensemble during editing.
+ (BOOL)isABadTimeToMergeEnsemble;
+ (void)setIsBadTimeToMergeEnsemble:(BOOL)aValue;

+ (BOOL)isUserPreviewingAVideo;
+ (void)setUserIsPreviewingAVideo:(BOOL)aValue;
+ (void)setCurrentPreviewPlayerState:(PREVIEW_PLAYBACK_STATE)state;
+ (PREVIEW_PLAYBACK_STATE)currrentPreviewPlayerState;


+ (void)setPlaybackTimerActive:(BOOL)active onThreadNum:(NSInteger)threadNum;
+ (BOOL)isPlaybackTimerActive;
+ (NSInteger)threadNumOfPlaybackSleepTimerThreadWhichShouldFire;

+ (PLABACK_REPEAT_MODE)playbackRepeatType;
+ (void)setPlaybackRepeatType:(PLABACK_REPEAT_MODE)type;
+ (SHUFFLE_STATE)shuffleState;
+ (void)setShuffleState:(SHUFFLE_STATE)state;
+ (NSString *)stringRepresentationOfRepeatMode;
+ (NSString *)stringRepresentationOfShuffleState;

//fonts
+ (NSString *)regularFontName;
+ (NSString *)boldFontName;
+ (NSString *)italicFontName;
+ (NSString *)boldItalicFontName;

//---Stuff in NSUserDefaults----

//----app settings---
+ (int)preferredSongCellHeight;
+ (void)setPreferredSongCellHeight:(int)cellHeight;
+ (int)minimumSongCellHeight;
+ (int)maximumSongCellHeight;
+ (int)defaultSongCellHeight;

+ (short)preferredWifiStreamSetting;
+ (short)preferredCellularStreamSetting;
+ (void)setPreferredWifiStreamSetting:(short)resolutionValue;
+ (void)setPreferredCellularStreamSetting:(short)resolutionValue;

+ (BOOL)isIcloudSwitchWaitingForActionToFinish;
+ (BOOL)icloudSyncEnabled;
+ (void)set_iCloudSyncEnabled:(BOOL)enabled;

+ (void)setShouldOnlyAirplayAudio:(BOOL)airplayAudio;
+ (BOOL)shouldOnlyAirplayAudio;

+ (void)setUserHasSeenCellularDataUsageWarning:(BOOL)hasSeen;
+ (BOOL)didPreviouslyShowUserCellularWarning;

+ (void)setAppTheme:(UIColor *)appTheme;
//-----End of app settings------

+ (void)setLastSuccessfulSyncDate:(NSDate *)date;
+ (NSString *)humanReadableLastSyncTime;
//---End of stuff in NSUserDefaults---


//Other stuff
+ (UIColor *)defaultAppThemeBeforeUserPickedTheme;

+ (int)navBarHeight;
+ (void)setNavBarHeight:(int)height;
+ (int)statusBarHeight;
+ (void)setStatusBarHeight:(int)height;

+ (UIColor *)expandingCellGestureInitialColor;
+ (UIColor *)expandingCellGestureQueueItemColor;
+ (UIColor *)expandingCellGestureDeleteItemColor;

+ (UIColor *)nowPlayingItemColor;

@end
