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
#import "SongPlayerViewController.h"  //needed just to call preDealloc

static AFDropdownNotification *notification;

@implementation MyAlerts

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type
{
    if([NSThread mainThread]){
        [MyAlerts runDisplayAlertCodeWithAlertType:type];
    } else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [MyAlerts runDisplayAlertCodeWithAlertType:type];
        });
    }
}

+ (void)runDisplayAlertCodeWithAlertType:(ALERT_TYPE)type
{
    return;
    switch (type) {
        case ALERT_TYPE_CannotConnectToYouTube:
        {
            //alert user to internet problem
            
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Cannot connect to YouTube.";
            notification.image = [UIImage colorOpaquePartOfImage:[UIColor redColor]
                                                                :[UIImage imageNamed:@"x_icon"]];
            notification.topButtonText = @"Retry";
            notification.bottomButtonText = @"Okay";
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            
            [notification listenEventsWithBlock:^(AFDropdownNotificationEvent event) {
                switch (event) {
                    case AFDropdownNotificationEventTopButton:
                        [VideoPlayerWrapper startPlaybackOfSong:[NowPlayingSong sharedInstance].nowPlaying
                                                   goingForward:YES
                                                        oldSong:nil];
                        break;
                    default:
                        break;
                }
            }];
            break;
        }
        case ALERT_TYPE_CannotLoadVideo:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText =  @"An unknown problem occured while loading your song.";
            notification.topButtonText = @"Retry";
            notification.bottomButtonText = @"Okay";
            notification.image = [UIImage colorOpaquePartOfImage:[UIColor redColor]
                                                                :[UIImage imageNamed:@"x_icon"]];
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            
            [notification listenEventsWithBlock:^(AFDropdownNotificationEvent event) {
                switch (event) {
                    case AFDropdownNotificationEventTopButton:
                        [VideoPlayerWrapper startPlaybackOfSong:[NowPlayingSong sharedInstance].nowPlaying
                                                   goingForward:YES
                                                        oldSong:nil];
                        break;
                    default:
                        break;
                }
            }];
            break;
        }
        case ALERT_TYPE_FatalSongDurationError:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Song duration not available.";
            notification.bottomButtonText = @"Okay";
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_PotentialVideoDurationFetchFail:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Video Fetch Issue";
            notification.subtitleText = @"This video cannot be saved in its current state. An error has occured fetching information.";
            notification.bottomButtonText = @"Okay";
            notification.image = [UIImage colorOpaquePartOfImage:[UIColor yellowColor]
                                                                                   :[UIImage imageNamed:@"warning"]] ;
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            [MusicPlaybackController longVideoSkippedOnCellularConnection];
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
            {
                NSString *subtitle;
                
                int numSkipped = [MusicPlaybackController numLongVideosSkippedOnCellularConnection];
                if(numSkipped == 0)
                    return;
                else if (numSkipped == 1)
                    subtitle = @"1 Song was skipped. Long songs are skipped on a cellular connection.";
                else
                    subtitle = [NSString stringWithFormat:@"%i Songs skipped. Long songs are skipped on a cellular connection.", numSkipped];
                
                NSString *title;
                if(numSkipped == 1)
                    title = @"Song Skipped";
                else
                    title = @"Songs Skipped";

                notification = [[AFDropdownNotification alloc] init];
                notification.titleText = title;
                notification.subtitleText = subtitle;
                notification.dismissOnTap = NO;
                notification.bottomButtonText = @"Okay";
                [notification presentInView:[UIApplication sharedApplication].keyWindow
                       withGravityAnimation:YES];
                
                [MusicPlaybackController resetNumberOfLongVideosSkippedOnCellularConnection];
            }
            
            break;
        }
        case ALERT_TYPE_LongPreviewVideoSkippedOnCellular:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Long Video";
            notification.subtitleText = @"This video is too long to preview on a cellular connection.";
            notification.image = [UIImage colorOpaquePartOfImage:[UIColor yellowColor]
                                                                :[UIImage imageNamed:@"warning"]];
            notification.dismissOnTap = NO;
            notification.bottomButtonText = @"Okay";
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_TroubleSharingVideo:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Sorry, a problem occured sharing your video.";
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Sorry, this song could not be shared.";
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_CannotOpenSafariError:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Whoops";
            notification.subtitleText = @"Something went wrong trying to launch Safari.";
            UIImage *x = [UIImage colorOpaquePartOfImage:[UIColor redColor]
                                                        :[UIImage imageNamed:@"x_icon"]];
            notification.image = x;
            notification.bottomButtonText = @"Okay";
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_CannotOpenSelectedImageError:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Bad Image";
            notification.subtitleText = @"The selected image could not be opened. Try a different image.";
            notification.dismissOnTap = NO;
            notification.bottomButtonText = @"Okay";
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_SongSaveHasFailed:
        {
            notification = [[AFDropdownNotification alloc] init];
            notification.titleText = @"Song Not Saved";
            notification.subtitleText = @"Sorry, something went wrong saving your song.";
            notification.image = [UIImage colorOpaquePartOfImage:[UIColor redColor]
                                                                :[UIImage imageNamed:@"x_icon"]];
            notification.bottomButtonText = @"Okay";
            notification.dismissOnTap = NO;
            [notification presentInView:[UIApplication sharedApplication].keyWindow
                   withGravityAnimation:YES];
            break;
        }
        case ALERT_TYPE_SongQueued:
        {
#warning alert doesnt do anything
            /*
            NSString *msg = @"Queued";
            [MyAlerts displayBannerWithMsg:msg
                                     style:CSNotificationViewStyleSuccess
                                     delay:0
                             shortDuration:YES];
             */
            break;
        }
        default:
            break;
    }
}

+ (void)dismissCurrentViewController
{
    //If the class has a preDealloc method, call it to avoid a retain cycle or worse a crash.
    UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
    id someVC = [keyWindow visibleViewController];
    
    if ([someVC respondsToSelector:@selector(preDealloc)]) {
        [someVC preDealloc];
    }
    UIViewController *vc = (UIViewController *)someVC;
    [vc dismissViewControllerAnimated:YES completion:nil];
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
    alert.normalButtonFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.buttonTextColor = [UIColor defaultAppColorScheme];
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
