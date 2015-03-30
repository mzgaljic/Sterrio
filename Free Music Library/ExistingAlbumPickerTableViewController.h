//
//  ExistingAlbumPickerTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "Album.h"
#import "AlbumTableViewFormatter.h"
#import "UIImage+colorImages.h"
#import "CoreDataCustomTableViewController.h"
#import "StackController.h"

@interface ExistingAlbumPickerTableViewController : CoreDataCustomTableViewController
                                                    <UISearchBarDelegate,
                                                    UITableViewDataSource,
                                                    UITableViewDelegate>
{
    StackController *stackController;
}

- (id)initWithCurrentAlbum:(Album *)anAlbum;


@end
