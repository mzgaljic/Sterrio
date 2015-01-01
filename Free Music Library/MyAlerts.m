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

@implementation MyAlerts

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type
{
    switch (type) {
        case CannotConnectToYouTube:
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
