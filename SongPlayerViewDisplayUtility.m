//
//  SongPlayerViewDisplayUtility.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/23/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongPlayerViewDisplayUtility.h"
#import "SongPlayerNavController.h"
#import "SongPlayerCoordinator.h"
#import "AFBlurSegue.h"

@implementation SongPlayerViewDisplayUtility

int nearestEvenInt(int to)
{
    return (to % 2 == 0) ? to : (to + 1);
}

+ (float)videoHeightInSixteenByNineAspectRatioGivenWidth:(float)width
{
    float tempVar = width;
    tempVar = ceil(width * 9.0f);
    return ceil(tempVar / 16.0f);
}

+ (void)segueToSongPlayerViewControllerFrom:(UIViewController *)sourceController
{
    BOOL expanded = [SongPlayerCoordinator isVideoPlayerExpanded];
    if(! expanded){
        //check orientation. Don't want to animate in landscape
        BOOL animate = NO;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if(orientation == UIInterfaceOrientationPortrait)
            animate = YES;
        SongPlayerNavController *vc = [[SongPlayerNavController alloc] init];
        AFBlurSegue *segue = [[AFBlurSegue alloc] initWithIdentifier:@""
                                                              source:sourceController
                                                         destination:vc];
        segue.animate = animate;
        if(! animate)
            vc.view.hidden = YES;
        
        [sourceController prepareForSegue:segue sender:nil];
        
        vc.view.layer.speed = 0.90;  //slows down the modal transition
        [segue perform];
        
        [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];

        if(! [AppEnvironmentConstants userSawExpandingPlayerTip]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldDismissPlayerExpandingTip" object:@YES];
        }

        if(!animate){
            __weak UIViewController *weakVC = vc;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [SongPlayerViewDisplayUtility makeAlphaOne:weakVC];
            });
        }
    }
}

+ (void)animatePlayerIntoMinimzedModeInPrepForPlayback
{
    BOOL expanded = [SongPlayerCoordinator isVideoPlayerExpanded];
    if(expanded)
        return;  //no work to be done, player already very much visible lol.
    [[SongPlayerCoordinator sharedInstance] beginAnimatingPlayerIntoMinimzedStateIfNotExpanded];
}

+ (void)makeAlphaOne:(UIViewController *)vc
{
    vc.view.hidden = NO;
}

static NSString *secondsToStringReturn = @"";
static NSUInteger totalSeconds;
static NSUInteger totalMinutes;
static int seconds;
static int minutes;
static int hours;
+ (NSString *)convertSecondsToPrintableNSStringWithSliderValue:(float)value
{
    totalSeconds = value;
    seconds = (int)(totalSeconds % MZSecondsInAMinute);
    totalMinutes = totalSeconds / MZSecondsInAMinute;
    minutes = (int)(totalMinutes % MZMinutesInAnHour);
    hours = (int)(totalMinutes / MZMinutesInAnHour);
    
    if(minutes < 10 && hours == 0)  //we can shorten the text
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
    else if(hours > 0)
    {
        if(hours <= 9)
            secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d:%02d",hours,minutes,seconds];
        else
            secondsToStringReturn = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes, seconds];
    }
    else
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    return secondsToStringReturn;
}

@end