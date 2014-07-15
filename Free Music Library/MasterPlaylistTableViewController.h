//
//  MasterPlaylistTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Playlist.h"
#import "RNFrostedSideBar.h"
#import "AlteredModelItem.h"
#import "PlaylistItemTableViewController.h"  //tableview controller that shows the songs in the playlist
#import "PlaylistSongItemTableViewController.h"  //song picker
#import "AlteredModelAlbumQueue.h"
#import "AppEnvironmentConstants.h"

@interface MasterPlaylistTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *results;  //for searching tableView?
@property (nonatomic, assign) int selectedRowIndexValue;

- (IBAction)expandableMenuSelected:(id)sender;
- (IBAction)addButtonPressed:(id)sender;
@end
