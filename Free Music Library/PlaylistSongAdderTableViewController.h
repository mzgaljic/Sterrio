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

//will set up a new playlist if it doesnt exist. if user cancels editing new playlist,
//core data context will be rolled back to remove changes made in this class.
//if the playlist exists, the changes will be saved once this class is done doing its work.
- (instancetype)initWithPlaylistsUniqueId:(NSString *)uniqueId playlistName:(NSString *)name;

//gui vars
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftBarButton;

- (IBAction)leftBarButtonTapped:(id)sender;

@end
