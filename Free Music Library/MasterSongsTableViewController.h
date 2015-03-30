//
//  MasterSongsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSString+smartSort.h"
#import "CoreDataCustomTableViewController.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "Song+Utilities.h"
#import "SongTableViewFormatter.h"
#import "PreferredFontSizeUtility.h"
#import "UIImage+colorImages.h"
#import "UIColor+ColorComparison.h"
#import "MusicPlaybackController.h"
#import "MasterSongEditorViewController.h"
#import "MainScreenViewControllerDelegate.h"
#import <FXImageView/UIImage+FX.h>
#import "PlaybackContext.h"
#import "AllSongsDataSource.h"

@class StackController;
@interface MasterSongsTableViewController : CoreDataCustomTableViewController
                                                            <SearchBarDataSourceDelegate,
                                                            EditableSongDataSourceDelegate,
                                                            MainScreenViewControllerDelegate,
                                                            MGSwipeTableCellDelegate>
@end
