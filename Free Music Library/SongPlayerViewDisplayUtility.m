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
        SongPlayerNavController *vc = [[SongPlayerNavController alloc] init];
        AFBlurSegue *segue = [[AFBlurSegue alloc] initWithIdentifier:@"" source:sourceController destination:vc];
        [sourceController prepareForSegue:segue sender:nil];
        [segue perform];
        [[SongPlayerCoordinator sharedInstance] begingExpandingVideoPlayer];
    }
}

@end