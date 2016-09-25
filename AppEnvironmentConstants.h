//
//  AppEnvironmentConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

//settings keys
#define PREFERRED_SONG_CELL_HEIGHT_KEY @"preferredSongCellHeight"
#define PREFERRED_WIFI_VALUE_KEY @"preferredWifiStreamValue"
#define PREFERRED_CELL_VALUE_KEY @"preferredCellularStreamValue"
#define USERS_LAST_KNOWN_MAJOR_IOS_VERS_VALUE_KEY @"the users last known major ios version number"
#define USER_SAW_EXPANDING_PLAYER_TIP_VALUE_KEY @"user already saw the swipe up gesture tips"
#define ICLOUD_SYNC @"icloudSettingsSync"
#define ONLY_AIRPLAY_AUDIO_VALUE_KEY @"shouldOnlyAirplayAudio"
#define LIMIT_VIDEO_LENGTH_CELLULAR_VALUE_KEY @"limit length of videos when on LTE/3G"
#define USER_HAS_SEEN_CELLULAR_WARNING @"alreadyShowedUserCellDataUsageWarning"
#define USER_HAS_ACCEPTED_OR_DECLINED_PUSH_NOTIF @"userHasAcceptedOrDeclinedPushNotif"
#define LAST_SUCCESSFUL_ICLOUD_SYNC_KEY @"last date icloud synced"
#define ARE_ADS_REMOVED_KEYCHAIN_ID @"Have ads been removed?"
#define NUM_TIMES_APP_LAUNCHED @"numberOfTimesAppLaunched"  //on just this device.
#define NUM_TIMES_SONG_ADDED_TO_LIB @"numberOfTimesSongAddedToLib"  //on just this device.
#define HIGHEST_TOS_VERSION_ACCEPTED @"highest vers of the terms of service user agreed to." //on just this device.

#import <Foundation/Foundation.h>
#import "MZAppTheme.h"

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
+ (int)usersMajorIosVersion;
+ (BOOL)isUserOniOS9OrHigher;
+ (BOOL)isUserOniOS10OrHigher;

/**
 Returns YES if the user is currently on a phone call
 */
+ (BOOL)isUserCurrentlyOnCall;

+ (BOOL)shouldDisplayWelcomeScreen;
+ (void)markShouldDisplayWelcomeScreenTrue;

+ (BOOL)hasUserRatedApp;
+ (void)setUserHasRatedMyApp:(BOOL)userDidRateApp;

+ (BOOL)isFirstTimeAppLaunched;
+ (void)markAppAsLaunchedForFirstTime;

+ (NSNumber *)numberTimesUserLaunchedApp;

+ (NSNumber *)numberTimesUserAddedSongToLib;
+ (void)incrementNumTimesUserAddedSongToLibCount;

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
+ (NSString *)stringRepresentationOfRepeatMode;
+ (NSString *)stringRepresentationOfShuffleState:(SHUFFLE_STATE)state;

//fonts
+ (NSString *)regularFontName;
+ (NSString *)boldFontName;
+ (NSString *)italicFontName;


//---Stuff in Keychain---
+ (void)adsHaveBeenRemoved:(BOOL)adsRemoved;
+ (BOOL)areAdsRemoved;
//---End of stuff in Keychain---

//---Stuff in NSUserDefaults----
+ (void)setUserSawExpandingPlayerTip:(BOOL)userSawIt;
+ (BOOL)userSawExpandingPlayerTip;
+ (BOOL)userAcceptedOrDeclinedPushNotifications;
+ (void)userAcceptedOrDeclinedPushNotif:(BOOL)something;
+ (void)setHighestTosVersionUserAccepted:(NSNumber *)tosVersion updateNsDefaults:(BOOL)update;
+ (NSNumber *)highestTosVersionUserAccepted;
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
+ (void)set_iCloudSyncEnabled:(BOOL)enabled tryToBlindlySet:(BOOL)blindySet;

+ (void)setShouldOnlyAirplayAudio:(BOOL)airplayAudio;
+ (BOOL)shouldOnlyAirplayAudio;

+ (void)setLimitVideoLengthOnCellular:(BOOL)limit;
+ (BOOL)limitVideoLengthOnCellular;

+ (void)setUserHasSeenCellularDataUsageWarning:(BOOL)hasSeen;
+ (BOOL)didPreviouslyShowUserCellularWarning;

+ (void)setAppTheme:(MZAppTheme *)appTheme saveInUserDefaults:(BOOL)save;
+ (MZAppTheme *)appTheme;
//-----End of app settings------

+ (void)setLastSuccessfulSyncDate:(NSDate *)date;
+ (NSDate *)lastSuccessfulSyncDate;
+ (NSString *)humanReadableLastSyncTime;
//---End of stuff in NSUserDefaults---


//Other stuff
+ (int)navBarHeight;
+ (int)statusBarHeight;
+ (int)regularStatusBarHeightPortrait;  //the non-expanded height
+ (void)setStatusBarHeight:(int)height;
+ (void)setBannerAdHeight:(int)height;
+ (int)bannerAdHeight;
+ (UIImage *)navBarBackgroundImageWithoutGradientFromFrame:(CGRect)frame; //only use when absolutely necessary
+ (UIImage *)navBarBackgroundImageFromFrame:(CGRect)frame;
+ (BOOL)isAppStoreBuild;
+ (NSString *)testingAdMobDeviceId;

@end
