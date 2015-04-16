//
//  PlaylistSongAdderTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

//This class controls how the user adds songs to their playlist
#import <Foundation/Foundation.h>
#import "CoreDataManager.h"
#import "CoreDataCustomTableViewController.h"
#import "PlaylistSongAdderDataSourceDelegate.h"
#import "SearchBarDataSourceDelegate.h"

@class Playlist;
@interface PlaylistSongAdderTableViewController : CoreDataCustomTableViewController
                                                                <SearchBarDataSourceDelegate,
                                                                PlaylistSongAdderDataSourceDelegate>

- (id)initWithPlaylist:(Playlist *)aPlaylist;

@property (nonatomic, strong) Playlist *receiverPlaylist;  //the playlist the chosen songs will be a part of

//gui vars
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftBarButton;

- (IBAction)rightBarButtonTapped:(id)sender;
- (IBAction)leftBarButtonTapped:(id)sender;

@end
