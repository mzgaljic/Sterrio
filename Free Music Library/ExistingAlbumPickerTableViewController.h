//
//  ExistingAlbumPickerTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "AlbumItemViewController.h"
#import "Album.h"
#import "SDWebImageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AlbumTableViewFormatter.h"
#import "UIImage+colorImages.h"
#import "UIColor+SystemTintColor.h"

@interface ExistingAlbumPickerTableViewController : UITableViewController

- (id)initWithCurrentAlbum:(Album *)anAlbum;

@end
