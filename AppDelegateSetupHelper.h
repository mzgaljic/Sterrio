//
//  AppDelegateSetupHelper.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppEnvironmentConstants.h"

@interface AppDelegateSetupHelper : NSObject

+ (void)loadUsersSettingsFromNSUserDefaults;
+ (void)setGlobalFontsAndColorsForAppGUIComponents;
+ (void)logGlobalAppTintColor;

+ (void)reduceEncryptionStrengthOnRelevantDirs __attribute__((deprecated));
+ (void)setupDiskAndMemoryWebCache;
+ (BOOL)appLaunchedFirstTime;

@end
