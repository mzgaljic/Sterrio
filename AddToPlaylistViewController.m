//
//  AddToPlaylist.m
//  Sterrio
//
//  Created by Mark Zgaljic on 5/21/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AddToPlaylistViewController.h"
#import "AllPlaylistsDataSource.h"
#import "CoreDataManager.h"
#import "MZTableViewCell.h"
#import "MyAlerts.h"
#import "PlaylistItem+Utilities.h"
#import "AppEnvironmentConstants.h"
#import "SpotlightHelper.h"
#import "SongPlayerCoordinator.h"
#import "MusicPlaybackController.h"
#import "MZInterstitialAd.h"
#import "SDCAlertController.h"
#import "PlaylistItem+Utilities.h"

@interface AddToPlaylistViewController ()
@property (nonatomic, strong) SSBouncyButton *centerButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSManagedObject *entity;
@property (nonatomic, strong) AllPlaylistsDataSource *tableViewDataSourceAndDelegate;
@property (nonatomic, strong) SDCAlertController *createPlaylistAlert;

@property (nonatomic, strong) UISwitch *hideFromLibSwitch;

@property (nonatomic, strong) UIImageView *navHairline;  //for the 'extended navigation bar'
//the toolbar beneath the nav bar, giving it the 'extended' look.
@property (nonatomic, strong) UIToolbar *segmentbar;
@end

@implementation AddToPlaylistViewController

- (instancetype)initWithSong:(Song *)aSong
{
    if(self = [super init]) {
        _entity = aSong;
    }
    return self;
}

- (void)dismiss
{
    _centerButton = nil;
    _delegate = nil;
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissAfterSave
{
    _centerButton = nil;
    _delegate = nil;
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    UIViewController *grandParentVc = self.presentingViewController.presentingViewController;
    [grandParentVc dismissViewControllerAnimated:YES completion:^{
        if([MusicPlaybackController nowPlayingSong]) {
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
        }
    }];
    
    [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerCanIgnoreToolbar];
    [AppEnvironmentConstants incrementNumTimesUserAddedSongToLibCount];
    MainScreenViewController *mainScreenVc = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).mainVC;
    [[MZInterstitialAd sharedInstance] presentIfReadyWithRootVc:(UIViewController *)mainScreenVc
                                              withDismissAction:nil];
}

#pragma mark - VC life cycle
- (void)dealloc
{
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([AddToPlaylistViewController class]));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:YES];
    self.title = @"Add to a Playlist";
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tableView.allowsSelectionDuringEditing = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self establishTableViewDataSource];
    
    // find the hairline below the navigationBar
    for (UIView *aView in self.navigationController.navigationBar.subviews) {
        for (UIView *bView in aView.subviews) {
            if ([bView isKindOfClass:[UIImageView class]] &&
                bView.bounds.size.width == self.navigationController.navigationBar.frame.size.width &&
                bView.bounds.size.height < 2) {
                self.navHairline = (UIImageView *)bView;
            }
        }
    }
    self.segmentbar = [self createExtendedNavToolbar];
    [self.view addSubview:self.segmentbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //due to the extended nav bar effect, i'm overriding the nav bar image
    CGRect navBarFrame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.bounds.size.height + [AppEnvironmentConstants statusBarHeight]);
    UIImage *navBarImg = [AppEnvironmentConstants navBarBackgroundImageWithoutGradientFromFrame:navBarFrame];
    [self.navigationController.navigationBar setBackgroundImage:navBarImg
                                                  forBarMetrics:UIBarMetricsDefault];
    
    //make toolbar translucent
    self.segmentbar.translucent = NO;
    UIImage *toolBarImg = [AppEnvironmentConstants navBarBackgroundImageWithoutGradientFromFrame:self.segmentbar.frame];
    [self.segmentbar setBackgroundImage:toolBarImg
                     forToolbarPosition:UIToolbarPositionAny
                             barMetrics:UIBarMetricsDefault];
    self.navHairline.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self presentCenterButtonAnimated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navHairline.hidden = NO;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    //so table content doesnt get covered by the extended nav bar. (not sure why but /2 looks great.)
    self.tableView.contentInset = UIEdgeInsetsMake(self.segmentbar.frame.size.height, 0, 0, 0);
}

- (void)establishTableViewDataSource
{
    NSString *cellReuseId = @"PlaylistCell";
    short srcType = PLAYLIST_DATA_SRC_TYPE_AddSongToPlaylist;
    AllPlaylistsDataSource *delegate;
    delegate = [[AllPlaylistsDataSource alloc] initWithPlaylisttDataSourceType:srcType
                                                   searchBarDataSourceDelegate:nil];
    self.tableViewDataSourceAndDelegate = delegate;
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = nil;
    self.tableViewDataSourceAndDelegate.cellReuseId = cellReuseId;
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = [MZCommons generateTapPlusToCreateNewPlaylistText];
    self.tableViewDataSourceAndDelegate.actionablePlaylistDelegate = self;
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
    self.tableDataSource = self.tableViewDataSourceAndDelegate;
    
    //this VC is not tied to storyboard, so we need to set the cellReuseId somewhere...
    [self.tableView registerClass:[MZTableViewCell class] forCellReuseIdentifier:cellReuseId];
}

#pragma mark - ActionablePlaylistDataSourceDelegate
- (void)userSelectedPlaylist:(Playlist *)selectedPlaylist
{
    if([_entity isMemberOfClass:[Song class]]) {
        Song *song = (Song *)_entity;
        if(_hideFromLibSwitch.isOn) {
            song.smartSortSongName = nil;
        }
        [self addSongToPlaylistAndSave:selectedPlaylist];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MZForceMainVcTabsToUpdateDatasources
                                                        object:nil];
    [self dismissAfterSave];
}

#pragma mark - Creating New Playlist
- (void)displayCreatePlaylistAlert
{
    __weak AddToPlaylistViewController *weakself = self;
    _createPlaylistAlert = [SDCAlertController alertControllerWithTitle:@"New Playlist"
                                                                message:nil
                                                         preferredStyle:SDCAlertControllerStyleAlert];
    
    [_createPlaylistAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
        int minFontSize = 17;
        if(fontSize < minFontSize)
            fontSize = minFontSize;
        UIFont *myFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:fontSize];
        textField.font = myFont;
        textField.placeholder = @"Name me";
        textField.returnKeyType = UIReturnKeyDone;
        textField.delegate = weakself;  //delegate for the textField
        [textField addTarget:weakself
                      action:@selector(alertTextFieldTextHasChanged:)
            forControlEvents:UIControlEventEditingChanged];
    }];
    [_createPlaylistAlert addAction:[SDCAlertAction actionWithTitle:@"Cancel"
                                                              style:SDCAlertActionStyleDefault
                                                            handler:^(SDCAlertAction *action) {
                                                                //dont do anything
                                                                currNewPlaylistAlertTextFieldText = @"";
                                                                return;
                                                            }]];
    SDCAlertAction *createAction = [SDCAlertAction actionWithTitle:@"Create"
                                                             style:SDCAlertActionStyleRecommended
                                                           handler:^(SDCAlertAction *action) {
                                                               [weakself handleCreateAlertButtonActionWithPlaylistName:currNewPlaylistAlertTextFieldText];
                                                               currNewPlaylistAlertTextFieldText = @"";
                                                           }];
    createAction.enabled = NO;
    [_createPlaylistAlert addAction:createAction];
    [_createPlaylistAlert presentWithCompletion:nil];
}

static NSString *currNewPlaylistAlertTextFieldText;
- (void)alertTextFieldTextHasChanged:(UITextField *)sender
{
    if (_createPlaylistAlert)
    {
        currNewPlaylistAlertTextFieldText = sender.text;
        
        NSString *tempString = [currNewPlaylistAlertTextFieldText copy];
        tempString = [tempString removeIrrelevantWhitespace];
        BOOL enableCreateButton = (tempString.length != 0);
        UIAlertAction *createAction = _createPlaylistAlert.actions.lastObject;
        createAction.enabled = enableCreateButton;
    }
}

- (void)handleCreateAlertButtonActionWithPlaylistName:(NSString *)playlistName
{
    playlistName = [playlistName removeIrrelevantWhitespace];
    
    if(playlistName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    NSManagedObjectContext *mainContext = [CoreDataManager context];
    Playlist *playlist = [Playlist createNewPlaylistWithName:playlistName
                                            inManagedContext:mainContext];
    
    if([_entity isMemberOfClass:[Song class]]) {
        Song *song = (Song *)_entity;
        int const firstIndex = 0;
        [PlaylistItem createNewPlaylistItemWithCorrespondingPlaylist:playlist
                                                                song:song
                                                     indexInPlaylist:firstIndex
                                                    inManagedContext:mainContext];
    }
    NSError *error;
    if ([mainContext save:&error] == NO) {
        //save failed
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_PlaylistCreationHasFailed];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)alertTextField
{
    __weak AddToPlaylistViewController *weakself = self;
    [_createPlaylistAlert dismissWithCompletion:^{
        [weakself handleCreateAlertButtonActionWithPlaylistName:alertTextField.text];
        currNewPlaylistAlertTextFieldText = @"";
    }];
    
    return YES;
}

#pragma mark - Center button logic
- (void)presentCenterButtonAnimated
{
    [self.centerButton removeFromSuperview];
    self.centerButton = nil;
    UIImage *img =[MZCommons centerButtonImage];
    img = [UIImage colorOpaquePartOfImage:[AppEnvironmentConstants appTheme].mainGuiTint :img];
    self.centerButton = [[SSBouncyButton alloc] initAsImage];
    [self.centerButton setImage:img forState:UIControlStateNormal];
    [self.centerButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    [self.centerButton addTarget:self
                          action:@selector(tabBarAddButtonWithDelay)
                forControlEvents:UIControlEventTouchUpInside];
    int btnDiameter = img.size.width;
    CGRect beginFrame = CGRectMake(self.view.frame.size.width/2 - btnDiameter/2,
                                   self.view.frame.size.height,
                                   btnDiameter,
                                   btnDiameter);
    CGRect endFrame = CGRectMake(beginFrame.origin.x,
                                 beginFrame.origin.y - MZTabBarHeight,
                                 btnDiameter,
                                 btnDiameter);
    self.centerButton.frame = beginFrame;
    [self.centerButton setBackgroundColor:[UIColor whiteColor]];
    float cornerRadius = self.centerButton.frame.size.height / 2;
    [self.centerButton.layer setCornerRadius:cornerRadius];
    [self.view addSubview:self.centerButton];
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.55
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.centerButton.frame = endFrame;
                     }
                     completion:nil];
}

- (void)tabBarAddButtonWithDelay
{
    [self performSelector:@selector(tabBarAddButtonPressed) withObject:nil afterDelay:0.2];
}

- (void)tabBarAddButtonPressed
{
    [self displayCreatePlaylistAlert];
}

static BOOL hidingCenterBtnAnimationIsDone = YES;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    hidingCenterBtnAnimationIsDone = NO;
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:1
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.centerButton.alpha = 0;
                         [self.centerButton removeFromSuperview];
                     } completion:^(BOOL finished) {
                         hidingCenterBtnAnimationIsDone = YES;
                     }];
    
    [self setNeedsStatusBarAppearanceUpdate];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustCenterBtnFrameAfterRotation];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)adjustCenterBtnFrameAfterRotation
{
    int btnDiameter = self.centerButton.frame.size.height;
    int viewWidth = self.view.frame.size.width;
    int viewHeight = self.view.frame.size.height;
    CGRect oldFrame = CGRectMake((viewWidth/2) - (btnDiameter/2),
                                 viewHeight,
                                 btnDiameter,
                                 btnDiameter);
    CGRect newFrame = CGRectMake((viewWidth/2) - (btnDiameter/2),
                                 viewHeight - MZTabBarHeight,
                                 btnDiameter,
                                 btnDiameter);
    self.centerButton.frame = oldFrame;
    
    [UIView animateWithDuration:0.35
                          delay:0
         usingSpringWithDamping:0.55
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         if(! hidingCenterBtnAnimationIsDone){
                             [self.centerButton removeFromSuperview];
                         }
                         [self.view addSubview:self.centerButton];
                         self.centerButton.alpha = 1;
                         self.centerButton.frame = newFrame;
                     }
                     completion:nil];
}

#pragma mark - fetching and sorting
- (void)initFetchResultsController
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
    request.predicate = nil;  //means i want all of the playlists
    [request setFetchBatchSize:MZDefaultCoreDataFetchBatchSize];
    [request setPropertiesToFetch:@[@"playlistName"]];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistName"
                                                                     ascending:NO];
    
    request.sortDescriptors = @[sortDescriptor];
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

#pragma mark - Utils
- (void)addSongToPlaylistAndSave:(Playlist *)playlist
{
    [self.delegate willSaveSongToPlaylistWithoutAddingToGeneralLib];
    NSMutableSet *set = [NSMutableSet setWithSet:playlist.playlistItems];
    
    //index at the end of the playlist (if imagined conceptually as an array)
    short nextEmptyIndexInPlaylist = set.count;
    PlaylistItem *newItem = [PlaylistItem createNewPlaylistItemWithCorrespondingPlaylist:playlist
                                                                       song:(Song *)_entity
                                                            indexInPlaylist:nextEmptyIndexInPlaylist
                                                           inManagedContext:[CoreDataManager context]];
    [set addObject:newItem];
    playlist.playlistItems = set;
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    [self commitSongToCoreData];
}

/*
- (void)addAlbumToPlaylistAndSave(Playlist *)Playlist
{
    
}
 */

- (void)commitSongToCoreData
{
    NSError *error;
    if ([[CoreDataManager context] save:&error] == NO) {
        //save failed
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongSaveHasFailed];
    }
    else
    {
        //save success
        [SpotlightHelper addSongToSpotlightIndex:(Song *)_entity];
        [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
        
        //now lets go the extra mile and try to merge here.
        CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
        if(ensemble.isLeeched)
        {
            [ensemble mergeWithCompletion:^(NSError *error) {
                if(error){
                    NSLog(@"Saved song to playlist-only, but couldnt merge.");
                } else{
                    NSLog(@"Just Merged after saving song to playlist-only.");
                    [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                }
            }];
        }
    }
    [self.delegate didSaveSongToPlaylistWithoutAddingToGeneralLib];
}

- (UIToolbar *)createExtendedNavToolbar
{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbar.clipsToBounds = YES;  //removes the hairline above the toolbar.
    
    UIBarButtonItem *flexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 10.0f, self.view.frame.size.width, 21.0f)];
    [label setFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:17]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[AppEnvironmentConstants appTheme].navBarToolbarTextTint];
    [label setText:@"Only visible in selected playlist"];
    [label setTextAlignment:NSTextAlignmentRight];
    UIBarButtonItem *labelBtn = [[UIBarButtonItem alloc] initWithCustomView:label];
    
    if(_hideFromLibSwitch == nil) {
        _hideFromLibSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [_hideFromLibSwitch setOn:NO];  //set default value
    }
    UIBarButtonItem *switchBarBtn = [[UIBarButtonItem alloc] initWithCustomView:_hideFromLibSwitch];
    [toolbar setItems:@[flexSpacer, labelBtn, switchBarBtn]];
    return toolbar;
}
@end
