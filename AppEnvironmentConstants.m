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

@implementation AppEnvironmentConstants

static MZAppTheme *currentAppTheme;

static BOOL shouldShowWhatsNewScreen = NO;
static BOOL shouldDisplayWelcomeScreen = NO;
static BOOL isFirstTimeAppLaunched = NO;
static BOOL isBadTimeToMergeEnsemble = NO;
static BOOL userAcceptedOrDeclinedPushNotifications = NO;
static BOOL didPreviouslyShowUserCellularWarning = NO;
static BOOL userIsPreviewingAVideo = NO;
static BOOL limitVideoLengthOnCellular = NO;
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

static VALSynchronizableValet *adsKeychainItem;
static VALSynchronizableValet *storeRatingKeychainItem;

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

static BOOL userOnIos9OrAboveCached = NO;
+ (BOOL)isUserOniOS9OrAbove
{
    if(userOnIos9OrAboveCached) {
        return YES;
    }
    NSOperatingSystemVersion ios9;
    ios9.majorVersion = 9;
    ios9.minorVersion = 0;
    ios9.patchVersion = 0;
    userOnIos9OrAboveCached = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios9];
    return userOnIos9OrAboveCached;
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


//app rating is stored in keychain with VALSynchronizableValet so that the data is easily
//stored in icloud.
static NSString *USER_HAS_RATED_APP_KEY = @"mzUserRatedCurrentVersion";
static BOOL userRatedAppCachedVal = NO;
static BOOL didFetchAppRatedKeychainVal = NO;
+ (BOOL)hasUserRatedApp
{
    if(didFetchAppRatedKeychainVal) {
        return userRatedAppCachedVal;
    }
    
    if(storeRatingKeychainItem == nil) {
        storeRatingKeychainItem = [[VALSynchronizableValet alloc] initWithIdentifier:USER_HAS_RATED_APP_KEY
                                                               accessibility:VALAccessibilityAfterFirstUnlock];
    }
    
    NSData *data = [storeRatingKeychainItem objectForKey:USER_HAS_RATED_APP_KEY];
    didFetchAppRatedKeychainVal = YES;
    int boolAsInt;
    if(data == nil) {
        userRatedAppCachedVal = NO;
        return userRatedAppCachedVal;
    }
    [data getBytes:&boolAsInt length:sizeof(boolAsInt)];
    userRatedAppCachedVal = [[NSNumber numberWithInt:boolAsInt] boolValue];
    return userRatedAppCachedVal;
}
+ (void)setUserHasRatedMyApp:(BOOL)userDidRateApp
{
    if(storeRatingKeychainItem == nil) {
        storeRatingKeychainItem = [[VALSynchronizableValet alloc] initWithIdentifier:USER_HAS_RATED_APP_KEY
                                                               accessibility:VALAccessibilityAfterFirstUnlock];
    }
    
    int boolAsInt = [[NSNumber numberWithBool:userDidRateApp] intValue];
    NSData *data = [NSData dataWithBytes:&boolAsInt length:sizeof(boolAsInt)];
    [storeRatingKeychainItem setObject:data forKey:USER_HAS_RATED_APP_KEY];
    userRatedAppCachedVal = userDidRateApp;
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

+ (BOOL)isFirstTimeAppLaunched
{
    return isFirstTimeAppLaunched;
}

+ (void)markAppAsLaunchedForFirstTime
{
    isFirstTimeAppLaunched = YES;
}

static NSNumber *numTimesAppLaunched = nil;
+ (NSNumber *)numberTimesUserLaunchedApp
{
    if(numTimesAppLaunched) {
        return numTimesAppLaunched;
    }
    numTimesAppLaunched = [[NSUserDefaults standardUserDefaults] objectForKey:NUM_TIMES_APP_LAUNCHED];
    return numTimesAppLaunched;
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
static NSString *regularFontName = nil;
static NSString *boldFontName = nil;
static NSString *italicFontName = nil;
+ (NSString *)regularFontName
{
    if(regularFontName == nil) {
        regularFontName = [[UIFont systemFontOfSize:10] fontName];
    }
    return regularFontName;
}
+ (NSString *)boldFontName
{
    if(boldFontName == nil) {
        boldFontName = [[UIFont boldSystemFontOfSize:10] fontName];
    }
    return boldFontName;
}
+ (NSString *)italicFontName
{
    if(italicFontName == nil) {
        italicFontName = [[UIFont italicSystemFontOfSize:10] fontName];
    }
    return italicFontName;
}


static NSString *const areAdsRemovedKeychainKey = @"ads removed yet?";
static BOOL areAdsRemovedCachedVal = NO;
static BOOL didFetchAreAdsRemovedKeychainVal = NO;
+ (void)adsHaveBeenRemoved:(BOOL)adsRemoved
{
    if(adsKeychainItem == nil) {
        adsKeychainItem = [[VALSynchronizableValet alloc] initWithIdentifier:ARE_ADS_REMOVED_KEYCHAIN_ID
                                                               accessibility:VALAccessibilityAfterFirstUnlock];
    }
    
    int boolAsInt = [[NSNumber numberWithBool:adsRemoved] intValue];
    NSData *data = [NSData dataWithBytes:&boolAsInt length:sizeof(boolAsInt)];
    [adsKeychainItem setObject:data forKey:areAdsRemovedKeychainKey];
    areAdsRemovedCachedVal = adsRemoved;
}
+ (BOOL)areAdsRemoved
{
    if(didFetchAreAdsRemovedKeychainVal) {
        return areAdsRemovedCachedVal;
    }
    if(adsKeychainItem == nil) {
        adsKeychainItem = [[VALSynchronizableValet alloc] initWithIdentifier:ARE_ADS_REMOVED_KEYCHAIN_ID
                                                               accessibility:VALAccessibilityAfterFirstUnlock];
    }
    
    NSData *data = [adsKeychainItem objectForKey:areAdsRemovedKeychainKey];
    didFetchAreAdsRemovedKeychainVal = YES;
    int boolAsInt;
    if(data == nil) {
        areAdsRemovedCachedVal = NO;
        return areAdsRemovedCachedVal;
    }
    [data getBytes:&boolAsInt length:sizeof(boolAsInt)];
    areAdsRemovedCachedVal = [[NSNumber numberWithInt:boolAsInt] boolValue];
    return areAdsRemovedCachedVal;
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
    return 58;
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

+ (void)setLimitVideoLengthOnCellular:(BOOL)limit
{
    limitVideoLengthOnCellular = limit;
}

+ (BOOL)limitVideoLengthOnCellular
{
    return limitVideoLengthOnCellular;
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

static NSLock *icloudSwitchWaitingForActionToFinishLock;
+ (BOOL)isIcloudSwitchWaitingForActionToFinish
{
    BOOL retVal;
    [icloudSwitchWaitingForActionToFinishLock lock];
    retVal = isIcloudSwitchWaitingForActionToComplete;
    [icloudSwitchWaitingForActionToFinishLock unlock];
    return retVal;
}

static NSLock *icloudSyncEnabledLock;
+ (BOOL)icloudSyncEnabled
{
    BOOL retVal;
    [icloudSyncEnabledLock lock];
    retVal = icloudSyncEnabled;
    [icloudSyncEnabledLock unlock];
    return retVal;
}

//blindlySet should only be used when loading settings from disk.
+ (void)set_iCloudSyncEnabled:(BOOL)enabled tryToBlindlySet:(BOOL)blindySet
{
    if(blindySet) {
        [icloudSyncEnabledLock lock];
        icloudSyncEnabled = enabled;
        [icloudSyncEnabledLock unlock];
        return;
    }
    
    //the icloud switch is disabled from touches (in interface) until the action
    //succeeds or fails.
    [icloudSwitchWaitingForActionToFinishLock lock];
    isIcloudSwitchWaitingForActionToComplete = YES;
    [icloudSwitchWaitingForActionToFinishLock unlock];

    if(enabled)
        [AppEnvironmentConstants tryToLeechMainContextEnsemble];
    else
        [AppEnvironmentConstants tryToDeleechMainContextEnsemble];
    
    [icloudSyncEnabledLock lock];
    icloudSyncEnabled = enabled;
    [icloudSyncEnabledLock unlock];
}

+ (void)tryToDeleechMainContextEnsemble
{
    CDEPersistentStoreEnsemble *ensemble =[[CoreDataManager sharedInstance] ensembleForMainContext];
    if(! ensemble.isLeeched){
        [icloudSwitchWaitingForActionToFinishLock lock];
        isIcloudSwitchWaitingForActionToComplete = NO;
        [icloudSwitchWaitingForActionToFinishLock unlock];
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
                                                             [AppEnvironmentConstants notifyThatAppsIcloudStateChanged];
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
            [AppEnvironmentConstants notifyThatAppsIcloudStateChanged];
            NSLog(@"De-leeched ensemble successfuly");
        }
    }];
}

+ (void)tryToLeechMainContextEnsemble
{
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    if(ensemble.isLeeched){
        [icloudSwitchWaitingForActionToFinishLock lock];
        isIcloudSwitchWaitingForActionToComplete = NO;
        [icloudSwitchWaitingForActionToFinishLock unlock];
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
                                                             [AppEnvironmentConstants notifyThatAppsIcloudStateChanged];
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
                //notifying here because the reciever of the notification cares about the last
                //successful sync date (set above)
                [AppEnvironmentConstants notifyThatAppsIcloudStateChanged];
            }];
        }
    }];
}

static NSLock *lastSuccessfulSyncDateLock;
+ (void)setLastSuccessfulSyncDate:(NSDate *)date
{
    [lastSuccessfulSyncDateLock lock];
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:LAST_SUCCESSFUL_ICLOUD_SYNC_KEY];
    lastSuccessfulSyncDate = date;
    [[NSUserDefaults standardUserDefaults] synchronize];
    [lastSuccessfulSyncDateLock unlock];
}

+ (NSDate *)lastSuccessfulSyncDate
{
    NSDate *retVal;
    [lastSuccessfulSyncDateLock lock];
    retVal = lastSuccessfulSyncDate;
    [lastSuccessfulSyncDateLock unlock];
    return retVal;
}

//returns a date in a nice user readable format, such as "Yesterday at 1:15 PM".
+ (NSString *)humanReadableLastSyncTime
{
    if(lastSuccessfulSyncDate == nil
       || [AppEnvironmentConstants isIcloudSwitchWaitingForActionToFinish])
        return nil;
    
    //if any of these cases are true, use that instead of the date AND time.
    NSDate *threadSafeLastSyncDate = [AppEnvironmentConstants lastSuccessfulSyncDate];
    NSTimeInterval secs = [[[NSDate alloc] init] timeIntervalSinceDate:threadSafeLastSyncDate];
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
    
    NSString *prettyDateString = [dateFormatter stringFromDate:threadSafeLastSyncDate];
    NSString *timeString = [timeFormatter stringFromDate:threadSafeLastSyncDate];
    
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
    [icloudSyncEnabledLock lock];
    icloudSyncEnabled = NO;
    [icloudSyncEnabledLock unlock];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOnIcloudFailed object:nil];
    }];
}

+ (void)notifyThatIcloudSyncFailedToDisable
{
    [icloudSyncEnabledLock lock];
    icloudSyncEnabled = YES;
    [icloudSyncEnabledLock unlock];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOffIcloudFailed object:nil];
    }];
}

+ (void)notifyThatIcloudSyncSuccessfullyEnabled
{
    [icloudSyncEnabledLock lock];
    icloudSyncEnabled = YES;
    [icloudSyncEnabledLock unlock];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOnIcloudSuccess object:nil];
    }];
}

+ (void)notifyThatIcloudSyncSuccessfullyDisabled
{
    [icloudSyncEnabledLock lock];
    icloudSyncEnabled = NO;
    [icloudSyncEnabledLock unlock];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZTurningOffIcloudSuccess object:nil];
    }];
}

//called to basically say "hey, the GUI should re-query the icloud state of the app".
+ (void)notifyThatAppsIcloudStateChanged
{
    [icloudSwitchWaitingForActionToFinishLock lock];
    isIcloudSwitchWaitingForActionToComplete = NO;
    [icloudSwitchWaitingForActionToFinishLock unlock];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZIcloudSyncStateHasChanged
                                                            object:nil];
    }];
}


#pragma mark - Other GUI junk
+ (void)setAppTheme:(MZAppTheme *)appTheme saveInUserDefaults:(BOOL)save
{
    currentAppTheme = appTheme;
    [AppDelegateSetupHelper setGlobalFontsAndColorsForAppGUIComponents];
    if(save) {
        NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        [standardDefaults setObject:[appTheme nsUserDefaultsCompatibleDictFromTheme]
                             forKey:[MZAppTheme nsUserDefaultsKeyAppThemeDict]];
        [standardDefaults synchronize];
    }
}

+ (MZAppTheme *)appTheme
{
    return currentAppTheme;
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

+ (UIImage *)navBarBackgroundImageFromFrame:(CGRect)frame
{
    UIColor *mainBarBackgroundBackground = [AppEnvironmentConstants appTheme].mainGuiTint;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, frame.size.width, frame.size.height + [AppEnvironmentConstants statusBarHeight]);
    gradient.colors = @[(id)[mainBarBackgroundBackground CGColor],
                        (id)[[mainBarBackgroundBackground lighterColor] CGColor]];
    UIImage *navBarImage = [AppEnvironmentConstants imageFromLayer:gradient];
    return navBarImage;
}

+ (UIImage *)imageFromLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, 0);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

@end
