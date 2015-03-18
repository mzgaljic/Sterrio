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
    //self.emptyTableUserMessage = @"No Albums";
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


@end
