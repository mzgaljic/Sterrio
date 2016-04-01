//
//  AppDelegateSetupHelper.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegateSetupHelper.h"
#import "AppDelegate.h"
#import "Song.h"
#import "Album.h"
#import "Playlist.h"
#import "Artist.h"
#import "UIDevice+DeviceName.h"
#import "SDWebImageManager.h"
#import "UIColor+LighterAndDarker.h"
#import "MZAppTheme.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]


@implementation AppDelegateSetupHelper

+ (void)loadUsersSettingsFromNSUserDefaults
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    if([AppDelegateSetupHelper appLaunchedFirstTime]){
        //these are the default settings
        int prefSongCellHeight = [AppEnvironmentConstants defaultSongCellHeight];
        short prefWifiStreamQuality = 720;
        short prefCellStreamQuality = 240;
        BOOL icloudSync = NO;
        BOOL shouldOnlyAirplayAudio = YES;
        BOOL limitVideoLengthOnCellular = YES;
        BOOL userSawExpandingPlayerTip = NO;
        BOOL userHasSeenCellDataWarning = NO;
        BOOL userAcceptedOrDeclinedPushNotif = NO;
        BOOL userRatedMyApp = NO;
        
        [AppEnvironmentConstants setPreferredSongCellHeight:prefSongCellHeight];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:prefWifiStreamQuality];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:prefCellStreamQuality];
        [AppEnvironmentConstants set_iCloudSyncEnabled:icloudSync
                                       tryToBlindlySet:YES];
        [AppEnvironmentConstants setUserHasSeenCellularDataUsageWarning:userHasSeenCellDataWarning];
        [AppEnvironmentConstants setShouldOnlyAirplayAudio:shouldOnlyAirplayAudio];
        [AppEnvironmentConstants setLimitVideoLengthOnCellular:limitVideoLengthOnCellular];
        [AppEnvironmentConstants setUserSawExpandingPlayerTip:userSawExpandingPlayerTip];
        [AppEnvironmentConstants setUserHasRatedMyApp:userRatedMyApp];
        
        [standardDefaults setInteger:prefSongCellHeight
                              forKey:PREFERRED_SONG_CELL_HEIGHT_KEY];
        [standardDefaults setInteger:prefWifiStreamQuality
                              forKey:PREFERRED_WIFI_VALUE_KEY];
        [standardDefaults setInteger:prefCellStreamQuality
                              forKey:PREFERRED_CELL_VALUE_KEY];
        [standardDefaults setInteger:[AppEnvironmentConstants usersMajorIosVersion]
                              forKey:USERS_LAST_KNOWN_MAJOR_IOS_VERS_VALUE_KEY];
        [standardDefaults setBool:icloudSync
                           forKey:ICLOUD_SYNC];
        [standardDefaults setBool:userHasSeenCellDataWarning
                           forKey:USER_HAS_SEEN_CELLULAR_WARNING];
        [standardDefaults setBool:userAcceptedOrDeclinedPushNotif
                           forKey:USER_HAS_ACCEPTED_OR_DECLINED_PUSH_NOTIF];
        [standardDefaults setBool:shouldOnlyAirplayAudio
                           forKey:ONLY_AIRPLAY_AUDIO_VALUE_KEY];
        [standardDefaults setBool:limitVideoLengthOnCellular
                           forKey:LIMIT_VIDEO_LENGTH_CELLULAR_VALUE_KEY];
        [standardDefaults setObject:[NSNumber numberWithInteger:1] forKey:NUM_TIMES_APP_LAUNCHED];
        
        MZAppTheme *appTheme = [MZAppTheme defaultAppThemeBeforeUserPickedTheme];
        [AppEnvironmentConstants setAppTheme:appTheme saveInUserDefaults:NO];
        [standardDefaults setObject:[appTheme nsUserDefaultsCompatibleDictFromTheme]
                             forKey:[MZAppTheme nsUserDefaultsKeyAppThemeDict]];
        [standardDefaults synchronize];
    } else{
        //load users last settings from disk before setting these values.
        [AppEnvironmentConstants setPreferredSongCellHeight:(int)
                        [standardDefaults integerForKey:PREFERRED_SONG_CELL_HEIGHT_KEY]];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:
                        [standardDefaults integerForKey:PREFERRED_WIFI_VALUE_KEY]];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:
                        [standardDefaults integerForKey:PREFERRED_CELL_VALUE_KEY]];
        [AppEnvironmentConstants set_iCloudSyncEnabled:
                        [standardDefaults boolForKey:ICLOUD_SYNC] tryToBlindlySet:YES];
        [AppEnvironmentConstants setShouldOnlyAirplayAudio:
                        [standardDefaults boolForKey:ONLY_AIRPLAY_AUDIO_VALUE_KEY]];
        [AppEnvironmentConstants setLimitVideoLengthOnCellular:
                        [standardDefaults boolForKey:LIMIT_VIDEO_LENGTH_CELLULAR_VALUE_KEY]];
        [AppEnvironmentConstants setUserHasSeenCellularDataUsageWarning:
                        [standardDefaults boolForKey:USER_HAS_SEEN_CELLULAR_WARNING]];
        [AppEnvironmentConstants userAcceptedOrDeclinedPushNotif:
                        [standardDefaults boolForKey:USER_HAS_ACCEPTED_OR_DECLINED_PUSH_NOTIF]];
        [AppEnvironmentConstants setLastSuccessfulSyncDate:
                        [standardDefaults objectForKey:LAST_SUCCESSFUL_ICLOUD_SYNC_KEY]];
        [AppEnvironmentConstants setUserSawExpandingPlayerTip:[standardDefaults boolForKey:USER_SAW_EXPANDING_PLAYER_TIP_VALUE_KEY]];
        
        NSDictionary *dict = [standardDefaults objectForKey:[MZAppTheme nsUserDefaultsKeyAppThemeDict]];
        MZAppTheme *appTheme = [[MZAppTheme alloc] initWithNsUserDefaultsCompatibleDict:dict];
        [AppEnvironmentConstants setAppTheme:appTheme saveInUserDefaults:NO];
        
        //increment and set NUM_TIMES_APP_LAUNCHED
        NSNumber *numTimesAppLaunched = [standardDefaults objectForKey:NUM_TIMES_APP_LAUNCHED];
        numTimesAppLaunched = @([numTimesAppLaunched longLongValue] + 1);
        [standardDefaults setObject:numTimesAppLaunched forKey:NUM_TIMES_APP_LAUNCHED];
        [standardDefaults synchronize];
    }
}

+ (void)setGlobalFontsAndColorsForAppGUIComponents
{
    //set global default "AppColorScheme"
    MZAppTheme *appTheme = [AppEnvironmentConstants appTheme];
    UIColor *textOrNavBarTint = appTheme.contrastingTextOrNavBarTint;
    UIColor *mainColor = appTheme.mainGuiTint;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.tintColor = textOrNavBarTint;
    
    //cancel button color of all uisearchbars
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             mainColor,NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    
    //tab bar font
    UIFont *tabBarFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                         size:10];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:tabBarFont, NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    UIFont *barButtonFonts = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:17];
    NSDictionary *barButtonAttributes = @{
                                          NSForegroundColorAttributeName : textOrNavBarTint,
                                          NSFontAttributeName : barButtonFonts
                                          };
    
    //toolbar button colors
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]
     setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             textOrNavBarTint,
                             NSForegroundColorAttributeName,
                             barButtonFonts, NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    //nav bar attributes
    UIFont *navBarFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:20];
    NSDictionary *navBarTitleAttributes = @{
                                            NSForegroundColorAttributeName : textOrNavBarTint,
                                            NSFontAttributeName : navBarFont
                                            };
    [[UINavigationBar appearance] setTitleTextAttributes:navBarTitleAttributes];
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAttributes
                                                forState:UIControlStateNormal];
    //search bar cancel button font
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:@{NSFontAttributeName:barButtonFonts} forState:UIControlStateNormal];
    
    //particulary useful for alert views.
    [[UITextField appearance] setTintColor:[UIColor darkGrayColor]];
}

/*
 The Album Art dir must have an encryption level of
 NSFileProtectionCompleteUntilFirstUserAuthentication, otherwise the images for the lockscreen
 will not be able to load. */
+ (void)reduceEncryptionStrengthOnRelevantDirs
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //now set documents dir encryption to a weaker value
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:documentsPath error:nil]];
    [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
}

+ (void)setupDiskAndMemoryWebCache
{
    [[SDImageCache sharedImageCache] setMaxCacheSize:4000000];  //4 mb cache size
    int cacheSizeMemory = 4 * 1024 * 1024;  //4MB
    int cacheSizeDisk = 15 * 1024 * 1024;  //15MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory
                                                            diskCapacity:cacheSizeDisk
                                                                diskPath:[AppDelegateSetupHelper obtainNSURLCachePath]];
    [NSURLCache setSharedURLCache:sharedCache];
}

+ (NSString *)obtainNSURLCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dirPath = [documentsDirectory stringByAppendingPathComponent:@"NSURL Cache"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dirPath]){
        NSArray *keys = [NSArray arrayWithObjects:NSFileProtectionKey, nil];
        NSArray *objects = [NSArray arrayWithObjects: NSFileProtectionCompleteUntilFirstUserAuthentication, nil];
        NSDictionary *permission = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        
        //Create folder with weaker encryption
        [fileManager createDirectoryAtPath:dirPath
               withIntermediateDirectories:YES
                                attributes:permission
                                     error:nil];
    }
    return dirPath;
}

static short appLaunchedFirstTimeNumCalls = 0;
+ (BOOL)appLaunchedFirstTime
{
    //this counter helps us prevent the code beneath from being executed more than once per app launch.
    //doing so would cause the "whats new screen" to be messed up...displayed at wrong times.
    if(appLaunchedFirstTimeNumCalls > 0)
        return [AppEnvironmentConstants isFirstTimeAppLaunched];
    appLaunchedFirstTimeNumCalls++;
    
    //determining whether or not the app has been launched for the first time
    NSString *lastBuild = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_INSTALLED_BUILD];
    NSString *currentBuild = [UIDevice appBuildString];
    if(lastBuild == nil){
        [[NSUserDefaults standardUserDefaults] setObject:currentBuild
                                                  forKey:LAST_INSTALLED_BUILD];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [AppEnvironmentConstants markAppAsLaunchedForFirstTime];
        [AppEnvironmentConstants markShouldDisplayWelcomeScreenTrue];
        return YES;
    } else if(! [lastBuild isEqualToString:currentBuild]){
        [AppEnvironmentConstants markShouldDisplayWhatsNewScreenTrue];
        return NO;
    } else {
        return NO;
    }
}

@end
