//
//  PlaylistSongItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistSongAdderTableViewController.h"

#import "Song.h"
#import "PlaylistItem+Utilities.h"
#import "Playlist+Utilities.h"
#import "AppEnvironmentConstants.h"
#import "MasterSongsTableViewController.h"
#import "AllSongsDataSource.h"

@interface PlaylistSongAdderTableViewController()
{
    CGRect originalTableViewFrame;
    BOOL isUserCreatingNewPlaylist;
    short numSongsInPlaylistBeforeEditing;
}
@property (nonatomic, strong) MySearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property AllSongsDataSource *tableViewDataSourceAndDelegate;
@property (nonatomic, strong) Playlist *playlist;
@end

@implementation PlaylistSongAdderTableViewController

- (instancetype)initWithPlaylistsUniqueId:(NSString *)uniqueId playlistName:(NSString *)name;
{
    UIStoryboard *sb = [MZCommons mainStoryboard];
    PlaylistSongAdderTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"playlistSongAdderView"];
    self = vc;
    if (self) {
        [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:YES];
        
        //custom variables init here
        self.playlist = [self fetchPlaylistWithUniqueId:uniqueId];
        
        if(self.playlist == nil){
            self.playlist = [Playlist createNewPlaylistWithName:name
                                               inManagedContext:[CoreDataManager context]];
            isUserCreatingNewPlaylist = YES;
            numSongsInPlaylistBeforeEditing = 0;
        }
        else{
            isUserCreatingNewPlaylist = NO;
            numSongsInPlaylistBeforeEditing = self.playlist.playlistItems.count;
        }
    }
    return self;
}

#pragma mark - SearchBarDataSourceDelegate implementation
- (NSString *)placeholderTextForSearchBar
{
    return @"Search My Songs";
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


#pragma mark - Miscellaneous
- (void)establishTableViewDataSource
{
    self.tableViewDataSourceAndDelegate = [[AllSongsDataSource alloc] initWithSongDataSourceType:SONG_DATA_SRC_TYPE_Playlist_MultiSelect
                                                                     searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"playlistSongItemPickerCell";
    self.tableViewDataSourceAndDelegate.playlistSongAdderDelegate = self;
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = [MZCommons makeAttributedString:@"No Songs"];
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
}

#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    //order of calls matters here...
    if(! self.searchBar) {
        self.searchBar = [self.tableViewDataSourceAndDelegate setUpSearchBar];
        [super setSearchBar:self.searchBar];
    }
    [super viewWillAppear:animated];
    
    //needed to make UITableViewCellAccessoryCheckmark the nav bar color!
    self.tableView.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    if(isUserCreatingNewPlaylist){
        UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Add Later"
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(rightBarButtonTapped:)];
        [self.navigationItem setRightBarButtonItem:btn animated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    originalTableViewFrame = CGRectNull;
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    [self establishTableViewDataSource];
    
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)dealloc
{
    self.vcToNotifyAboutRotation = nil;
    [super prepareFetchedResultsControllerForDealloc];
    self.playlist = nil;
    self.searchBar = nil;
    self.tableViewDataSourceAndDelegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - PlaylistSongAdderDataSourceDelegate protocol implementation
- (void)setSuccessNavBarButtonStringValue:(NSString *)newValue
{
    if([newValue isEqualToString:@""]){
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
    else if(! [self.navigationItem.rightBarButtonItem.title isEqualToString:newValue])
    {
        UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:newValue
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(rightBarButtonTapped:)];
        [self.navigationItem setRightBarButtonItem:btn animated:YES];
    }
}

- (BOOL)isUserCreatingPlaylistFromScratch
{
    return isUserCreatingNewPlaylist;
}

#pragma mark - User button actions
- (IBAction)rightBarButtonTapped:(id)sender
{
    NSArray *newSongsArray = [self.tableViewDataSourceAndDelegate minimallyFaultedArrayOfSelectedPlaylistSongs];
    
    //songs must have been added
    if(newSongsArray.count > 0){
        
        if(! isUserCreatingNewPlaylist)
        {
            //user finished adding songs to the playlist. this playlist already existed in the library,
            //so user is going to return to the playlist detail VC. make sure tab bar is hidden.
            [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated
                                                                object:@YES];
        }
        
        NSMutableSet *set = [NSMutableSet setWithSet:self.playlist.playlistItems];
        //[set addObjectsFromArray:newSongsArray];

        __block PlaylistItem *aNewItem;
        __weak Playlist *weakPlaylist = self.playlist;
        __weak NSManagedObjectContext *weakContext = [CoreDataManager context];
        
        //index at the end of the playlist (if imagined conceptually as an array)
        __block int nextEmptyIndexInPlaylist = (int)set.count;
        
        [newSongsArray enumerateObjectsUsingBlock:^(Song *aSong, NSUInteger idx, BOOL *stop) {
            
            aNewItem = [PlaylistItem createNewPlaylistItemWithCorrespondingPlaylist:weakPlaylist
                                                                               song:aSong
                                                                    indexInPlaylist:nextEmptyIndexInPlaylist
                                                                   inManagedContext:weakContext];
            nextEmptyIndexInPlaylist++;
            [set addObject:aNewItem];
        }];
        
        self.playlist.playlistItems = set;
    
    } else{
        //user hasnt added any songs, they want to add songs later. No action necessary.
    }

    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    [[CoreDataManager sharedInstance] saveContext];  //commit changes
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

             
- (IBAction)leftBarButtonTapped:(id)sender
{
    self.tableViewDataSourceAndDelegate = nil;
    
    //user cancelled playlist creation
    if(self.playlist.playlistItems.count == 0 && isUserCreatingNewPlaylist){
        [[CoreDataManager context] rollback];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated
                                                            object:@NO];
    } else{
        self.playlist = nil;
        //user cancelled adding additional songs to his/her playlist. should hide tab bar
        //since the user will end up back in playlist detail VC.
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated
                                                            object:@YES];
    }
    
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    //get exec bad access in landscape sometimes when dismissing if i dont set these to nil.
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Rotation status bar methods
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(self.vcToNotifyAboutRotation)
        [self.vcToNotifyAboutRotation didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - fetching and sorting
- (void)initFetchResultsController
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    //means i want all songs in core data that were not added to only a playlist. (i.e. are part of the
    //general library)
    request.predicate = [NSPredicate predicateWithFormat:@"smartSortSongName != nil"];
    [request setFetchBatchSize:MZDefaultCoreDataFetchBatchSize];
    [request setPropertiesToFetch:@[@"songName", @"album", @"artist"]];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    //no playback context set here since its impossible to select songs for playback in this VC.
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

#pragma mark - Helpers
- (Playlist *)fetchPlaylistWithUniqueId:(NSString *)uniqueId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
    request.predicate = [NSPredicate predicateWithFormat:@"self.uniqueId == %@", uniqueId];
    
    NSArray *results = [[CoreDataManager context] executeFetchRequest:request error:nil];
    int count = (int)results.count;
    NSAssert(count == 1 || count == 0, @"Two playlists exist in core data with unique id: %@", uniqueId);
    
    return (count == 1) ? results[0] : nil;
}

@end
