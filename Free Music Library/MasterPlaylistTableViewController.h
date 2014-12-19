//
//  MasterPlaylistTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Playlist+Utilities.h"
#import "PlaylistItemTableViewController.h"  //tableview controller that shows the songs in the playlist
#import "PlaylistSongAdderTableViewController.h"  //song picker
#import "AppEnvironmentConstants.h"
#import "PlayListTableViewFormatter.h"
#import "NSString+WhiteSpace_Utility.h"
#import "SDWebImageManager.h"
#import "CoreDataManager.h"
#import "MusicPlaybackController.h"

#import "PlaylistSongAdderTableViewController.h"
#import "UINavigationController+CustomPushAnimation.h"

@interface MasterPlaylistTableViewController : CoreDataTableViewController <UISearchBarDelegate, UITextFieldDelegate>

@end
