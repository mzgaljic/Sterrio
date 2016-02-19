//
//  MyAlerts.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAlerts.h"
#import "PreferredFontSizeUtility.h"
#import "SongPlayerCoordinator.h"
#import "UIColor+LighterAndDarker.h"
#import "UIImage+colorImages.h"
#import "UIWindow+VisibleVC.h"
#import "SDCAlertControllerView.h"
#import "PlayableItem.h"
#import "PreviousNowPlayingInfo.h"
#import <CRToast.h>

@implementation MyAlerts

static BOOL currentlyDisplayingBanner;
static NSMutableArray *queuedToastBannerOptions;

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(queuedToastBannerOptions == nil)
            queuedToastBannerOptions = [NSMutableArray array];
        [MyAlerts runDisplayAlertCodeWithAlertType:type];
    }];
}

+ (void)retryPlayingCurrentSong
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        Song *nowPlayingSong = [NowPlayingSong sharedInstance].nowPlayingItem.songForItem;
        PlayableItem *oldItem = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading];
        [VideoPlayerWrapper startPlaybackOfSong:nowPlayingSong
                                   goingForward:YES
                                oldPlayableItem:oldItem];
    }];
}

+ (void)runDisplayAlertCodeWithAlertType:(ALERT_TYPE)type
{
    switch (type) {
        case ALERT_TYPE_CannotConnectToYouTube:
        {
            //alert user to internet problem
            NSString *title = @"Internet Connection";
            NSString *msg = @"Could not connect to YouTube.";

            SDCAlertAction *retry = [SDCAlertAction actionWithTitle:@"Try Again"
                                                              style:SDCAlertActionStyleRecommended
                                                            handler:^(SDCAlertAction *action) {
                                                                [MyAlerts retryPlayingCurrentSong];
                                                            }];
            SDCAlertAction *ok = [SDCAlertAction actionWithTitle:@"OK"
                                                           style:SDCAlertActionStyleDefault
                                                         handler:nil];
            
            //actions in array will appear in the same order in the alert on screen...
            NSArray *actions = @[ok, retry];
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                    customActions:actions
                           allowsBasicLocalNotif:YES];
            break;
        }
        case ALERT_TYPE_CannotLoadVideo:
        {
            NSString *msg = @"Video failed to load.";
            [self launchAlertViewWithDialogTitle:nil
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES];
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            NSDictionary *options = @{
                                      kCRToastTextKey : @"Long song(s) skipped.",
                                      kCRToastTextAlignmentKey : @(NSTextAlignmentLeft),
                                      kCRToastBackgroundColorKey : [UIColor defaultAppColorScheme],
                                      kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                                      kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                                      kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                      kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionBottom),
                                      kCRToastFontKey   :   [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18],
                                      kCRToastNotificationTypeKey   : @(CRToastPresentationTypePush),
                                      kCRToastImageKey  : [UIImage imageNamed:@"alert_exclamation"],
                                      };
            [MyAlerts showOrQueueUpCRToastBannerWithOptions:options];
            break;
        }
        case ALERT_TYPE_Chosen_Song_Too_Long_For_Cellular:
        {
            NSDictionary *options = @{
                                      kCRToastTextKey : @"Song unplayable on LTE/3G, check settings.",
                                      kCRToastTextAlignmentKey : @(NSTextAlignmentLeft),
                                      kCRToastBackgroundColorKey : [UIColor defaultAppColorScheme],
                                      kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                                      kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                                      kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                      kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionBottom),
                                      kCRToastFontKey   :   [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18],
                                      kCRToastNotificationTypeKey   : @(CRToastPresentationTypePush),
                                      kCRToastImageKey  : [UIImage imageNamed:@"alert_exclamation"],
                                      };
            [MyAlerts showOrQueueUpCRToastBannerWithOptions:options];
            break;
        }
        case ALERT_TYPE_TroubleSharingVideo:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something bad happened when trying to share your video.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something bad happened when trying to share your song.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO];
            break;
        }
        case ALERT_TYPE_CannotOpenSafariError:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something went wrong trying to launch Safari.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES];
            break;
        }
        case ALERT_TYPE_CannotOpenSelectedImageError:
        {
            NSString *title = @"Bad Image";
            NSString *msg = @"The selected image could not be opened. Try a different image.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO];
            break;
        }
        case ALERT_TYPE_SongSaveHasFailed:
        {
            NSString *title = @"Song Not Saved";
            NSString *msg = @"Sorry, something went wrong saving your song.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO];
            break;
        }
        case ALERT_TYPE_WarnUserOfCellularDataFees:
        {
            NSString *title = @"Cellular Data Warning";
            NSString *msg = [NSString stringWithFormat:@"Just a heads up, %@ can use large amounts of data depending on your settings. Please be conscious of your data usage as fees from your provider may apply.", MZAppName];
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES];
            break;
        }
        case ALERT_TYPE_NowPlayingSongWasDeletedOnOtherDevice:
        {
            NSString *title = @"Current Song Deleted";
            NSString *msg = [NSString stringWithFormat:@"The previously playing song was deleted on another one of your devices. This device has synced with iCloud, so the song no longer exists. Skipping ahead..."];
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES];
            break;
        }
        default:
            break;
    }
}

+ (void)showOrQueueUpCRToastBannerWithOptions:(NSDictionary *)options
{
    BOOL appIsNotActive = [UIApplication sharedApplication].applicationState != UIApplicationStateActive;
    if(currentlyDisplayingBanner || appIsNotActive)
        [queuedToastBannerOptions addObject:options];
    else{
        currentlyDisplayingBanner = YES;
        [CRToastManager showNotificationWithOptions:options
                                    completionBlock:^{
                                        currentlyDisplayingBanner = NO;
                                        if(queuedToastBannerOptions.count > 0){
                                            NSDictionary *options = queuedToastBannerOptions[0];
                                            [queuedToastBannerOptions removeObjectAtIndex:0];
                                            
                                            double delayInSeconds = 0.6;
                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                //code to be executed on the main queue after delay
                                                [MyAlerts showOrQueueUpCRToastBannerWithOptions:options];
                                            });
                                        }
                                    }];
    }
}

+ (void)showAllQueuedBanners
{
    if(queuedToastBannerOptions.count == 0)
        return;
    else{
        NSDictionary *firstOption = [queuedToastBannerOptions objectAtIndex:0];
        [queuedToastBannerOptions removeObjectAtIndex:0];
        [CRToastManager showNotificationWithOptions:firstOption
                                    completionBlock:^{
                                        currentlyDisplayingBanner = NO;
                                        if(queuedToastBannerOptions.count > 0){
                                            NSDictionary *options = queuedToastBannerOptions[0];
                                            [queuedToastBannerOptions removeObjectAtIndex:0];
                                            
                                            double delayInSeconds = 0.6;
                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                //code to be executed on the main queue after delay
                                                [MyAlerts showOrQueueUpCRToastBannerWithOptions:options];
                                            });
                                        }
                                    }];
    }
}

+ (void)launchAlertViewWithDialogTitle:(NSString *)title
                            andMessage:(NSString *)message
                         customActions:(NSArray *)customAlertActions
                 allowsBasicLocalNotif:(BOOL)allowed
{
    UIApplication *app = [UIApplication sharedApplication];
    if(allowed && app.applicationState != UIApplicationStateActive){
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.repeatInterval = 0;
        [notification setAlertTitle:title];
        [notification setAlertBody:message];
        [notification setTimeZone:[NSTimeZone defaultTimeZone]];
        //[notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        [app scheduleLocalNotification:notification];
    } else {
        SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:SDCAlertControllerStyleAlert];
        SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                             style:SDCAlertActionStyleRecommended
                                                           handler:nil];
        if(customAlertActions){
            for(SDCAlertAction *someAction in customAlertActions)
                [alert addAction:someAction];
        }
        else
            [alert addAction:okAction];
        [alert presentWithCompletion:nil];
    }
}



@end
