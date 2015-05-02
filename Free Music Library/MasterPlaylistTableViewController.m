//
//  MasterPlaylistTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterPlaylistTableViewController.h"
#import "AllPlaylistsDataSource.h"
#import "PlayableBaseDataSource.h"
#import "SDCAlertController.h"

@interface MasterPlaylistTableViewController ()
{
    CGRect originalTableViewFrame;
}
@property(nonatomic, strong) SDCAlertController *createPlaylistAlert;
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property AllPlaylistsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation MasterPlaylistTableViewController
@synthesize createPlaylistAlert = _createPlaylistAlert;

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

- (void)establishTableViewDataSource
{
    short srcType = PLAYLIST_DATA_SRC_TYPE_Default;
    AllPlaylistsDataSource *delegate;
    delegate = [[AllPlaylistsDataSource alloc] initWithPlaylisttDataSourceType:srcType
                                                   searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate = delegate;
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = nil;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"PlaylistItemCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = @"No Playlists";
    self.tableViewDataSourceAndDelegate.actionablePlaylistDelegate = self;
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
        __weak MasterPlaylistTableViewController *weakself = self;
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
    return @"Search My Playlists";
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
                                                        object:@YES];
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

#pragma mark - ActionableArtistDataSourceDelegate implementation
static BOOL didForcefullyCloseSearchBarBeforeSegue = NO;
static NSString *lastQueryBeforeForceClosingSearchBar;

- (void)performEditSegueWithArtist:(Artist *)artistToBeEdited
{
    
}
- (void)performPlaylistDetailVCSegueWithPlaylist:(Playlist *)aPlaylist
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@YES];
    if(self.searchBar.isFirstResponder){
        lastQueryBeforeForceClosingSearchBar = self.searchBar.text;
        [self.searchBar resignFirstResponder];
        [self searchBarIsBecomingInactive];
        [self popAndSegueWithDelayUsingPlaylist:aPlaylist];
    }
    else
        [self performSegueWithIdentifier:@"playlistItemSegue" sender:aPlaylist];
}

- (void)popAndSegueWithDelayUsingPlaylist:(Playlist *)aPlaylist
{
    double delayInSeconds = 0.25;
    __weak MasterPlaylistTableViewController *weakself = self;
    __weak Playlist *weakPlaylist = aPlaylist;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself.navigationController popViewControllerAnimated:YES];
        [weakself performSegueWithIdentifier:@"playlistItemSegue" sender:weakPlaylist];
        didForcefullyCloseSearchBarBeforeSegue = YES;
        [weakself.tableViewDataSourceAndDelegate clearSearchResultsDataSource];
        [weakself.tableViewDataSourceAndDelegate searchResultsShouldBeDisplayed:NO];
    });
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:(Playlist *)sender];
    }
    else if([[segue identifier] isEqualToString:@"playlistSongPickerSegue"]){
        UINavigationController *navController = [segue destinationViewController];
        [navController.childViewControllers[0] setReceiverPlaylist:(Playlist *)sender];
    }
}

- (void)displayCreatePlaylistAlert
{
    __weak MasterPlaylistTableViewController *weakself = self;
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
                                                                currentAlertTextFieldText = @"";
                                                                return;
                                                            }]];
    SDCAlertAction *createAction = [SDCAlertAction actionWithTitle:@"Create"
                                                             style:SDCAlertActionStyleRecommended
                                                           handler:^(SDCAlertAction *action) {
                                                               [weakself handleCreateAlertButtonActionWithPlaylistName:currentAlertTextFieldText];
                                                               currentAlertTextFieldText = @"";
                                                           }];
    createAction.enabled = NO;
    [_createPlaylistAlert addAction:createAction];
    _createPlaylistAlert.view.tintColor = [UIColor defaultAppColorScheme];
    [_createPlaylistAlert presentWithCompletion:nil];
}

static NSString *currentAlertTextFieldText;
- (void)alertTextFieldTextHasChanged:(UITextField *)sender
{
    if (_createPlaylistAlert)
    {
        currentAlertTextFieldText = sender.text;
        
        NSString *tempString = [currentAlertTextFieldText copy];
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
    
    Playlist *myNewPlaylist = [Playlist createNewPlaylistWithName:playlistName inManagedContext:[CoreDataManager context]];
    [self performSegueWithIdentifier:@"playlistSongPickerSegue" sender:myNewPlaylist];
}

- (void)tabBarAddButtonPressed
{
    [self displayCreatePlaylistAlert];
}

- (BOOL)textFieldShouldReturn:(UITextField *)alertTextField
{
    __weak MasterPlaylistTableViewController *weakself = self;
    [_createPlaylistAlert dismissWithCompletion:^{
        [weakself handleCreateAlertButtonActionWithPlaylistName:alertTextField.text];
        currentAlertTextFieldText = @"";
    }];
    
    return YES;
}

#pragma mark - Go To Settings
- (void)settingsButtonTapped
{
    [self performSegueWithIdentifier:@"settingsSegue" sender:self];
}

#pragma mark - Rotation methods
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
    request.predicate = nil;  //means i want all of the playlists
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistName"
                                                                     ascending:YES
                                                                      selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
