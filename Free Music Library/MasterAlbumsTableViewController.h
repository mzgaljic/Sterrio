//
//  MasterAlbumsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "AlbumItemViewController.h"
#import "Album.h"
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import "CoreDataCustomTableViewController.h"
#import "MusicPlaybackController.h"
#import "SDCAlertView.h"
#import "MainScreenViewControllerDelegate.h"

#import "SearchBarDataSourceDelegate.h"
#import "PlayableBaseDataSource.h"
#import "AllAlbumsDataSource.h"

@interface MasterAlbumsTableViewController : CoreDataCustomTableViewController
                                                                <SearchBarDataSourceDelegate,
                                                                ActionableAlbumDataSourceDelegate,
                                                                MainScreenViewControllerDelegate>
@end
