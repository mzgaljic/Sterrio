//
//  ArtistItemAlbumViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Artist.h"
#import "SDWebImageManager.h"
#import "MyViewController.h"

@interface ArtistItemAlbumViewController : MyViewController

@property (strong, nonatomic) Artist *artist;
//GUI vars
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@end
