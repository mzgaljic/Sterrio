//
//  ArtistItemAlbumViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ArtistItemAlbumViewController.h"

@interface ArtistItemAlbumViewController ()
@end

@implementation ArtistItemAlbumViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *navBarTitle;
    if(self.artist)
        navBarTitle = self.artist.artistName;
    else
        navBarTitle = @"";
    self.navBar.title = navBarTitle;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

@end
