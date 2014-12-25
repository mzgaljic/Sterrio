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
    SongPlayerViewController *vc = [[SongPlayerViewController alloc] init];
    [self pushViewController:vc animated:NO];
}

@end