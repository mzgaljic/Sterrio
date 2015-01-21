//
//  MZSongModifierTableView.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
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
#import "MyTableViewController.h"

@interface MZSongModifierTableView : UITableView <UIActionSheetDelegate,
                                                UINavigationControllerDelegate,
                                                UIImagePickerControllerDelegate>

@property (nonatomic, strong) Song *songIAmEditing;
@property (nonatomic, assign) NSInteger lastTappedRow;  //only used for section 0

@property (nonatomic, strong) UINavigationController *navController;

- (void)cancelEditing;
- (void)songEditingWasSuccessful;

@end
