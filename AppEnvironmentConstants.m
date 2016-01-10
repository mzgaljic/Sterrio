//
//  AppEnvironmentConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"
#import "AppDelegateSetupHelper.h"
#import "CoreDataManager.h"
#import "SDCAlertController.h"
#import "MusicPlaybackController.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <Valet/VALSynchronizableValet.h>

#define Rgb2UIColor(r, g, b, a)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]

@implementation AppEnvironmentConstants

static const BOOL PRODUCTION_MODE = YES;
static BOOL shouldShowWhatsNewScreen = NO;
static BOOL shouldDisplayWelcomeScreen = NO;
static BOOL isFirstTimeAppLaunched = NO;
static BOOL whatsNewMsgIsNew = NO;
static BOOL isBadTimeToMergeEnsemble = NO;
static BOOL userAcceptedOrDeclinedPushNotifications = NO;
static BOOL didPreviouslyShowUserCellularWarning = NO;
static BOOL userIsPreviewingAVideo = NO;
static BOOL tabBarIsHidden = NO;
static BOOL isIcloudSwitchWaitingForActionToComplete = NO;
static BOOL playbackTimerActive = NO;
static BOOL userSawExpandingPlayerTip = NO;
static NSDate *lastSuccessfulSyncDate;
static NSInteger activePlaybackTimerThreadNum;
static PLABACK_REPEAT_MODE repeatType;
static SHUFFLE_STATE shuffleState;
static PREVIEW_PLAYBACK_STATE currentPreviewPlayerState = PREVIEW_PLAYBACK_STATE_Uninitialized;

static int navBarHeight;
static int statusBarHeight;
static int bannerAdHeight;
static NSInteger lastPlayerViewIndex = NSNotFound;

static VALSynchronizableValet *adsKeychainItem;

//setting vars
static int preferredSongCellHeight;
static short preferredWifiStreamValue;
static short preferredCellularStreamValue;
static BOOL icloudSyncEnabled;
static BOOL shouldOnlyAirplayAudio;
//end of setting vars


//runtime configuration
+ (int)usersMajorIosVersion
{
    return [[[UIDevice currentDevice] systemVersion] intValue];
}

+ (BOOL)isUserOniOS8OrAbove
{
    // conditionally check for any version >= iOS 8 using 'isOperatingSystemAtLeastVersion'
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return YES;
    else
        return NO;
}

+ (BOOL)isUserOniOS9OrAbove
{
    if([AppEnvironmentConstants isUserOniOS8OrAbove]){
        NSOperatingSystemVersion ios9;
        ios9.majorVersion = 9;
        ios9.minorVersion = 0;
        ios9.patchVersion = 0;
        return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios9];
    }
    else
        return NO;
}


+ (BOOL)isUserCurrentlyOnCall
{    
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall *call in callCenter.currentCalls)  {
        if (call.callState == CTCallStateConnected) {
            return YES;
        }
    }
    return NO;
}

+ (void)recordIndexOfPlayerView:(NSUInteger)index
{
    lastPlayerViewIndex = index;
}

+ (NSUInteger)lastIndexOfPlayerView
{
    return lastPlayerViewIndex;
}


+ (BOOL)isAppInProductionMode
{
    return PRODUCTION_MODE;
}

+ (BOOL)shouldDisplayWhatsNewScreen
{
    return shouldShowWhatsNewScreen;
}

+ (void)markShouldDisplayWhatsNewScreenTrue
{
    shouldShowWhatsNewScreen = YES;
}

+ (BOOL)shouldDisplayWelcomeScreen
{
    return shouldDisplayWelcomeScreen;
}

+ (void)markShouldDisplayWelcomeScreenTrue
{
    shouldDisplayWelcomeScreen = YES;
}

+ (BOOL)whatsNewMsgIsActuallyNew
{
    return whatsNewMsgIsNew;
}

+ (void)marksWhatsNewMsgAsNew
{
    whatsNewMsgIsNew = YES;
}

+ (BOOL)isFirstTimeAppLaunched
{
    return isFirstTimeAppLaunched;
}

+ (void)markAppAsLaunchedForFirstTime
{
    isFirstTimeAppLaunched = YES;
}

+ (BOOL)isTabBarHidden
{
    return tabBarIsHidden;
}
+ (void)setTabBarHidden:(BOOL)hidden
{
    tabBarIsHidden = hidden;
}


+ (BOOL)isABadTimeToMergeEnsemble
{
    return isBadTimeToMergeEnsemble;
}
+ (void)setIsBadTimeToMergeEnsemble:(BOOL)aValue
{
    isBadTimeToMergeEnsemble = aValue;
}

+ (BOOL)isUserPreviewingAVideo
{
    return userIsPreviewingAVideo;
}

+ (void)setUserIsPreviewingAVideo:(BOOL)aValue
{
    userIsPreviewingAVideo = aValue;
    if(! userIsPreviewingAVideo)
        [AppEnvironmentConstants setCurrentPreviewPlayerState:PREVIEW_PLAYBACK_STATE_Uninitialized];
}

+ (void)setCurrentPreviewPlayerState:(PREVIEW_PLAYBACK_STATE)state
{
    currentPreviewPlayerState = state;
}

+ (PREVIEW_PLAYBACK_STATE)currrentPreviewPlayerState
{
    return currentPreviewPlayerState;
}


static NSLock *playbackTimerLock;
+ (void)setPlaybackTimerActive:(BOOL)active onThreadNum:(NSInteger)threadNum
{
    [playbackTimerLock lock];
    
    playbackTimerActive = active;
    activePlaybackTimerThreadNum = threadNum;
    
    [playbackTimerLock unlock];
}

+ (BOOL)isPlaybackTimerActive
{
    return playbackTimerActive;
}

+ (NSInteger)threadNumOfPlaybackSleepTimerThreadWhichShouldFire
{
    return activePlaybackTimerThreadNum;
}


+ (PLABACK_REPEAT_MODE)playbackRepeatType
{
    return repeatType;
}

+ (void)setPlaybackRepeatType:(PLABACK_REPEAT_MODE)type
{
    repeatType = type;
}

+ (SHUFFLE_STATE)shuffleState
{
    return shuffleState;
}

+ (void)setShuffleState:(SHUFFLE_STATE)state
{
    shuffleState = state;
}

+ (NSString *)stringRepresentationOfRepeatMode
{
    switch (repeatType)
    {
        case PLABACK_REPEAT_MODE_disabled:
            return @"Repeat Off";
            break;
        case PLABACK_REPEAT_MODE_Song:
            return @"Repeat Song";
        case PLABACK_REPEAT_MODE_All:
            return @"Repeat All";
        default:
            return @"";
            break;
    }
}

+ (NSString *)stringRepresentationOfShuffleState
{
    switch (shuffleState)
    {
        case SHUFFLE_STATE_Disabled:
            return @"Shuffle Off";
            break;
        case SHUFFLE_STATE_Enabled:
            return @"Shuffle";
        default:
            break;
    }
}

//fonts
+ (NSString *)regularFontName
{
    return @"Ubuntu";
}
+ (NSString *)boldFontName
{
    return @"Ubuntu-Bold";
}
+ (NSString *)italicFontName
{
    return @"Ubuntu-Italic";
}
+ (NSString *)boldItalicFontName
{
    return @"Ubuntu-BoldItalic";
}


static NSString *const areAdsRemovedKeychainKey = @"ads removed yet?";
+ (void)adsHaveBeenRemoved:(BOOL)adsRemoved
{
    if(adsKeychainItem == nil) {
        adsKeychainItem = [[VALSynchronizableValet alloc] initWithIdentifier:ARE_ADS_REMOVED_KEYCHAIN_ID
                                                               accessibility:VALAccessibilityAfterFirstUnlock];
    }
    
    int boolAsInt = [[NSNumber numberWithBool:adsRemoved] intValue];
    NSData *data = [NSData dataWithBytes:&boolAsInt length:sizeof(boolAsInt)];
    [adsKeychainItem setObject:data forKey:areAdsRemovedKeychainKey];
}
+ (BOOL)areAdsRemoved
{
    if(adsKeychainItem == nil) {
        adsKeychainItem = [[VALSynchronizableValet alloc] initWithIdentifier:ARE_ADS_REMOVED_KEYCHAIN_ID
                                                               accessibility:VALAccessibilityAfterFirstUnlock];
    }
    
    NSData *data = [adsKeychainItem objectForKey:areAdsRemovedKeychainKey];
    int boolAsInt;
    if(data == nil) {
        return NO;
    }
    [data getBytes:&boolAsInt length:sizeof(boolAsInt)];
    return [[NSNumber numberWithInt:boolAsInt] boolValue];
}
+ (void)setUserSawExpandingPlayerTip:(BOOL)userSawIt
{
    [[NSUserDefaults standardUserDefaults] setBool:userSawIt
                                            forKey:USER_SAW_EXPANDING_PLAYER_TIP_VALUE_KEY];
    userSawExpandingPlayerTip = userSawIt;
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+ (BOOL)userSawExpandingPlayerTip
{
    return userSawExpandingPlayerTip;
}
+ (BOOL)userAcceptedOrDeclinedPushNotifications
{
    return userAcceptedOrDeclinedPushNotifications;
}
+ (void)userAcceptedOrDeclinedPushNotif:(BOOL)something
{
    [[NSUserDefaults standardUserDefaults] setBool:something
                                            forKey:USER_HAS_ACCEPTED_OR_DECLINED_PUSH_NOTIF];
    userAcceptedOrDeclinedPushNotifications = something;
    [[NSUserDefaults standardUserDefaults] synchronize];
}
//app settings  --these are saved in nsuserdefaults once user leaves settings page.
+ (int)preferredSongCellHeight
{
    return preferredSongCellHeight;
}
+ (void)setPreferredSongCellHeight:(int)cellHeight
{
    preferredSongCellHeight = cellHeight;
}
+ (int)minimumSongCellHeight
{
    return 49;
}
+ (int)maximumSongCellHeight
{
    return 115;
}
+ (int)defaultSongCellHeight
{
    return 50;
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

+ (void)setShouldOnlyAirplayAudio:(BOOL)airplayAudio
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    shouldOnlyAirplayAudio = airplayAudio;
    if(shouldOnlyAirplayAudio)
        player.allowsExternalPlayback = NO;
    else
        player.allowsExternalPlayback = YES;
}

+ (BOOL)shouldOnlyAirplayAudio
{
    return shouldOnlyAirplayAudio;
}

+ (void)setUserHasSeenCellularDataUsageWarning:(BOOL)hasSeen
{
    [[NSUserDefaults standardUserDefaults] setBool:hasSeen
                                            forKey:USER_HAS_SEEN_CELLULAR_WARNING];
    didPreviouslyShowUserCellularWarning = hasSeen;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)didPreviouslyShowUserCellularWarning
{
    return didPreviouslyShowUserCellularWarning;
}

+ (BOOL)icloudSyncEnabled
{
    return icloudSyncEnabled;
}

+ (BOOL)isIcloudSwitchWaitingForActionToFinish
{
    return isIcloudSwitchWaitingForActionToComplete;
}

static int icloudEnabledCounter = 0;
+ (void)set_iCloudSyncEnabled:(BOOL)enabled
{
    icloudEnabledCounter++;
    if(icloudEnabledCounter != 1){
        //the icloud switch is disabled from touches (in interface) until the action
        //succeeds or fails.
        isIcloudSwitchWaitingForActionToComplete = YES;
    }

    if(enabled)
        [AppEnvironmentConstants tryToLeechMainContextEnsemble];
    else
        [AppEnvironmentConstants tryToDeleechMainContextEnsemble];
    
    icloudSyncEnabled = enabled;
}

+ (void)tryToDeleechMainContextEnsemble
{
    CDEPersistentStoreEnsemble *ensemble =[[CoreDataManager sharedInstance] ensembleForMainContext];
    if(! ensemble.isLeeched){
        isIcloudSwitchWaitingForActionToComplete = NO;
        return;
    }
    
    [ensemble deleechPersistentStoreWithCompletion:^(NSError *error) {
        if(error)
        {
            //could not de-leech
            NSString *message = @"A problem occured disabling iCloud sync.";
            SDCAlertController *alert = [SDCAlertController alertControllerWithTitle:@"iCloud"
                                                                             message:message
                                                                      preferredStyle:SDCAlertControllerStyleAlert];
            SDCAlertAction *ok = [SDCAlertAction actionWithTitle:@"OK"
                                                           style:SDCAlertActionStyleDefault
                                                         handler:^(SDCAlertAction *action) {
                                                             [AppEnvironmentConstants notifyThatIcloudSyncFailedToDisable];
                                                         }];
            SDCAlertAction *tryAgain = [SDCAlertAction actionWithTitle:@"Try Again"
                                                                 style:SDCAlertActionStyleRecommended
                                                               handler:^(SDCAlertAction *action) {
                                                                   [AppEnvironmentConstants tryToDeleechMainContextEnsemble];
                                                               }];
            [alert addAction:ok];
            [alert addAction:tryAgain];
            [alert performSelectorOnMainThread:@selector(presentWithCompletion:)
                                    withObject:nil
                                 waitUntilDone:NO];
            
            NSLog(@"De-leeched ensemble failed.");
        }
        else
        {
            [AppEnvironmentConstants notifyThatIcloudSyncSuccessfullyDisabled];
            NSLog(@"De-leeched ensemble successfuly");
        }
        
        isIcloudSwitchWaitingForActionToComplete = NO;
    }];
}

+ (void)tryToLeechMainContextEnsemble
{
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    if(ensemble.isLeeched){
        isIcloudSwitchWaitingForActionToComplete = NO;
        return;
    }
    
    [ensemble leechPersistentStoreWithCompletion:^(NSError *error) {
        if(error)
        {
            //could not leech
            NSString *message = @"A problem occured enabling iCloud sync.";
            SDCAlertController *alert = [SDCAlertController alertControllerWithTitle:@"iCloud"
                                                                             message:message
                                                                      preferredStyle:SDCAlertControllerStyleAlert];
            SDCAlertAction *ok = [SDCAlertAction actionWithTitle:@"OK"
                                                           style:SDCAlertActionStyleDefault
                                                         handler:^(SDCAlertAction *action) {
                                                             [AppEnvironmentConstants notifyThatIcloudSyncFailedToEnable];
                                                         }];
            SDCAlertAction *tryAgain = [SDCAlertAction actionWithTitle:@"Try Again"
                                                                 style:SDCAlertActionStyleRecommended
                                                               handler:^(SDCAlertAction *action) {
                                                                   [AppEnvironmentConstants tryToLeechMainContextEnsemble];
                                                               }];
            [alert addAction:ok];
            [alert addAction:tryAgain];
            [alert performSelectorOnMainThread:@selector(presentWithCompletion:)
                                    withObject:nil
                                 waitUntilDone:NO];
            
            NSLog(@"Leeching ensemble failed.");
        }
        else
        {
            [AppEnvironmentConstants notifyThatIcloudSyncSuccessfullyEnabled];
            NSLog(@"Leeched ensemble successfuly");
            
            //now lets go the extra mile and try to merge here.
            CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
            [ensemble mergeWithCompletion:^(NSError *error) {
                if(error){
                    NSLog(@"Leeched successfully, but couldnt merge.");
                } else{
                    NSLog(@"Just merged successfully.");
                    [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                }
            }];
        }
        
        isIcloudSwitchWaitingForActionToComplete = NO;
    }];
}

+ (void)setLastSuccessfulSyncDate:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:LAST_SUCCESSFUL_ICLOUD_SYNC_KEY];
    lastSuccessfulSyncDate = date;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDate *)lastSuccessfulSyncDate
{
    return lastSuccessfulSyncDate;
}

//returns a date in a nice user readable format, such as "Yesterday at 1:15 PM".
+ (NSString *)humanReadableLastSyncTime
{
    if(lastSuccessfulSyncDate == nil)
        return nil;
    
    //if any of these cases are true, use that instead of the date AND time.
    NSTimeInterval secs = [[[NSDate alloc] init] timeIntervalSinceDate:lastSuccessfulSyncDate];
    if(secs < 60){
        return @"Just Now";
    } else if(secs < 3600){
        int minutesAgo = secs/60;
        if(minutesAgo == 1)
            return @"a minute ago";
        else
            return [NSString stringWithFormat:@"%i minutes ago", minutesAgo];
    }
    
    //otherwise just show date and time in a pretty format.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    if([self isUserUsingMilitaryTime])
        [timeFormatter setDateFormat:@"HH:mm"];
    else
        [timeFormatter setDateFormat:@"h:mm a"];
    
    NSString *prettyDateString = [dateFormatter stringFromDate:lastSuccessfulSyncDate];
    NSString *timeString = [timeFormatter stringFromDate:lastSuccessfulSyncDate];
    
    return [NSString stringWithFormat:@"%@ at %@", prettyDateString, timeString];
}

//helper for above method
+ (BOOL)isUserUsingMilitaryTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    return is24h;
}

#pragma mark - Notifying user interface about success or failure of icloud operations.
+ (void)notifyThatIcloudSyncFailedToEnable
{
    icloudSyncEnabled = NO;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOnIcloudFailed object:nil];
    }];
}

+ (void)notifyThatIcloudSyncFailedToDisable
{
    icloudSyncEnabled = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOffIcloudFailed object:nil];
    }];
}

+ (void)notifyThatIcloudSyncSuccessfullyEnabled
{
    icloudSyncEnabled = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOnIcloudSuccess object:nil];
    }];
}

+ (void)notifyThatIcloudSyncSuccessfullyDisabled
{
    icloudSyncEnabled = NO;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOffIcloudSuccess object:nil];
    }];
}

+ (void)setAppTheme:(UIColor *)appThemeColor
{
    const CGFloat* components = CGColorGetComponents(appThemeColor.CGColor);
    NSNumber *red = [NSNumber numberWithFloat:components[0]];
    NSNumber *green = [NSNumber numberWithFloat:components[1]];
    NSNumber *blue = [NSNumber numberWithFloat:components[2]];
    NSNumber *alpha = [NSNumber numberWithFloat:components[3]];
    
    NSArray *defaultColorRepresentation = @[red, green, blue, alpha];
    [[NSUserDefaults standardUserDefaults] setObject:defaultColorRepresentation
                                              forKey:APP_THEME_COLOR_VALUE_KEY];
    
    [UIColor defaultAppColorScheme:appThemeColor];
    [AppDelegateSetupHelper setGlobalFontsAndColorsForAppGUIComponents];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UIColor *)defaultAppThemeBeforeUserPickedTheme
{
    return Rgb2UIColor(240, 110, 50, 1);
}

+ (int)navBarHeight
{
    return navBarHeight;
}

+ (void)setNavBarHeight:(int)height
{
    navBarHeight = height;
}

+ (int)statusBarHeight
{
    return statusBarHeight;
}

+ (int)regularStatusBarHeightPortrait  //the non-expanded height
{
    return 20;
}

+ (void)setStatusBarHeight:(int)height
{
    statusBarHeight = height;
}

+ (void)setBannerAdHeight:(int)height
{
    bannerAdHeight = height;
}

+ (int)bannerAdHeight
{
    return bannerAdHeight;
}



//color stuff
+ (UIColor *)expandingCellGestureInitialColor
{
    return [UIColor lightGrayColor];
}

+ (UIColor *)expandingCellGestureQueueItemColor
{
    return Rgb2UIColor(114, 218, 58, 1);
}

+ (UIColor *)expandingCellGestureDeleteItemColor
{
    return Rgb2UIColor(255, 39, 39, 1);
}

+ (UIColor *)nowPlayingItemColor
{
    return [[UIColor defaultAppColorScheme] lighterColor];
}

+ (NSArray *)appThemeColors
{
    return  @[
              //orange
              [AppEnvironmentConstants defaultAppThemeBeforeUserPickedTheme],
              
              //green
              [Rgb2UIColor(74, 153, 118, 1) darkerColor],
              
              //pink
              [Rgb2UIColor(233, 91, 152, 1) lighterColor],
              
              //blue
              Rgb2UIColor(57, 104, 190, 1),
              
              //purple
              Rgb2UIColor(111, 91, 164, 1),
              
              //yellow
              Rgb2UIColor(254, 200, 45, 1)
              ];
}

@end
