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

@implementation MyAlerts

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type
{
    switch (type) {
        case ALERT_TYPE_CannotConnectToYouTube:
        {
            //alert user to internet problem
            NSString *title = @"Internet";
            NSString *msg = @"Cannot connect to YouTube.";
            UIViewController *vc = [MyAlerts topViewController];
            [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            [vc dismissViewControllerAnimated:YES completion:nil];
            [[SongPlayerCoordinator sharedInstance] beginShrinkingVideoPlayer];
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            [MusicPlaybackController longVideoSkippedOnCellularConnection];
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
                MCNotification *notification = [MCNotification notification];
                UIImage *infoIcon = [UIImage colorOpaquePartOfImage:[UIColor blackColor]
                                                                   :[UIImage imageNamed:@"Information"]];
                notification.image = infoIcon;
                int numSkipped = [MusicPlaybackController numLongVideosSkippedOnCellularConnection];
                if(numSkipped == 0)
                    return;
                else if (numSkipped == 1)
                    notification.text = @"1 Song Skipped";
                else
                    notification.text = [NSString stringWithFormat:@"%i Songs Skipped", numSkipped];
                notification.detailText = @"Wi-Fi required for longer videos.";
                notification.backgroundColor = [[UIColor whiteColor] darkerColor];
                notification.tintColor = [UIColor blackColor];
                [[MCNotificationManager sharedInstance] showNotification:notification];
                [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
            }
                
            break;
        }
            
        case ALERT_TYPE_TroubleSharingVideo:
        {
            //alert user to internet problem
            NSString *title = @"Trouble Sharing";
            NSString *msg = @"Sorry, a problem occured while gathering information to share this video.";
            [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            //alert user to internet problem
            NSString *title = @"Trouble Sharing";
            NSString *msg = @"Sorry, a problem occured while gathering information to share this song.";
            [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            break;
        }
        default:
            break;
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

@end
