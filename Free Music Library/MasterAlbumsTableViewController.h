//
//  MasterAlbumsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrostedSideBarHelper.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "AlbumItemViewController.h"
#import "Album.h"
#import "AlbumTableViewFormatter.h"

@interface MasterAlbumsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *results;  //for searching tableView?
@property (nonatomic, assign) int selectedRowIndexValue;

- (IBAction)expandableMenuSelected:(id)sender;
@end
