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

@interface AddToPlaylistViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSManagedObject *entity;
@property (nonatomic, strong) AllPlaylistsDataSource *tableViewDataSourceAndDelegate;
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
    //grandParentNav is the navigation controller that shows the youtube search results, video preview, etc.
    UINavigationController *parentNav = (UINavigationController *)self.parentViewController;
    UINavigationController *grandParentNav = (UINavigationController *)parentNav.parentViewController;
    [grandParentNav dismissViewControllerAnimated:YES completion:nil];
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
        [self.delegate didSaveSongToPlaylistWithoutAddingToGeneralLib];
        
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
}
@end
