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
    self.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar font light (readable)
    
    //fixes issue where playerview is sometimes "behind" a presented modal view (usually multiple modals)
    [[MusicPlaybackController obtainRawPlayerView] removeFromSuperview];
    UIWindow *appWindow = [[[UIApplication sharedApplication] delegate] window];
    [appWindow addSubview:[MusicPlaybackController obtainRawPlayerView]];
    [AppEnvironmentConstants recordIndexOfPlayerView:[[appWindow subviews] indexOfObject:[MusicPlaybackController obtainRawPlayerView]]];
    [super viewWillAppear:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

@end