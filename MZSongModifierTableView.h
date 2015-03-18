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
#import "MyTableViewController.h"
#import "MZSongModifierDelegate.h"

#import <MSCellAccessory.h>
#import <FXImageView/UIImage+FX.h>

//This class breaks so much MVC it's not even funny. it's like a sin...but it works lol
@interface MZSongModifierTableView : UITableView <UIActionSheetDelegate,
                                                UINavigationControllerDelegate,
                                                UIImagePickerControllerDelegate,
                                                UITableViewDelegate,
                                                UITableViewDataSource>

@property (nonatomic, strong) Song *songIAmEditing;
@property (nonatomic, assign) NSInteger lastTappedRow;  //only used for section 0

@property (nonatomic, strong) UIViewController *VC;
@property (nonatomic, assign) id<MZSongModifierDelegate>theDelegate;

//Must implement these for the table to work properly
- (void)initWasCalled;
- (void)preDealloc;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)didReceiveMemoryWarning;

- (void)provideDefaultAlbumArt:(UIImage *)image;

- (void)canShowAddToLibraryButton;

//optional but very important methods
- (void)cancelEditing;
- (void)songEditingWasSuccessful;

@end
