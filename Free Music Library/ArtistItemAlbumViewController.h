//
//  ArtistItemAlbumViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyViewController.h"
#import "MGSwipeTableCell.h"

@class Artist;
@interface ArtistItemAlbumViewController : MyViewController
                                                    <UITableViewDataSource,
                                                    UITableViewDelegate,
                                                    MGSwipeTableCellDelegate>

@property (strong, nonatomic) Artist *artist;
@property (strong, nonatomic) UIViewController *parentVc;
@property (strong, nonatomic) PlaybackContext *parentVcPlaybackContext;

@end
