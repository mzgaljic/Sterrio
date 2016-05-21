//
//  AddToPlaylist.m
//  Sterrio
//
//  Created by Mark Zgaljic on 5/21/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AddToPlaylistViewController.h"
#import "AllPlaylistsDataSource.h"

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

#pragma mark - VC life cycle
- (void)dealloc
{
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([AddToPlaylistViewController class]));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
}

- (void)establishTableViewDataSource
{
    short srcType = PLAYLIST_DATA_SRC_TYPE_Default;
    AllPlaylistsDataSource *delegate;
    delegate = [[AllPlaylistsDataSource alloc] initWithPlaylisttDataSourceType:srcType
                                                   searchBarDataSourceDelegate:nil];
    self.tableViewDataSourceAndDelegate = delegate;
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = nil;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"PlaylistItemCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = [MZCommons generateTapPlusToCreateNewPlaylistText];
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
    self.tableDataSource = self.tableViewDataSourceAndDelegate;
}


@end
