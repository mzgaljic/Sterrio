//
//  ExistingArtistPickerTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ExistingArtistPickerTableViewController.h"
#import "CoreDataManager.h"
#import "AppEnvironmentConstants.h"
#import "Artist.h"
#import "MySearchBar.h"
#import "AllArtistsDataSource.h"
#import "NSString+smartSort.h"

@interface ExistingArtistPickerTableViewController ()
{
    CGRect originalTableViewFrame;
    Artist *usersCurrentArtist;
    float searchBecomingInactiveAnimationDuration;
}
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) id <ExistingEntityPickerDelegate> delegate;
@property AllArtistsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation ExistingArtistPickerTableViewController

- (id)initWithCurrentArtist:(Artist *)anArtist
existingEntityPickerDelegate:(id <ExistingEntityPickerDelegate>)delegate
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ExistingArtistPickerTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"browseExistingArtistsVC"];
    self = vc;
    if (self) {
        searchBecomingInactiveAnimationDuration = 0.3;
        usersCurrentArtist = anArtist;
        self.delegate = delegate;
    }
    return self;
}

- (void)establishTableViewDataSourceUsingSelectedArtist:(Artist *)artist
{
    short srcType = ARTIST_DATA_SRC_TYPE_Single_Artist_Picker;
    AllArtistsDataSource *src = [[AllArtistsDataSource alloc] initWithArtistDataSourceType:srcType
                                                                            selectedArtist:artist searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate = src;
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = self.playbackContext;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"existingArtistItemPickerCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = [[NSAttributedString alloc] initWithString:@"No Artists"];
    self.tableViewDataSourceAndDelegate.actionableArtistDelegate = self;
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
    self.title = @"All Artists";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    originalTableViewFrame = CGRectNull;
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self establishTableViewDataSourceUsingSelectedArtist:usersCurrentArtist];
}

- (void)dealloc
{
    [super prepareFetchedResultsControllerForDealloc];
    self.delegate = nil;
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
}

#pragma mark - ActionableAlbumDataSourceDelegate implementation
- (void)userDidSelectArtistFromSinglePicker:(Artist *)chosenArtist
{
    [self.delegate existingArtistHasBeenChosen:chosenArtist];
    
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
    __weak ExistingArtistPickerTableViewController *weakself = self;
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
    request.predicate = nil;  //means i want all of the artists
    
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
