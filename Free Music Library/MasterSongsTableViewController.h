//
//  MasterSongsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RNFrostedSideBar.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "SongItemViewController.h"
#import "AlteredModelItem.h"
#import "AlteredModelSongQueue.h"
#import "Song.h"

@interface MasterSongsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *results;  //for searching tableView?
@property (nonatomic, assign) int selectedRowIndexValue;

- (IBAction)expandableMenuSelected:(id)sender;
@end
