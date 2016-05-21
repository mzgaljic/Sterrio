//
//  ExistingAlbumPickerTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ExistingAlbumPickerTableViewController.h"
#import "CoreDataManager.h"
#import "AppEnvironmentConstants.h"
#import "Album.h"
#import "MySearchBar.h"
#import "AllAlbumsDataSource.h"

@interface ExistingAlbumPickerTableViewController ()
{
    CGRect originalTableViewFrame;
    Album *usersCurrentAlbum;
    float searchBecomingInactiveAnimationDuration;
}
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) id <ExistingEntityPickerDelegate> delegate;
@property AllAlbumsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation ExistingAlbumPickerTableViewController

- (id)initWithCurrentAlbum:(Album *)anAlbum
existingEntityPickerDelegate:(id <ExistingEntityPickerDelegate>)delegate
{
    UIStoryboard *sb = [MZCommons mainStoryboard];
    ExistingAlbumPickerTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"browseExistingAlbumsVC"];
    self = vc;
    if (self) {
        searchBecomingInactiveAnimationDuration = 0.3;
        usersCurrentAlbum = anAlbum;
        self.delegate = delegate;
    }
    return self;
}

- (void)establishTableViewDataSourceUsingSelectedAlbum:(Album *)album
{
    short srcType = ALBUM_DATA_SRC_TYPE_Single_Album_Picker;
    self.tableViewDataSourceAndDelegate = [[AllAlbumsDataSource alloc] initWithAlbumDataSourceType:srcType
                                                                                     selectedAlbum:album searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = self.playbackContext;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"existingAlbumCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = [MZCommons attributedStringFromString:@"No Albums"];
    self.tableViewDataSourceAndDelegate.actionableAlbumDelegate = self;
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
    self.tableDataSource = self.tableViewDataSourceAndDelegate;
}


#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    //order of calls matters here...
    self.searchBar = [self.tableViewDataSourceAndDelegate setUpSearchBar];
    [super setSearchBar:self.searchBar];
    [super viewWillAppear:animated];
    self.title = @"All Albums";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    originalTableViewFrame = CGRectNull;
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self establishTableViewDataSourceUsingSelectedAlbum:usersCurrentAlbum];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)dealloc
{
    [super prepareFetchedResultsControllerForDealloc];
    self.delegate = nil;
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
                                                        object:[NSNumber numberWithBool:NO]];
}

#pragma mark - ActionableAlbumDataSourceDelegate implementation
- (void)userDidSelectAlbumFromSinglePicker:(Album *)chosenAlbum
{
    [self.delegate existingAlbumHasBeenChosen:chosenAlbum];
    
    if(self.searchBar.isFirstResponder){
        [self.searchBar resignFirstResponder];
        [self searchBarIsBecomingInactive];
        [self popAnimatedWithDelay];
    }
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)popAnimatedWithDelay
{
    double delayInSeconds = 0.35;
    __weak ExistingAlbumPickerTableViewController *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - Rotation and status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setNeedsStatusBarAppearanceUpdate];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    if(_tableViewDataSourceAndDelegate.displaySearchResults)
        return YES;
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        return YES;
    else
        return NO;
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
