//
//  MasterSongsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterSongsTableViewController.h"
#import "AllSongsDataSource.h"

@interface MasterSongsTableViewController ()
{
    CGRect originalTableViewFrame;
}
@property (nonatomic, assign) int indexOfEditingSong;
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, strong) MySearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property AllSongsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation MasterSongsTableViewController
static BOOL haveCheckedCoreDataInit = NO;

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
    self.rightBarButtonItems = @[self.editButton];
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
        
        if(self.leftBarButtonItems.count > 0){
            UIBarButtonItem *leftMostItem = self.leftBarButtonItems[0];
            [self makeBarButtonItemNormal:leftMostItem];
        }
    }
    else
    {
        //entering editing mode now
        [self setEditing:YES animated:YES];
        [self.tableView setEditing:YES animated:YES];

        if(self.leftBarButtonItems.count > 0){
            UIBarButtonItem *leftMostItem = self.leftBarButtonItems[0];
            [self makeBarButtonItemGrey:leftMostItem];
        }
    }
}

- (UIBarButtonItem *)makeBarButtonItemGrey:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = false;
    return barButton;
}

- (UIBarButtonItem *)makeBarButtonItemNormal:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = true;
    return barButton;
}

- (void)establishTableViewDataSource
{
    self.tableViewDataSourceAndDelegate = [[AllSongsDataSource alloc] initWithSongDataSourceType:SONG_DATA_SRC_TYPE_Default
                                                                     searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.playbackContext = self.playbackContext;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"SongItemCell";
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = @"No Songs";
    self.tableViewDataSourceAndDelegate.editableSongDelegate = self;
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
    self.tableDataSource = self.tableViewDataSourceAndDelegate;
}

#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.searchBar = [self.tableViewDataSourceAndDelegate setUpSearchBar];
    
    [super setSearchBar:self.searchBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    originalTableViewFrame = CGRectNull;
    if(!haveCheckedCoreDataInit){
        //need to check if core data even works before i try loading the songs in this VC
        //force core data to attempt to initialze itself by asking for its context
        
        if([CoreDataManager context]){
            haveCheckedCoreDataInit = YES;
        } else{
            [self performSegueWithIdentifier:@"coreDataProblem" sender:nil];
            haveCheckedCoreDataInit = YES;
            return;
        }
    }
    
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    [self establishTableViewDataSource];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    //tab bar overlaps part of the table, which causes the scroll indicators to get cut off...
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(self.tableView.scrollIndicatorInsets.top,
                                                 self.tableView.scrollIndicatorInsets.left,
                                                 self.tableView.scrollIndicatorInsets.bottom + MZTabBarHeight,
                                                 self.tableView.scrollIndicatorInsets.right);
    self.tableView.scrollIndicatorInsets = scrollInsets;
    
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForNavigationBar];
    self.navigationItem.leftBarButtonItems = [self leftBarButtonItemsForNavigationBar];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingModeCompleted:)
                                                 name:@"SongEditDone"
                                               object:nil];
    
    //This is a ghetto version of an official welcome screen.
    if([AppEnvironmentConstants shouldDisplayWelcomeScreen]){
        NSString *msg = @"Thanks for being a beta tester. Bugs may be reported via the settings view or the Testflight app itself I believe.";
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Welcome"
                                                          message:msg
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
        NSString *msg2 = @"Some things to note:\n-The settings view will receive a complete overhaul at some point. I don't like it, and many of the settings seem a bit useless.\n-The process of adding album art to a song is tedious at the moment. I apologize, and I am working on improving this.";
        SDCAlertView *alert2 = [[SDCAlertView alloc] initWithTitle:@"One more thing"
                                                          message:msg2
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
        NSString *msg3 = @"This is important. Do NOT spend a significant amount of time trying to make the library perfect. Expect that data may be possibly corrupted or lost as this is a Beta application. Reinstalling the app will erase all song data.\n\nTap the plus sign in the songs, albums, or artists tabs to add additional songs into the library.";
        SDCAlertView *alert3 = [[SDCAlertView alloc] initWithTitle:@"Last thing, I promise"
                                                           message:msg3
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles: nil];
        alert.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert.messageLabelFont = [UIFont systemFontOfSize:20];
        alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        alert.buttonTextColor = [UIColor defaultAppColorScheme];
        
        alert2.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert2.messageLabelFont = [UIFont systemFontOfSize:20];
        alert2.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        alert2.buttonTextColor = [UIColor defaultAppColorScheme];
        
        alert3.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert3.messageLabelFont = [UIFont systemFontOfSize:20];
        alert3.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        alert3.buttonTextColor = [UIColor defaultAppColorScheme];
        [alert3 show];
        [alert2 show];
        [alert show];
    } else if([AppEnvironmentConstants shouldDisplayWhatsNewScreen]){
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Whats New"
                                                           message:MZWhatsNewUserMsg
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles: nil];
        alert.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert.messageLabelFont = [UIFont systemFontOfSize:20];
        alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        alert.buttonTextColor = [UIColor defaultAppColorScheme];
        [alert show];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SearchBarDataSourceDelegate implementation
- (void)searchBarIsBecomingActive
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if(CGRectIsNull(originalTableViewFrame))
        originalTableViewFrame = self.tableView.frame;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.view.backgroundColor = [UIColor defaultAppColorScheme];
                         int statusBarHeight = [AppEnvironmentConstants statusBarHeight];
                         self.tableView.frame = CGRectMake(0,
                                                           statusBarHeight,
                                                           self.view.frame.size.width,
                                                           self.view.frame.size.height);
                     }
                     completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZMainScreenVCStatusBarAlwaysVisible
                                                        object:[NSNumber numberWithBool:YES]];
}

- (void)searchBarIsBecomingInactive
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.view.backgroundColor = [UIColor clearColor];
                         CGRect viewFrame = self.view.frame;
                         self.tableView.frame = CGRectMake(originalTableViewFrame.origin.x,
                                                           originalTableViewFrame.origin.y,
                                                           viewFrame.size.width,
                                                           viewFrame.size.height);
                     }
                     completion:^(BOOL finished) {
                         originalTableViewFrame = CGRectNull;
                     }];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZMainScreenVCStatusBarAlwaysVisible
                                                         object:[NSNumber numberWithBool:NO]];
}

#pragma mark - EditableSongDataSourceDelegate implementation
- (void)performEditSegueWithSong:(Song *)songToBeEdited
{
    [self performSegueWithIdentifier:@"editingSongMasterSegue" sender:songToBeEdited];
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"editingSongMasterSegue"]){
        //set the songIAmEditing property in the modal view controller
        MasterSongEditorViewController* controller = (MasterSongEditorViewController*)[[segue destinationViewController] topViewController];
        [controller setSongIAmEditing:(Song *)sender];
        self.indexOfEditingSong = self.selectedRowIndexValue;
    }
}

#pragma mark - song editing
- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"SongEditDone"]){
        self.indexOfEditingSong = -1;
    }
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = nil;  //means i want all of the songs
    
    NSSortDescriptor *sortDescriptor;
    if([AppEnvironmentConstants smartAlphabeticalSort])
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    else
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    if(self.playbackContext == nil){
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:@"All Songs"
                                                                   contextId:self.playbackContextUniqueId];
    }
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
