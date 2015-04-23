//
//  PlaylistItemTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Playlist+Utilities.h"
#import "Song+Utilities.h"
#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"
#import "SDWebImageManager.h"
#import "CoreDataCustomTableViewController.h"
#import "PlaylistSongAdderTableViewController.h"
#import "UINavigationController+CustomPushAnimation.h"
#import "MusicPlaybackController.h"
#import <FXImageView/UIImage+FX.h>

@class StackController;
@interface PlaylistItemTableViewController : CoreDataCustomTableViewController
                                                            <UISearchBarDelegate,
                                                            UITableViewDataSource,
                                                            UITableViewDelegate,
                                                            UITextFieldDelegate,
                                                            MGSwipeTableCellDelegate>
{
    StackController *stackController;
}

@property (nonatomic, strong) Playlist *playlist;
@property (strong, nonatomic) PlaybackContext *parentVcPlaybackContext;

@property (nonatomic, strong) NSArray *originalLeftBarButtonItems;
@property (nonatomic, strong) NSArray *originalRightBarButtonItems;
@property (nonatomic, strong) UINavigationItem *navBar;

@end
