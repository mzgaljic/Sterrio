//
//  PushNotificationsHelper.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/22/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "PushNotificationsHelper.h"
#import "SDCAlertControllerView.h"
#import "AppEnvironmentConstants.h"

@implementation PushNotificationsHelper

+ (void)askUserIfTheyAreInterestedInPushNotif
{
    if([AppEnvironmentConstants userAcceptedOrDeclinedPushNotifications]) {
        return;
    }
    
    [AppEnvironmentConstants userAcceptedOrDeclinedPushNotif:YES];
    NSString *msg = @"We're about to ask for permission to send push notifications. Responding with \"Allow\" lets us notify you when problems occur.";
    
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:@"Push notifications"
                                                                    message:msg
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    SDCAlertAction *act = [SDCAlertAction actionWithTitle:@"I'm Ready"
                                                   style:SDCAlertActionStyleRecommended
                                                 handler:^(SDCAlertAction *action) {
                                                     [PushNotificationsHelper promptSystemPushNotifRequest];
                                                 }];
    [alert addAction:act];
    [alert presentWithCompletion:nil];
}

+ (void)promptSystemPushNotifRequest
{
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

@end
