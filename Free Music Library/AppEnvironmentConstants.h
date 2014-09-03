//
//  AppEnvironmentConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//
#define APP_ALREADY_LAUNCHED_KEY @"AppLaunchedAlready"
//settings keys
#define PREFERRED_SIZE_KEY @"preferredSizeValue"
#define PREFERRED_WIFI_VALUE_KEY @"preferredWifiStreamValue"
#define PREFERRED_CELL_VALUE_KEY @"preferredCellularStreamValue"
#define BOLD_NAME @"boldName"
#define SMART_SORT @"smartAlphabeticalSort"
#define ICLOUD_SYNC @"icloudSettingsSync"

#import <Foundation/Foundation.h>

@interface AppEnvironmentConstants : NSObject

+ (BOOL)isAppInProductionMode;

+ (BOOL)hasSongBeenPlayedSinceLaunch;
+ (void)setSongHasBeenPlayedSinceLaunch;

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

@end
