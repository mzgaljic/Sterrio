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
    
    [self setUpAlbumView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)setUpAlbumView
{
    self.albumNameTitleLabel.text = self.album.albumName;
    
    if(PRODUCTION_MODE)
        self.albumUiImageView.image = [AlbumArtUtilities albumArtFileNameToUiImage: self.album.albumArtFileName];
    else
        self.albumUiImageView.image = [UIImage imageNamed:self.album.albumName];
    
    
    self.navBar.title = self.album.albumName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
}

@end