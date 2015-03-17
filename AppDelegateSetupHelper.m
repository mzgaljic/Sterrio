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
        [[NSUserDefaults standardUserDefaults] synchronize];
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

/*The Album Art dir must have an encryption level of
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

static short appLaunchedFirstTimeDefensiveCount = 0;
+ (BOOL)appLaunchedFirstTime
{
    //this counter helps us prevent the code beneath from being executed more than once per app launch.
    //doing so would cause the "whats new screen" to be messed up...displayed at wrong times.
    if(appLaunchedFirstTimeDefensiveCount > 0)
        return [AppEnvironmentConstants isFirstTimeAppLaunched];
    appLaunchedFirstTimeDefensiveCount++;
    
    //determine if "whats new" constant in this build is actually new.
    NSString *lastWhatsNewMsg = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_WhatsNewMsg];
    if(lastWhatsNewMsg == nil)
        [AppEnvironmentConstants marksWhatsNewMsgAsNew];
    else{
        if(! [lastWhatsNewMsg isEqualToString:MZWhatsNewUserMsg])
            [AppEnvironmentConstants marksWhatsNewMsgAsNew];
    }
    [[NSUserDefaults standardUserDefaults] setObject:MZWhatsNewUserMsg
                                              forKey:LAST_WhatsNewMsg];
    
    //determining whether or not "whats new" screen should be shown on this run of the app
    NSString *lastBuild = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_INSTALLED_BUILD];
    NSString *currentBuild = [UIDevice appBuildString];
    if(lastBuild == nil){
        [[NSUserDefaults standardUserDefaults] setObject:currentBuild
                                                  forKey:LAST_INSTALLED_BUILD];
    } else if(! [lastBuild isEqualToString:currentBuild] &&
              [AppEnvironmentConstants whatsNewMsgIsActuallyNew]){
        [AppEnvironmentConstants markShouldDisplayWhatsNewScreenTrue];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger code = [[NSUserDefaults standardUserDefaults] integerForKey:APP_ALREADY_LAUNCHED_KEY];
    if(code == APP_LAUNCHED_FIRST_TIME){
        
        //I want to only display one or the either, never the same on. Placement of this
        //if must stay exactly here, placement matters!
        if(! [AppEnvironmentConstants shouldDisplayWhatsNewScreen])
            [AppEnvironmentConstants markShouldDisplayWelcomeScreenTrue];
        
        [AppEnvironmentConstants markAppAsLaunchedForFirstTime];
        return YES;
    }
    else
        return NO;
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
