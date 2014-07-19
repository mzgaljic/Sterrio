//
//  AppEnvironmentConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppEnvironmentConstants.h"

@implementation AppEnvironmentConstants

static const BOOL PRODUCTION_MODE = NO;
static short preferredSizeValue;
static short preferredWifiStreamValue;
static short preferredCellularStreamValue;
static BOOL boldSongName;
static BOOL smartAlphabeticalSort;
static BOOL icloudSettingsSync;

+ (BOOL)isAppInProductionMode
{
    return PRODUCTION_MODE;
}

//app settings
+ (short)preferredSizeSetting
{
    return preferredSizeValue;
}

+ (void)setPreferredSizeSetting:(short)numUpToSix
{
    if(numUpToSix <= 6 && numUpToSix > 0)
        preferredSizeValue = numUpToSix;
    else{
        NSLog(@"Font Size setting problem, received an invalid size value!");
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
    preferredWifiStreamValue = resolutionValue;
}

+ (void)setPreferredCellularStreamSetting:(short)resolutionValue
{
    preferredCellularStreamValue = resolutionValue;
}

+ (BOOL)boldSongNames
{
    return boldSongName;
}

+ (void)setBoldSongNames:(BOOL)yesOrNo
{
    boldSongName = yesOrNo;
}

+ (BOOL)smartAlphabeticalSort
{
    return smartAlphabeticalSort;
}

+ (void)setSmartAlphabeticalSort:(BOOL)yesOrNo
{
    smartAlphabeticalSort = yesOrNo;
}

+ (BOOL)icloudSettingsSync
{
    return icloudSettingsSync;
}

+ (void)set_iCloudSettingsSync:(BOOL)yesOrNo
{
    icloudSettingsSync = yesOrNo;
}

@end
