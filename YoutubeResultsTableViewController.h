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
#import "UIImageView+WebCache.h"
#import "MyTableViewController.h"

@interface YoutubeResultsTableViewController : MyTableViewController <UISearchBarDelegate, YouTubeVideoSearchDelegate, SDWebImageManagerDelegate>
@end
