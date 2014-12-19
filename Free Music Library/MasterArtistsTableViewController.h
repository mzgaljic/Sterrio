//
//  MasterArtistsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import "AppEnvironmentConstants.h"
#import "Album.h"
#import "Song+Utilities.h"
#import "ArtistTableViewFormatter.h"
#import "NSString+smartSort.h"
#import "SDWebImageManager.h"
#import "MusicPlaybackController.h"

@interface MasterArtistsTableViewController : CoreDataTableViewController <UISearchBarDelegate>

@end
