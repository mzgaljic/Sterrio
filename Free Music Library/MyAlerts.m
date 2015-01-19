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
            
            UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
            [[keyWindow visibleViewController] dismissViewControllerAnimated:YES completion:nil];
            [[SongPlayerCoordinator sharedInstance] performSelector:@selector(beginShrinkingVideoPlayer)
                                                         withObject:nil
                                                         afterDelay:0.3];
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:1];
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            [MusicPlaybackController longVideoSkippedOnCellularConnection];
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
                NSString *msg;
                
                int numSkipped = [MusicPlaybackController numLongVideosSkippedOnCellularConnection];
                if(numSkipped == 0)
                    return;
                else if (numSkipped == 1)
                    msg = @"1 Song was skipped.";
                else
                    msg = [NSString stringWithFormat:@"%i Songs skipped.", numSkipped];
                
                [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleInfo delay:0];

                [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
            }
                
            break;
        }
            
        case ALERT_TYPE_TroubleSharingVideo:
        {
            NSString *msg = @"There was a problem sharing this video.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            NSString *msg = @"There was a problem sharing this song.";
            [MyAlerts displayBannerWithMsg:msg style:CSNotificationViewStyleError delay:0];
            break;
        }
        default:
            break;
    }
}

+ (void)displayBannerWithMsg:(NSString *)msg style:(CSNotificationViewStyle)style delay:(float)seconds
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
