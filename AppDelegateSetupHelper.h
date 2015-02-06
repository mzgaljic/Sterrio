//
//  AppDelegateSetupHelper.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppEnvironmentConstants.h"
#import "Song.h"
#import "Album.h"
#import "Playlist.h"
#import "Artist.h"
#import "UIDevice+DeviceName.h"

static const short APP_LAUNCHED_ALREADY = 1;
static const short APP_LAUNCHED_FIRST_TIME = 0;

@interface AppDelegateSetupHelper : NSObject

+ (void)setAppSettingsAppLaunchedFirstTime:(BOOL)firstTime;
+ (void)logGlobalAppTintColor;

+ (void)reduceEncryptionStrengthOnRelevantDirs;
+ (BOOL)appLaunchedFirstTime;

@end
