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
#import "NavBarViewControllerDelegate.h"
#import <FXImageView/UIImage+FX.h>
#import <MSCellAccessory.h>

@interface MasterAlbumsTableViewController : CoreDataCustomTableViewController
                                                                <UISearchBarDelegate,
                                                                UITableViewDataSource,
                                                                UITableViewDelegate,
                                                                NavBarViewControllerDelegate>
{
    StackController *stackController;
}
@end
