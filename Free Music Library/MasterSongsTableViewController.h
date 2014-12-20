//
//  MasterSongsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "StackController.h"
#import "NSString+smartSort.h"
#import "CoreDataTableViewController.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "SongItemViewController.h"
#import "MasterEditingSongTableViewController.h"
#import "Song.h"
#import "Song+Utilities.h"
#import "SongTableViewFormatter.h"
#import "PreferredFontSizeUtility.h"
#import "UIImage+colorImages.h"
#import "UIColor+SystemTintColor.h"
#import "UIColor+ColorComparison.h"
#import "MusicPlaybackController.h"
#import "UIViewController+ZoomTransition.h"  //for maximizing and minimizing the video

@class StackController;
@interface MasterSongsTableViewController : CoreDataTableViewController <UISearchBarDelegate>
{
    StackController *stackController;
}

@end
