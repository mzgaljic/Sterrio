//
//  AppDelegateSetupHelper.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegateSetupHelper.h"

@implementation AppDelegateSetupHelper
static BOOL PRODUCTION_MODE;

+ (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

+ (void)setAppSettingsAppLaunchedFirstTime:(BOOL)firstTime
{
    if(firstTime){
        //these are the default settings
        short sizeSetting = 3;
        BOOL boldNames = YES;
        short prefWifiStreamQuality = 720;
        short prefCellStreamQuality = 360;
        #warning should be YES in release version
        BOOL smartSort = YES;
        BOOL icloudSync = NO;
        [AppEnvironmentConstants setPreferredSizeSetting:sizeSetting];
        [AppEnvironmentConstants setBoldNames:boldNames];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:prefWifiStreamQuality];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:prefCellStreamQuality];
        [AppEnvironmentConstants setSmartAlphabeticalSort:smartSort];
        [AppEnvironmentConstants set_iCloudSettingsSync:icloudSync];
        
        [[NSUserDefaults standardUserDefaults] setInteger:sizeSetting
                                                   forKey:PREFERRED_SIZE_KEY];
        [[NSUserDefaults standardUserDefaults] setBool:boldNames
                                                forKey:BOLD_NAME];
        [[NSUserDefaults standardUserDefaults] setInteger:prefWifiStreamQuality
                                                   forKey:PREFERRED_WIFI_VALUE_KEY];
        [[NSUserDefaults standardUserDefaults] setInteger:prefCellStreamQuality
                                                   forKey:PREFERRED_CELL_VALUE_KEY];
        [[NSUserDefaults standardUserDefaults] setBool:smartSort
                                                forKey:SMART_SORT];
        [[NSUserDefaults standardUserDefaults] setBool:icloudSync
                                                forKey:ICLOUD_SYNC];
    } else{
        //load users last settings from disk before setting these values.
        [AppEnvironmentConstants setPreferredSizeSetting:
                        [[NSUserDefaults standardUserDefaults] integerForKey:PREFERRED_SIZE_KEY]];
        [AppEnvironmentConstants setBoldNames:
                        [[NSUserDefaults standardUserDefaults] boolForKey:BOLD_NAME]];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:
                        [[NSUserDefaults standardUserDefaults] integerForKey:PREFERRED_WIFI_VALUE_KEY]];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:
                        [[NSUserDefaults standardUserDefaults] integerForKey:PREFERRED_CELL_VALUE_KEY]];
        [AppEnvironmentConstants setSmartAlphabeticalSort:
                        [[NSUserDefaults standardUserDefaults] boolForKey:SMART_SORT]];
        [AppEnvironmentConstants set_iCloudSettingsSync:
                        [[NSUserDefaults standardUserDefaults] boolForKey:ICLOUD_SYNC]];
    }
}

+ (void)logGlobalAppTintColor
{
    UIColor *uicolor = [UIColor defaultSystemTintColor];
    CGColorRef color = [uicolor CGColor];
    int numComponents = (int)CGColorGetNumberOfComponents(color);
    if (numComponents == 4)
    {
        const CGFloat *components = CGColorGetComponents(color);
        CGFloat red = components[0] *255;
        CGFloat green = components[1]*255;
        CGFloat blue = components[2]*255;
        CGFloat alpha = components[3];
        NSLog(@"Default RGB tint color:\nred:%f, green:%f, blue:%f, alpha:%f", red, green, blue, alpha);
    }
}


@end
