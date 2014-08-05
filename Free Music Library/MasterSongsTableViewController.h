//
//  MasterSongsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "SongItemViewController.h"
#import "MasterEditingSongTableViewController.h"
#import "Song.h"
#import "SDWebImageManager.h"
#import "SongTableViewFormatter.h"
#import "FrostedSideBarHelper.h"
#import "PreferredFontSizeUtility.h"
#import "UIImage+colorImages.h"

@interface MasterSongsTableViewController : UITableViewController <UISearchBarDelegate>
- (IBAction)expandableMenuSelected:(id)sender;
@end
