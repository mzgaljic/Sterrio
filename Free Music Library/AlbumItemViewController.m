//
//  AlbumItemViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumItemViewController.h"

@interface AlbumItemViewController ()
@end

@implementation AlbumItemViewController
static BOOL PRODUCTION_MODE;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.emptyTableUserMessage = @"No Albums";
    [self setUpAlbumView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)setUpAlbumView
{
    self.navBar.title = self.album.albumName;
}


@end