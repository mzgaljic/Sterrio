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
            NSString *msg = @"Looks like there's a problem loading certain videos. We've been notified and we're working on fixing this ASAP!";
            [MyAlerts launchAlertViewWithDialogTitle:@"Problem loading videos"
                                          andMessage:msg
                                       customActions:nil
                               allowsBasicLocalNotif:YES
                                      makeNotifSound:NO];
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
                                  makeNotifSound:YES];
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
                                  makeNotifSound:YES];
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
                                  makeNotifSound:NO];
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
                                  makeNotifSound:NO];
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
                                  makeNotifSound:NO];
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
                                  makeNotifSound:NO];
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
                                  makeNotifSound:NO];
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
                                  makeNotifSound:YES];
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
                                  makeNotifSound:YES];
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
                                  makeNotifSound:YES];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player dismissAllSpinnersIfPossible];
    }];
}

+ (void)skippedLibrarySongDueToLength
{
    numSkippedSongs++;
}

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
                                  makeNotifSound:NO];
        numSkippedSongs = 0;
    }
}

+ (void)launchAlertViewWithDialogTitle:(NSString *)title
                            andMessage:(NSString *)message
                         customActions:(NSArray *)customAlertActions
                 allowsBasicLocalNotif:(BOOL)allowed
                        makeNotifSound:(BOOL)makeSound
{
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
    } else {
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
        }
        else
            [alert addAction:okAction];
        [alert presentWithCompletion:nil];
    }
}

@end
