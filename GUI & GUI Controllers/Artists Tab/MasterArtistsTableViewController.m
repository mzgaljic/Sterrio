//
//  MasterArtistsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterArtistsTableViewController.h"
#import "AllArtistsDataSource.h"
#import "PlayableBaseDataSource.h"
#import "ArtistItemAlbumViewController.h"

@interface MasterArtistsTableViewController ()
{
    CGRect originalTableViewFrame;
}
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property AllArtistsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation MasterArtistsTableViewController

#pragma mark - MainScreenViewControllerDelegate
- (NSArray *)leftBarButtonItemsForNavigationBar
{
    UIImage *image = [UIImage imageNamed:@"Settings-Line"];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self
                                                                action:@selector(settingsButtonTapped)];
    self.leftBarButtonItems = @[settings];
    return self.leftBarButtonItems;
}

- (NSArray *)rightBarButtonItemsForNavigationBar
{
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    self.editButton = editButton;
    self.rightBarButtonItems = @[editButton];
    return self.rightBarButtonItems;
}

- (void)tabBarAddButtonPressed
{
    [self performSegueWithIdentifier:@"addMusicToLibSegue" sender:nil];
}

- (void)reloadDataSourceBackingThisVc
{
    [self performFetch];
}

#pragma mark - Miscellaneous
- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        //leaving editing mode now
        [self setEditing:NO animated:YES];
        [self.tableView setEditing:NO animated:YES];
    }
    else
    {
        //entering editing mode now
        [self setEditing:YES animated:YES];
        [self.tableView setEditing:YES animated:YES];
    }
}

- (void)establishTableViewDataSource
{
    self.tableViewDataSourceAndDelegate = [[AllArtistsDataSource alloc] initWithArtistDataSourceType:ARTIST_DATA_SRC_TYPE_Default
                                                                       searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = self.playbackContext;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"ArtistItemCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = [MZCommons makeAttributedString:@"No Artists"];
    self.tableViewDataSourceAndDelegate.actionableArtistDelegate = self;
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
    self.tableDataSource = self.tableViewDataSourceAndDelegate;
}

#pragma mark - View Controller life cycle
-(void)viewWillAppear:(BOOL)animated
{
    //order of calls matters here...
    self.searchBar = [self.tableViewDataSourceAndDelegate setUpSearchBar];
    [super setSearchBar:self.searchBar];
    [super viewWillAppear:animated];  //super class reloads visible cells here.
}

- (void)viewDidAppear:(BOOL)animated
{
    if(didForcefullyCloseSearchBarBeforeSegue){
        //done to temporarily disable accidentaly touches during animation....
        //such as tapping the tab bar and crashing the app lol.
        UIView *window = [UIApplication sharedApplication].keyWindow;
        window.userInteractionEnabled = NO;
    }
    
    [super viewDidAppear:animated];
    if(didForcefullyCloseSearchBarBeforeSegue){
        [self.tableViewDataSourceAndDelegate searchResultsShouldBeDisplayed:YES];
        self.searchBar.text = lastQueryBeforeForceClosingSearchBar;
        [self searchBarIsBecomingActive];
        
        double delayInSeconds = 0.3;
        __weak MasterArtistsTableViewController *weakself = self;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakself.searchBar becomeFirstResponder];
            didForcefullyCloseSearchBarBeforeSegue = NO;
            lastQueryBeforeForceClosingSearchBar = nil;
            UIView *window = [UIApplication sharedApplication].keyWindow;
            window.userInteractionEnabled = YES;
        });
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    originalTableViewFrame = CGRectNull;
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForNavigationBar];
    self.navigationItem.leftBarButtonItems = [self leftBarButtonItemsForNavigationBar];
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    //tab bar overlaps part of the table, which causes the scroll indicators to get cut off...
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(self.tableView.scrollIndicatorInsets.top,
                                                 self.tableView.scrollIndicatorInsets.left,
                                                 self.tableView.scrollIndicatorInsets.bottom + MZTabBarHeight,
                                                 self.tableView.scrollIndicatorInsets.right);
    self.tableView.scrollIndicatorInsets = scrollInsets;
    
    [self establishTableViewDataSource];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)dealloc
{
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SearchBarDataSourceDelegate implementation
- (NSString *)placeholderTextForSearchBar
{
    return @"Search My Artists";
}

- (void)searchBarIsBecomingActive
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if(CGRectIsNull(originalTableViewFrame))
        originalTableViewFrame = self.tableView.frame;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.tableView.frame = CGRectMake(0,
                                                           0,
                                                           self.view.frame.size.width,
                                                           self.view.frame.size.height);
                     }
                     completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZMainScreenVCStatusBarAlwaysInvisible
                                                        object:[NSNumber numberWithBool:YES]];
}

- (void)searchBarIsBecomingInactive
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         CGRect viewFrame = self.view.frame;
                         self.tableView.frame = CGRectMake(originalTableViewFrame.origin.x,
                                                           originalTableViewFrame.origin.y,
                                                           viewFrame.size.width,
                                                           viewFrame.size.height);
                     }
                     completion:^(BOOL finished) {
                         originalTableViewFrame = CGRectNull;
                     }];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZMainScreenVCStatusBarAlwaysInvisible
                                                        object:[NSNumber numberWithBool:NO]];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated
                                                        object:@NO];
}

#pragma mark - ActionableArtistDataSourceDelegate implementation
static BOOL didForcefullyCloseSearchBarBeforeSegue = NO;
static NSString *lastQueryBeforeForceClosingSearchBar;

- (void)performEditSegueWithArtist:(Artist *)artistToBeEdited
{
    
}
- (void)performArtistDetailVCSegueWithArtist:(Artist *)anArtist
{
    if(self.searchBar.isFirstResponder){
        lastQueryBeforeForceClosingSearchBar = self.searchBar.text;
        [self.searchBar resignFirstResponder];
        [self searchBarIsBecomingInactive];
        [self popAndSegueWithDelayUsingArtist:anArtist];
    }
    else
        [self performSegueWithIdentifier:@"artistItemSegue" sender:anArtist];
}

- (void)popAndSegueWithDelayUsingArtist:(Artist *)anArtist
{
    double delayInSeconds = 0.25;
    __weak MasterArtistsTableViewController *weakself = self;
    __weak Artist *weakArtist = anArtist;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself.navigationController popViewControllerAnimated:YES];
        [weakself performSegueWithIdentifier:@"artistItemSegue" sender:weakArtist];
        didForcefullyCloseSearchBarBeforeSegue = YES;
    });
}


#pragma mark - other stuff
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"artistItemSegue"]){
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated
                                                            object:@YES];
        [[segue destinationViewController] setArtist:(Artist *)sender];
        [[segue destinationViewController] setParentVc:self];
        [[segue destinationViewController] setParentVcPlaybackContext:self.playbackContext];
    }
}

#pragma mark - artist editing
- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"ArtistEditDone"]){
        //leave editing mode
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ArtistEditDone" object:nil];
    }
}

- (void)artistWasSavedDuringEditing:(NSNotification *)notification
{
    /*
    if([notification.name isEqualToString:@"ArtistSavedDuringEdit"]){
        [self commitNewSongChanges:(Song *)notification.object];
    }
     */
}

- (void)commitNewArtistChanges:(Artist *)changedSong
{
    /*
    if(changedSong){
        [[CoreDataManager sharedInstance] saveContext];
#warning register for the notification: DataManagerDidSaveFailedNotification  (look in CoreDataManager.m)
        
        self.indexOfEditingSong = -1;
        if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
        
        //[self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongSavedDuringEdit" object:nil];
    }
     */
}

#pragma mark - Go To Settings
- (void)settingsButtonTapped
{
    [self performSegueWithIdentifier:@"settingsSegue" sender:self];
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setNeedsStatusBarAppearanceUpdate];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - fetching and sorting
- (void)initFetchResultsController
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
    //means i only want the artists who have at least 1 song which was added to the general libary (so not
    //the songs that were added to 'just a playlist'). Same query in Table data source.
    NSString *predicateFormat = @"(SUBQUERY(standAloneSongs, $song, $song.smartSortSongName != nil).@count > 0) || (SUBQUERY(albums, $album, SUBQUERY($album.albumSongs, $albumSong, $albumSong.smartSortSongName != nil).@count > 0).@count > 0)";
    request.predicate = [NSPredicate predicateWithFormat:predicateFormat];
    [request setFetchBatchSize:MZDefaultCoreDataFetchBatchSize];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortArtistName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    if(self.playbackContext == nil){
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:@""
                                                                   contextId:self.playbackContextUniqueId];
    }
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}


@end