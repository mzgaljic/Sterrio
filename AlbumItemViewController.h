//
//  AlbumItemViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataCustomTableViewController.h"
#import "MGSwipeTableCell.h"

@class Album;
@interface AlbumItemViewController : CoreDataCustomTableViewController <UITableViewDataSource,
                                                                        UITableViewDelegate,
                                                                        MGSwipeTableCellDelegate>

@property (strong, nonatomic) Album *album;
@property (strong, nonatomic) PlaybackContext *parentVcPlaybackContext;

//GUI vars
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@end
