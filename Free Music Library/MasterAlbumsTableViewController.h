//
//  MasterAlbumsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
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
#import "PlaybackModelSingleton.h"
#import "YouTubeMoviePlayerSingleton.h"
#import "UIImage+colorImages.h"

@interface MasterAlbumsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *results;  //for searching tableView?
@property (nonatomic, assign) int selectedRowIndexValue;

@end
