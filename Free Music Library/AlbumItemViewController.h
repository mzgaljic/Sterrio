//
//  AlbumItemViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumArtUtilities.h"
#import "Album.h"
#import "Song.h"
#import "MZAlbumSectionHeader.h"
#import "CoreDataCustomTableViewController.h"
#import "ArtistTableViewFormatter.h"

@interface AlbumItemViewController : CoreDataCustomTableViewController <UITableViewDataSource,
                                                                        UITableViewDelegate,
                                                                        MGSwipeTableCellDelegate>

@property (strong, nonatomic) Album *album;

//GUI vars
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@end
