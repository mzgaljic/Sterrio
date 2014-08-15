//
//  YoutubeResultsTableViewController.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "YouTubeVideoSearchDelegate.h"
#import "YouTubeVideoSearchService.h"
#import "UIImageView+WebCache.h"
#import "UIImage+colorImages.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"
#import "UIColor+LighterAndDarker.h"
#import "UIColor+SystemTintColor.h"
#import "MRProgress.h"
#import "AlbumArtUtilities.h"
#import "SDCAlertView.h"
#import "PreferredFontSizeUtility.h"
#import "YouTubeVideoPlaybackTableViewController.h"

@interface YoutubeResultsTableViewController : UITableViewController <UISearchBarDelegate, YouTubeVideoSearchDelegate, SDWebImageManagerDelegate>

@end
