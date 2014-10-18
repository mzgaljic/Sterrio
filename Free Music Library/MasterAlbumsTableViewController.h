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
#import "YouTubeMoviePlayerSingleton.h"
#import "UIImage+colorImages.h"
#import "CoreDataTableViewController.h"
#import "UIColor+SystemTintColor.h"

@interface MasterAlbumsTableViewController : CoreDataTableViewController <UISearchBarDelegate>
{
    StackController *stackController;
}
@end
