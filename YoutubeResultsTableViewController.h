//
//  YoutubeResultsTableViewController.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "YouTubeVideoQueryDelegate.h"
#import "UIImageView+WebCache.h"
#import "MyTableViewController.h"
#import "SongPlayerCoordinator.h"
@class StackController;

@interface YoutubeResultsTableViewController : MyTableViewController <UISearchBarDelegate,
                                                                    YouTubeServiceSearchingDelegate,
                                                                    SDWebImageManagerDelegate>
{
    StackController *stackController;
}
+ (instancetype)initWithSearchQuery:(NSString *)query replacementObjId:(NSManagedObjectID *)objId;
@end
