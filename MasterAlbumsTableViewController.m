//
//  MasterAlbumsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterAlbumsTableViewController.h"
#import "AlbumAlbumArt+Utilities.h"

@interface MasterAlbumsTableViewController()
{
    CGRect originalTableViewFrame;
}
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property AllAlbumsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation MasterAlbumsTableViewController

#pragma mark - NavBarItem Delegate
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

- (UIBarButtonItem *)makeBarButtonItemNormal:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = true;
    return barButton;
}

- (void)establishTableViewDataSource
{
    self.tableViewDataSourceAndDelegate = [[AllAlbumsDataSource alloc] initWithAlbumDataSourceType:ALBUM_DATA_SRC_TYPE_Default
                                                                       searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = self.playbackContext;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"AlbumItemCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = @"No Albums";
    self.tableViewDataSourceAndDelegate.actionableAlbumDelegate = self;
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
        
        double delayInSeconds = 0.25;
        __weak MasterAlbumsTableViewController *weakself = self;
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
    return @"Search My Albums";
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
                                                        object:@NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated
                                                        object:@NO];
}

#pragma mark - ActionableAlbumDataSourceDelegate implementation
static BOOL didForcefullyCloseSearchBarBeforeSegue = NO;
static NSString *lastQueryBeforeForceClosingSearchBar;

- (void)performEditSegueWithAlbum:(Album *)albumToBeEdited  {}

- (void)performAlbumDetailVCSegueWithAlbum:(Album *)anAlbum
{
    if(self.searchBar.isFirstResponder){
        lastQueryBeforeForceClosingSearchBar = self.searchBar.text;
        [self.searchBar resignFirstResponder];
        [self searchBarIsBecomingInactive];
        [self popAndSegueWithDelayUsingAlbum:anAlbum];
    }
    else
        [self performSegueWithIdentifier:@"albumItemSegue" sender:anAlbum];
}

- (void)popAndSegueWithDelayUsingAlbum:(Album *)anAlbum
{
    double delayInSeconds = 0.25;
    __weak MasterAlbumsTableViewController *weakself = self;
    __weak Album *weakAlbum = anAlbum;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself.navigationController popViewControllerAnimated:YES];
        [weakself performSegueWithIdentifier:@"albumItemSegue" sender:weakAlbum];
        didForcefullyCloseSearchBarBeforeSegue = YES;
    });
}

#pragma mark - other stuff
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"albumItemSegue"]){
        [[segue destinationViewController] setAlbum:(Album *)sender];
        [[segue destinationViewController] setParentVcPlaybackContext:self.playbackContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:[NSNumber numberWithBool:YES]];
    }
}

#pragma mark - album editing
- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"AlbumEditDone"]){
        //leave editing mode
        //no observer set up!
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AlbumEditDone" object:nil];
    }
}

- (void)albumWasSavedDuringEditing:(NSNotification *)notification
{
    /*
     if([notification.name isEqualToString:@"AlbumSavedDuringEdit"]){
     [self commitNewSongChanges:(Song *)notification.object];
     }
     */
}

- (void)commitNewAlbumChanges:(Artist *)changedAlbum
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

#pragma mark - Adding music to library
- (void)tabBarAddButtonPressed
{
    [self performSegueWithIdentifier:@"addMusicToLibSegue" sender:nil];
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    request.predicate = nil;  //means i want all of the albums
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
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