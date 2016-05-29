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
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSManagedObject *entity;
@property (nonatomic, strong) AllPlaylistsDataSource *tableViewDataSourceAndDelegate;
@property(nonatomic, strong) SDCAlertController *createPlaylistAlert;
@end

@implementation AddToPlaylistViewController

#pragma mark - Custom Initializers
- (instancetype)initWithSong:(Song *)aSong
{
    if(self = [super init]) {
        _entity = aSong;
    }
    return self;
}

- (void)dismiss
{
    self.delegate = nil;
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissAfterSave
{
    self.delegate = nil;
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

- (void)userSelectedPlaylist:(Playlist *)selectedPlaylist
{
    if([_entity isMemberOfClass:[Song class]]) {
        Song *song = (Song *)_entity;
        song.smartSortSongName = nil;
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
@end
