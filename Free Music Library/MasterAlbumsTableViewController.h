//
//  MasterAlbumsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "StackController.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "AlbumItemViewController.h"
#import "Album.h"
#import "AlbumTableViewFormatter.h"
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import "CoreDataCustomTableViewController.h"
#import "MusicPlaybackController.h"
#import <SDCAlertView.h>
#import "MainScreenViewControllerDelegate.h"
#import <FXImageView/UIImage+FX.h>
#import <MSCellAccessory.h>


#import "SearchBarDataSourceDelegate.h"
#import "PlayableBaseDataSource.h"
#import "AllAlbumsDataSource.h"

@interface MasterAlbumsTableViewController : CoreDataCustomTableViewController
                                                                <SearchBarDataSourceDelegate,
                                                                ActionableAlbumDataSourceDelegate,
                                                                MainScreenViewControllerDelegate,
                                                                MGSwipeTableCellDelegate>
@end
