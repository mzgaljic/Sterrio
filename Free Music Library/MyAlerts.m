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

static AFDropdownNotification *notification;

@implementation MyAlerts

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
                                    customActions:actions];
            break;
        }
        case ALERT_TYPE_CannotLoadVideo:
        {
            NSString *msg = @"Video failed to load.";
            [self launchAlertViewWithDialogTitle:nil
                                      andMessage:msg
                                   customActions:nil];
            break;
        }
        case ALERT_TYPE_LongVideoSkippedOnCellular:
        {
            return;
            
            
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
        case ALERT_TYPE_TroubleSharingVideo:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something went wrong sharing your video.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil];
            break;
        }
        case ALERT_TYPE_TroubleSharingLibrarySong:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something went wrong sharing your song.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil];
            break;
        }
        case ALERT_TYPE_CannotOpenSafariError:
        {
            NSString *title = @"Whoops";
            NSString *msg = @"Something went wrong trying to launch Safari.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil];
            break;
        }
        case ALERT_TYPE_CannotOpenSelectedImageError:
        {
            NSString *title = @"Bad Image";
            NSString *msg = @"The selected image could not be opened. Try a different image.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil];
            break;
        }
        case ALERT_TYPE_SongSaveHasFailed:
        {
            NSString *title = @"Song Not Saved";
            NSString *msg = @"Sorry, something went wrong saving your song.";
            [self launchAlertViewWithDialogTitle:title
                                      andMessage:msg
                                   customActions:nil];
            break;
        }
        default:
            break;
    }
}


+ (void)launchAlertViewWithDialogTitle:(NSString *)title
                            andMessage:(NSString *)message
                         customActions:(NSArray *)customAlertActions;
{
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



@end
