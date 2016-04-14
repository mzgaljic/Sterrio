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
#import "YouTubeService.h"
#import "TermsOfServiceViewController.h"
@import SafariServices;

@implementation MyAlerts
static int numSkippedSongs = 0;

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
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
        case ALERT_TYPE_SomeVideosNoLongerLoading:
        {
            NSString *msg = @"Looks like there's a problem loading this video. We've been notified and we're working on fixing this ASAP!";
            [MyAlerts launchAlertViewWithDialogTitle:@"Problem loading video"
                                          andMessage:msg
                                       customActions:nil
                               allowsBasicLocalNotif:YES
                                      makeNotifSound:NO
                                    useAlertAndNotif:YES];
            break;
        }
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
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:YES
                                useAlertAndNotif:NO];
            //userAlertAndNotif is no since when the app is backgrounded the app will just skip
            //to the next song (I think).
            break;
        }
        case ALERT_TYPE_CannotLoadVideo:
        {
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
            [self launchAlertViewWithDialogTitle:nil
                                      andMessage:@"Video failed to load."
                                   customActions:actions
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:YES
                                useAlertAndNotif:NO];
            //userAlertAndNotif is no since when the app is backgrounded the app will just skip
            //to the next song (I think).
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            [MyAlerts showAlertWithNumSkippedSongs];
            break;
        }
        case ALERT_TYPE_Chosen_Song_Too_Long_For_Cellular:
        {
            [MyAlerts showAlertWithNumSkippedSongs];
            break;
        }
        case ALERT_TYPE_TroubleSharingVideo:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something bad happened when trying to share your video.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO
                                  makeNotifSound:NO
                                useAlertAndNotif:NO];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something bad happened when trying to share your song.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO
                                  makeNotifSound:NO
                                useAlertAndNotif:NO];
            break;
        }
        case ALERT_TYPE_CannotOpenSafariError:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something went wrong trying to launch Safari.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:NO
                                useAlertAndNotif:NO];
            break;
        }
        case ALERT_TYPE_CannotOpenSelectedImageError:
        {
            NSString *title = @"Bad Image";
            NSString *msg = @"The selected image could not be opened. Try a different image.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO
                                  makeNotifSound:NO
                                useAlertAndNotif:NO];
            break;
        }
        case ALERT_TYPE_SongSaveHasFailed:
        {
            NSString *title = @"Song Not Saved";
            NSString *msg = @"Sorry, something bad happened when trying to save your song.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:NO
                                  makeNotifSound:NO
                                useAlertAndNotif:NO];
            break;
        }
        case ALERT_TYPE_WarnUserOfCellularDataFees:
        {
            NSString *title = @"Cellular Data Warning";
            NSString *msg = [NSString stringWithFormat:@"Just a heads up, %@ can use large amounts of data depending on your settings. \n\nPlease be conscious of your data usage as fees from your provider may apply.", MZAppName];
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:YES
                                useAlertAndNotif:YES];
            break;
        }
        case ALERT_TYPE_NowPlayingSongWasDeletedOnOtherDevice:
        {
            NSString *title = @"Current Song Deleted";
            NSString *msg = [NSString stringWithFormat:@"The previously playing song was deleted on another one of your devices. This device has synced with iCloud, so the song no longer exists. Skipping..."];
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:YES
                                useAlertAndNotif:YES];
            break;
        }
        case ALERT_TYPE_TosAndPrivacyPolicy:
        case ALERT_TYPE_NEWTosAndPrivacyPolicy:
        {
            NSString *title, *msg;
            if(type == ALERT_TYPE_TosAndPrivacyPolicy) {
                title = @"Terms";
                msg = [NSString stringWithFormat:@"Please take a minute to review %@'s Terms and Conditions. By tapping \"Accept\", you agree to the terms.", MZAppName];
            } else {
                title = @"Updated Terms";
                msg = @"There are new Terms and Conditions, please take a minute to review them. By tapping \"Accept\", you agree to these updates.";
            }
            SDCAlertAction *accept = [SDCAlertAction actionWithTitle:@"Accept"
                                                               style:SDCAlertActionStyleRecommended
                                                             handler:^(SDCAlertAction *action) {
                                                                 [MyAlerts markTermsAccepted];
                                                             }];
            SDCAlertAction *tos = [SDCAlertAction actionWithTitle:@"View Terms"
                                                            style:SDCAlertActionStyleDefault
                                                          handler:nil];
            SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                            message:msg
                                                                     preferredStyle:SDCAlertControllerStyleAlert];
            //tos is the left button here.
            [alert addAction:tos];
            [alert addAction:accept];
            alert.actionLayout = SDCAlertControllerActionLayoutAutomatic;
            alert.shouldDismissBlock = ^ BOOL(SDCAlertAction *action) {
                if([action.title isEqualToString:@"Accept"]) {
                    return YES;
                } else {
                    [MyAlerts presentAppTermsModally];
                    return NO;
                }
            };
            [alert presentWithCompletion:nil];
            break;
        }
        default:
            break;
    }
}

+ (void)displayVideoNoLongerAvailableOnYtAlertForSong:(NSString *)name
                                        customActions:(NSArray *)actions
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *msg = [NSString stringWithFormat:@"It looks like this video for \"%@\" is no longer available on YouTube.", name];
        [MyAlerts launchAlertViewWithDialogTitle:@"Video Unavailable"
                                      andMessage:msg
                                   customActions:actions
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:YES
                                useAlertAndNotif:YES];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player dismissAllSpinnersIfPossible];
    }];
}

+ (void)skippedLibrarySongDueToLength
{
    numSkippedSongs++;
}

//will show an alert AND local notif when this occurs. Will show the num songs skipped while
//the app tried to skip to the next song. NOT just the stuff skipped since the user had the app
//backgrounded.
+ (void)showAlertWithNumSkippedSongs
{
    if(numSkippedSongs == 0) {
        return;
    } else {
        NSString *title = @"Songs Skipped";
        
        NSString *msg;
        if(numSkippedSongs == 1) {
            msg = @"The previous song was skipped because it was too long for a cellular connection. To change this behavior, go into 'Advanced' in the App settings.";
        } else {
            msg = [NSString stringWithFormat:@"%i songs were skipped because they were too long for a cellular connection. To change this behavior, go into 'Advanced' in the App settings.", numSkippedSongs];
        }
        [MyAlerts launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil
                           allowsBasicLocalNotif:YES
                                  makeNotifSound:NO
                                useAlertAndNotif:YES];
        numSkippedSongs = 0;
    }
}

+ (void)launchAlertViewWithDialogTitle:(NSString *)title
                            andMessage:(NSString *)message
                         customActions:(NSArray *)customAlertActions
                 allowsBasicLocalNotif:(BOOL)allowed
                        makeNotifSound:(BOOL)makeSound
                      useAlertAndNotif:(BOOL)useBoth
{
    //setup the alert in case we want to show it...
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    [alert setActionLayout:SDCAlertControllerActionLayoutAutomatic];
    SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                         style:SDCAlertActionStyleRecommended
                                                       handler:nil];
    if(customAlertActions){
        for(SDCAlertAction *someAction in customAlertActions)
            [alert addAction:someAction];
    } else {
        [alert addAction:okAction];
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    if(allowed && app.applicationState != UIApplicationStateActive){
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.repeatInterval = 0;
        [notification setAlertTitle:title];
        [notification setAlertBody:message];
        [notification setTimeZone:[NSTimeZone defaultTimeZone]];
        if(makeSound) {
            [notification setSoundName:UILocalNotificationDefaultSoundName];
        }
        [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        [app scheduleLocalNotification:notification];
        if(useBoth) {
            [alert presentWithCompletion:nil];
        }
    } else {
        [alert presentWithCompletion:nil];
    }
}

#pragma mark - App Terms stuff
+ (void)presentAppTermsModally
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([AppEnvironmentConstants isUserOniOS9OrAbove]) {
            SFSafariViewController *safController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:MZAppTermsPdfLink]];
            //set toolbar & navbar button color
            safController.view.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
            UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:safController];
            navVc.navigationBar.barStyle = UIBarStyleBlack;
            [navVc setNavigationBarHidden:YES];  //hide my navigation bar and use the SFSafariController one.
            [[MZCommons topViewController] presentViewController:navVc animated:YES completion:NULL];
        } else {
            TermsOfServiceViewController *tosVc = [TermsOfServiceViewController new];
            UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:tosVc];
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                           target:tosVc
                                           action:@selector(dismiss)];
            tosVc.navigationItem.leftBarButtonItem = doneButton;
            [[MZCommons topViewController] presentViewController:navVc animated:YES completion:nil];
        }
    });
}

//private helper method
+ (void)markTermsAccepted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *tosVerAccepted = [NSNumber numberWithInteger:MZCurrentTosVersion];
        [AppEnvironmentConstants setHighestTosVersionUserAccepted:tosVerAccepted updateNsDefaults:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZAppIntroCompleteAndAppTermsAccepted object:nil];
    });
}

@end
