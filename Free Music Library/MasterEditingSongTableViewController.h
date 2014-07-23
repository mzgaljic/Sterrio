//
//  MasterEditingSongTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "EditableCellTableViewController.h"

@interface MasterEditingSongTableViewController : UITableViewController

@property (nonatomic, strong) Song *songIAmEditing;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (nonatomic, assign) NSInteger lastTappedRow;  //only used for section 0

- (IBAction)leftBarButtonTapped:(id)sender;
- (IBAction)rightBarButtonTapped:(id)sender;

@end
