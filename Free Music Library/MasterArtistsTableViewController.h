//
//  MasterArtistsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "Album.h"
#import "Song+Utilities.h"
#import "MusicPlaybackController.h"
#import "UIColor+LighterAndDarker.h"
#import "CoreDataCustomTableViewController.h"
#import "MainScreenViewControllerDelegate.h"
#import "ActionableArtistDataSourceDelegate.h"

@interface MasterArtistsTableViewController : CoreDataCustomTableViewController
                                                            <SearchBarDataSourceDelegate,
                                                            ActionableArtistDataSourceDelegate,
                                                            MainScreenViewControllerDelegate>

@end
