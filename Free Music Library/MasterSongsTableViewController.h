//
//  MasterSongsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "SongItemViewController.h"
#import "MasterEditingSongTableViewController.h"
#import "Song.h"
#import "SongTableViewFormatter.h"
#import "FrostedSideBarHelper.h"

@interface MasterSongsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *results;  //for searching tableView?
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, assign) int indexOfEditingSong;

- (IBAction)expandableMenuSelected:(id)sender;
@end
