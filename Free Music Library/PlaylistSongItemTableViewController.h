//
//  PlaylistSongItemTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

//This class controls how the user adds songs to their playlist
#import <Foundation/Foundation.h>
#import "Song.h"
#import "Playlist.h"
#import "AppEnvironmentConstants.h"
#import "MasterSongsTableViewController.h"
#import "SongTableViewFormatter.h"
#import "SDWebImageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface PlaylistSongItemTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *results;  //for searching tableView?
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, strong) NSMutableArray *songsSelected;
@property (nonatomic, strong) Playlist *receiverPlaylist;  //the playlist the chosen songs will be a part of

//gui vars
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftBarButton;

- (IBAction)rightBarButtonTapped:(id)sender;
- (IBAction)leftBarButtonTapped:(id)sender;

@end
