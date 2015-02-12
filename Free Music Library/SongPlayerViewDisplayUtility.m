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
#import <AFBlurSegue.h>

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
    BOOL expanded = [[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded];
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
        vc.view.layer.speed = 0.85;  //slows down the modal transition
        [segue perform];

        if(!animate){
            __weak UIViewController *weakVC = vc;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                [SongPlayerViewDisplayUtility makeAlphaOne:weakVC];
            });
        }

        [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];
    }
}

+ (void)makeAlphaOne:(UIViewController *)vc
{
    vc.view.hidden = NO;
}

@end