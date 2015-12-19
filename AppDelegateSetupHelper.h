//
//  AppDelegateSetupHelper.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppEnvironmentConstants.h"

static const short APP_LAUNCHED_ALREADY = 1;
static const short APP_LAUNCHED_FIRST_TIME = 0;

@interface AppDelegateSetupHelper : NSObject

+ (void)loadUsersSettingsFromNSUserDefaults;
+ (void)setGlobalFontsAndColorsForAppGUIComponents;
+ (void)logGlobalAppTintColor;

+ (void)reduceEncryptionStrengthOnRelevantDirs __attribute__((deprecated));
+ (void)setupDiskAndMemoryWebCache;
+ (BOOL)appLaunchedFirstTime;

+ (void)changeRootViewController:(UIViewController*)viewController forWindow:(UIWindow *)window;

@end
