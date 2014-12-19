//
//  MasterEditingSongTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import "Song+Utilities.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "EditableCellTableViewController.h"
#import "SDCAlertView.h"
#import "PreferredFontSizeUtility.h"
#import "NSString+WhiteSpace_Utility.h"
#import "NSString+HTTP_Char_Escape.h"
#import "GenreConstants.h"
#import "MusicPlaybackController.h"

#import "ExistingAlbumPickerTableViewController.h"
#import "ExistingArtistPickerTableViewController.h"
#import "GenrePickerTableViewController.h"

@interface MasterEditingSongTableViewController : UITableViewController <UIActionSheetDelegate,
                                                                        UINavigationControllerDelegate,
                                                                        UIImagePickerControllerDelegate>

@property (nonatomic, strong) Song *songIAmEditing;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (nonatomic, assign) NSInteger lastTappedRow;  //only used for section 0

- (IBAction)leftBarButtonTapped:(id)sender;
- (IBAction)rightBarButtonTapped:(id)sender;

@end
