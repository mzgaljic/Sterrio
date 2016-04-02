//
//  SongPlayerNavController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/23/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongPlayerNavController.h"
#import "SongPlayerViewController.h"

@implementation SongPlayerNavController : UINavigationController

- (void)viewWillAppear:(BOOL)animated
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SongPlayerViewController *vc = (SongPlayerViewController *)[storyboard instantiateViewControllerWithIdentifier:@"songItemView"];
    [self pushViewController:vc animated:NO];
    
    self.navigationController.navigationBar.translucent = YES;
    if([AppEnvironmentConstants appTheme].useWhiteStatusBar) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    } else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
    
    //fixes issue where playerview is sometimes "behind" a presented modal view (usually multiple modals)
    [[MusicPlaybackController obtainRawPlayerView] removeFromSuperview];
    UIWindow *appWindow = [[[UIApplication sharedApplication] delegate] window];
    [appWindow addSubview:[MusicPlaybackController obtainRawPlayerView]];
    [super viewWillAppear:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

@end