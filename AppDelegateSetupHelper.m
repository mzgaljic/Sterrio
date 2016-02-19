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
        BOOL userSawExpandingPlayerTip = NO;
        BOOL userHasSeenCellDataWarning = NO;
        BOOL userAcceptedOrDeclinedPushNotif = NO;
        BOOL userRatedMyApp = NO;
        
        [AppEnvironmentConstants setPreferredSongCellHeight:prefSongCellHeight];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:prefWifiStreamQuality];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:prefCellStreamQuality];
        [AppEnvironmentConstants set_iCloudSyncEnabled:icloudSync];
        [AppEnvironmentConstants setUserHasSeenCellularDataUsageWarning:userHasSeenCellDataWarning];
        [AppEnvironmentConstants setShouldOnlyAirplayAudio:shouldOnlyAirplayAudio];
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
        
        UIColor *color = [AppEnvironmentConstants defaultAppThemeBeforeUserPickedTheme];
        const CGFloat* components = CGColorGetComponents(color.CGColor);
        NSNumber *red = [NSNumber numberWithDouble:components[0]];
        NSNumber *green = [NSNumber numberWithDouble:components[1]];
        NSNumber *blue = [NSNumber numberWithDouble:components[2]];
        NSNumber *alpha = [NSNumber numberWithDouble:components[3]];
        NSArray *defaultColorRepresentation = @[red, green, blue, alpha];
        [standardDefaults setObject:defaultColorRepresentation
                             forKey:APP_THEME_COLOR_VALUE_KEY];
        [UIColor defaultAppColorScheme:color];
        
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
                        [standardDefaults boolForKey:ICLOUD_SYNC]];
        [AppEnvironmentConstants setShouldOnlyAirplayAudio:
                        [standardDefaults boolForKey:ONLY_AIRPLAY_AUDIO_VALUE_KEY]];
        [AppEnvironmentConstants setUserHasSeenCellularDataUsageWarning:
                        [standardDefaults boolForKey:USER_HAS_SEEN_CELLULAR_WARNING]];
        [AppEnvironmentConstants userAcceptedOrDeclinedPushNotif:
                        [standardDefaults boolForKey:USER_HAS_ACCEPTED_OR_DECLINED_PUSH_NOTIF]];
        [AppEnvironmentConstants setLastSuccessfulSyncDate:
                        [standardDefaults objectForKey:LAST_SUCCESSFUL_ICLOUD_SYNC_KEY]];
        [AppEnvironmentConstants setUserSawExpandingPlayerTip:[standardDefaults boolForKey:USER_SAW_EXPANDING_PLAYER_TIP_VALUE_KEY]];
        
        //I manually retrieve App color from NSUserDefaults
        NSArray *defaultColorRep2 = [standardDefaults objectForKey:APP_THEME_COLOR_VALUE_KEY];
        UIColor *usersChosenDefaultColor = [UIColor colorWithRed:[defaultColorRep2[0] doubleValue]
                                                           green:[defaultColorRep2[1] doubleValue]
                                                            blue:[defaultColorRep2[2] doubleValue]
                                                           alpha:[defaultColorRep2[3] doubleValue]];
        [UIColor defaultAppColorScheme:usersChosenDefaultColor];
    }
}

+ (void)setGlobalFontsAndColorsForAppGUIComponents
{
    //set global default "AppColorScheme"
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.tintColor = [UIColor whiteColor];
    
    //cancel button color of all uisearchbars
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil]
     setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             [[UIColor defaultAppColorScheme] lighterColor],NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    
    //tab bar font
    UIFont *tabBarFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                         size:10];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:tabBarFont, NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    UIFont *barButtonFonts = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:17];
    NSDictionary *barButtonAttributes = @{
                                          NSForegroundColorAttributeName : [UIColor defaultWindowTintColor],
                                          NSFontAttributeName : barButtonFonts
                                          };
    
    //toolbar button colors
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]
     setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             [[UIColor defaultAppColorScheme] lighterColor],
                             NSForegroundColorAttributeName,
                             barButtonFonts, NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    //nav bar attributes
    UIFont *navBarFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:20];
    NSDictionary *navBarTitleAttributes = @{
                                            NSForegroundColorAttributeName : [UIColor defaultWindowTintColor],
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

//used for debugging
+ (void)logGlobalAppTintColor
{
    UIColor *uicolor = [UIColor defaultAppColorScheme];
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
