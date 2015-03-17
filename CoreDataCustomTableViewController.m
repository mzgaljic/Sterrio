//
//  CoreDataCustomTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "CoreDataCustomTableViewController.h"

typedef enum{
    ContentInsetStateDefault,
    ContentInsetStateCompensatingForPlayer
} ContentInsetState;

static void *navBarHiddenChange = &navBarHiddenChange;

@interface CoreDataCustomTableViewController ()
{
    UITableView *tableView;  //this is the subviews tableview (gets set on the fly)
    MySearchBar *searchBar;  //also set on the fly
    int offsetHeightWhenPlayerVisible;
    int lastKnownTableViewVerticalContentOffset;
    ContentInsetState insetState;
}

@property (nonatomic) BOOL beganUpdates;
@end

@implementation CoreDataCustomTableViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//crucial for this to work (Marks add-on)
- (void)setTableForCoreDataView:(UITableView *)aTableView;
{
    tableView = aTableView;
}

- (void)setSearchBar:(MySearchBar *)aSearchBar
{
    searchBar = aSearchBar;
}

- (void)alertUserAboutSetupErrorAndAbort
{
    NSLog(@"YOU ARE ATTEMPTING TO USE CoreDataCustomTableViewController WITHOUT INITIALIZING ITS TABLEVIEW FIRST. Aborting...");
    abort();
}

#pragma mark - Fetching
- (void)performFetch
{
    if(_displaySearchResults){
        if (self.searchFetchedResultsController)
        {
            NSError *error;
            [self.searchFetchedResultsController performFetch:&error];
            if (error)
                NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd),
                      [error localizedDescription], [error localizedFailureReason]);
        }
        
    } else{
        if (self.fetchedResultsController)
        {
            NSError *error;
            [self.fetchedResultsController performFetch:&error];
            if (error)
                NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd),
                      [error localizedDescription], [error localizedFailureReason]);
        }
    }
    [tableView reloadData];
}

- (void)setSearchFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    if(tableView == nil && newfrc != nil)
        [self alertUserAboutSetupErrorAndAbort];
    NSFetchedResultsController *oldfrc = _searchFetchedResultsController;
    if (newfrc != oldfrc)
    {
        _searchFetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name])
            && (!self.navigationController || !self.navigationItem.title))
        {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc)
        {
            [self performFetch];
        }
        else
        {
            [tableView reloadData];
        }
    }
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    if(tableView == nil && newfrc != nil)
        [self alertUserAboutSetupErrorAndAbort];
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc)
    {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name])
            && (!self.navigationController || !self.navigationItem.title))
        {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc)
        {
            [self performFetch];
        }
        else
        {
            [tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(_displaySearchResults){
        return [[self.searchFetchedResultsController sections] count];
    } else{
        return [[self.fetchedResultsController sections] count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_displaySearchResults){
        return [[[self.searchFetchedResultsController sections] objectAtIndex:section] numberOfObjects];
    } else{
        return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(_displaySearchResults){
        return [[[self.searchFetchedResultsController sections] objectAtIndex:section] name];
    } else{
        return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if(_displaySearchResults){
        return [self.searchFetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
    } else{
        return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if(_displaySearchResults){
        return [self.searchFetchedResultsController sectionIndexTitles];
    } else{
        return [self.fetchedResultsController sectionIndexTitles];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [tableView beginUpdates];
    self.beganUpdates = YES;
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            //I added the next 2 cases in myself. xcode was complaining.
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.beganUpdates)
        [tableView endUpdates];
}

#pragma mark - overriden methods for default behavior across tableviews
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = [UIColor defaultAppColorScheme];
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor defaultWindowTintColor]
                        forKey:UITextAttributeTextColor]];
#pragma clang diagnostic warning "-Wdeprecated-declarations"
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar text light and readable
    
    //hides empty cells at the end
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //all tableviews subclassing this class are on a white background so this looks nice.
    //(playback queue tableview is inheriting from something else, dont worry about that).
    tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    
    //going to fade in tableview
    tableView.alpha = 0.8;
    [self hideSearchBarByDefaultIfApplicable];
    tableView.contentOffset = CGPointMake(tableView.contentOffset.x, lastKnownTableViewVerticalContentOffset);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //fading in tableview
    [UIView animateWithDuration:0.20 animations:^{
        tableView.alpha = 1;
    }];
    [self compensateTableViewInsetForPlayer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    lastKnownTableViewVerticalContentOffset = tableView.contentOffset.y;
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsPossiblyChanged)
                                                 name:MZUserFinishedWithReviewingSettings
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowPlayingSongsHasChanged:)
                                                 name:MZNewSongLoading
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerOnScreenStateChanged)
                                                 name:MZPlayerToggledOnScreenStatus
                                               object:nil];
    int smallPlayerHeight = [SongPlayerCoordinator  heightOfMinimizedPlayer];
    
    //multiplied by 2 since we want the padding amount to be applied under AND above the player height.
    offsetHeightWhenPlayerVisible = smallPlayerHeight + (MZSmallPlayerVideoFramePadding * 2);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    lastKnownTableViewVerticalContentOffset = 0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)settingsPossiblyChanged
{
    //tableview alrady re-draws itself after settings change, but reloading
    //the entire table fixes weird issues with the cells.
    //tableView reloadData];
}

- (void)hideSearchBarByDefaultIfApplicable
{
    if(searchBar){
        tableView.contentOffset = CGPointMake(tableView.contentOffset.x,
                                              searchBar.frame.size.height);
        if(lastKnownTableViewVerticalContentOffset < searchBar.frame.size.height)
            lastKnownTableViewVerticalContentOffset = searchBar.frame.size.height;
    }
}

- (void)nowPlayingSongsHasChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:MZNewSongLoading]){
        if([NSThread isMainThread]){
            [self performSelectorOnMainThread:@selector(reflectNowPlayingChangesInTableview:)
                                   withObject:notification
                                waitUntilDone:YES];
        } else{
            [self performSelectorOnMainThread:@selector(reflectNowPlayingChangesInTableview:)
                                   withObject:notification
                                waitUntilDone:NO];
        }
    }
}

- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification
{
    if(!self.isViewLoaded && !self.view.window){
        //view controller is not on screen, dont need to update cells on the fly...
        return;
    }
    Song *songToReplace = (Song *)[notification object];
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    Song *newSong = nowPlaying.nowPlaying;
    NSIndexPath *oldPath, *newPath;
    if(self.playbackContext == nil)
        return;
    
    //tries to obtain the path to the changed songs if possible.
    oldPath = [self.fetchedResultsController indexPathForObject:songToReplace];
    newPath = [self.fetchedResultsController indexPathForObject:newSong];
    
    if(oldPath || newPath){
        [tableView beginUpdates];
        if(oldPath)
            [tableView reloadRowsAtIndexPaths:@[oldPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        if(newPath != nil && newPath != oldPath)
            [tableView reloadRowsAtIndexPaths:@[newPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }
}

- (UIColor *)colorForNowPlayingItem
{
    return [[UIColor defaultAppColorScheme] lighterColor];
}

- (void)compensateTableViewInsetForPlayer
{
    UIEdgeInsets currentInsets = tableView.contentInset;
    UIEdgeInsets insetIncreaseContent = UIEdgeInsetsMake(currentInsets.top,
                                                         0,
                                                         offsetHeightWhenPlayerVisible,
                                                         0);
    UIEdgeInsets defaultInsets = UIEdgeInsetsMake(currentInsets.top, 0, 0, 0);
    [UIView animateWithDuration:0.8 animations:^{
        if([SongPlayerCoordinator isPlayerOnScreen])
        {
            if(insetState == ContentInsetStateDefault){
                tableView.contentInset = insetIncreaseContent;
                insetState = ContentInsetStateCompensatingForPlayer;
            }
        }
        else
        {
            if(insetState == ContentInsetStateDefault)
                tableView.contentInset = defaultInsets;
            else if(insetState == ContentInsetStateCompensatingForPlayer){
                tableView.contentInset = defaultInsets;
                insetState = ContentInsetStateDefault;
            }
        }
    }];
}

- (void)playerOnScreenStateChanged
{
    [self compensateTableViewInsetForPlayer];
}

@end
