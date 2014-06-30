//
//  AlbumItemViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"
#import "Song.h"

@interface AlbumItemViewController : UIViewController
@property (strong, nonatomic) Album *album;

//GUI vars
@property (weak, nonatomic) IBOutlet UILabel *albumNameTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumUiImageView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@end
