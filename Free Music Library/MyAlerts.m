//
//  MyAlerts.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAlerts.h"
#import "SDCAlertView+DuplicateAlertsPreventer.h"
#import "PreferredFontSizeUtility.h"
#import "SongPlayerCoordinator.h"
#import "UIColor+LighterAndDarker.h"
#import "UIImage+colorImages.h"
#import "UIWindow+VisibleVC.h"

@implementation MyAlerts

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type
{
    switch (type) {
        case ALERT_TYPE_CannotConnectToYouTube:
        {
            //alert user to internet problem
            NSString *msg = @"Cannot connect to YouTube.";
            [MyAlerts dismissCurrentViewController];
            [[SongPlayerCoordinator sharedInstance] performSelector:@selector(beginShrinkingVideoPlayer)
                                                         withObject:nil
                                                         afterDelay:0.3];
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:1];
            break;
        }
        case ALERT_TYPE_CannotLoadVideo:
        {
            NSString *msg = @"An unknown problem occured while loading your song.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        case ALERT_TYPE_FatalSongDurationError:
        {
            NSString *msg = @"Total Song duration is not available.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleInfo delay:0];
            break;
        }
        case ALERT_TYPE_PotentialVideoDurationFetchFail:
        {
            NSString *msg = @"This video cannot be saved in its current state. An error has occured while fetching the information necessary to save this video.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            [MusicPlaybackController longVideoSkippedOnCellularConnection];
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
            {
                NSString *msg;
                
                int numSkipped = [MusicPlaybackController numLongVideosSkippedOnCellularConnection];
                if(numSkipped == 0)
                    return;
                else if (numSkipped == 1)
                    msg = @"1 Song was skipped. Long songs are skipped on a cellular connection.";
                else
                    msg = [NSString stringWithFormat:@"%i Songs skipped. Long songs are skipped on a cellular connection.", numSkipped];
                
                [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleInfo delay:0.6];
                [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
            }
                
            break;
        }
        case ALERT_TYPE_TroubleSharingVideo:
        {
            NSString *msg = @"Sorry, this video could not be shared.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            NSString *msg = @"Sorry, this song could not be shared.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        case ALERT_TYPE_CannotOpenSafariError:
        {
            NSString *msg = @"Whoops, something went wrong trying to launch Safari.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        case ALERT_TYPE_SongSaveSuccess:
        {
            NSString *msg = @"Song saved.";
            [MyAlerts displayBannerWithMsg:msg
                                     style:CSNotificationViewStyleSuccess
                                     delay:0.6];
        }
        case ALERT_TYPE_SongSaveHasFailed:
        {
            NSString *msg = @"Oh no! Something went wrong saving your song.";
            [MyAlerts displayBannerWithMsg:msg
                                     style:CSNotificationViewStyleError
                                     delay:0.6];
        }
        default:
            break;
    }
}

+ (void)dismissCurrentViewController
{
    UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
    [[keyWindow visibleViewController] dismissViewControllerAnimated:YES completion:nil];
}

+ (void)displayBannerWithMsg:(NSString *)msg
                       style:(CSNotificationViewStyle)style
                       delay:(float)seconds
{
    if(seconds == 0){
        UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
        [CSNotificationView showInViewController:[keyWindow visibleViewController]
                                           style:style
                                         message:msg];
    } else{
        __weak NSString *weakMsg = msg;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MyAlerts displayBannerWithMsg:weakMsg style:style delay:0];
        });
    }
}

+ (void)launchAlertViewWithDialogUsingTitle:(NSString *)title andMessage:(NSString *)msg
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:title
                                                      message:msg
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                              avoidDuplicates:YES];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}



//---------------------------------------------------------
//code below probably not needed because I have a better category for this...
/*
+ (UIViewController *)topViewController{
    return [MyAlerts topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

//from snikch on Github
+ (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil)
        return rootViewController;
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}
 */

@end
