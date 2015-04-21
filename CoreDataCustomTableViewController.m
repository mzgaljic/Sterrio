//
//  CoreDataCustomTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "CoreDataCustomTableViewController.h"

#import "CoreDataManager.h"
#import "UIColor+LighterAndDarker.h"
#import "MySearchBar.h"
#import "MusicPlaybackController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "MZTableViewCell.h"
#import "NSObject+ObjectUUID.h"

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
    
    //makes the keyboard dismiss when the tableview is touched (useful for search bar stuff)
    tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    NSUInteger sectionCount;
    NSUInteger numObjsInTable;
    if(_displaySearchResults){
        sectionCount =  [[self.searchFetchedResultsController sections] count];
        numObjsInTable = [self numObjectsInTable];
        
        if(numObjsInTable == 0){
            NSString *text = @"No Search Results";
            tableView.backgroundView = [self friendlyTableEmptyUserMessageWithText:text];
        } else
            [self removeEmptyTableUserMessage];
    }
    else
    {
        sectionCount =  [[self.fetchedResultsController sections] count];
        numObjsInTable = [self numObjectsInTable];
        
        if(numObjsInTable == 0){
            NSString *text = self.emptyTableUserMessage;
            tableView.backgroundView = [self friendlyTableEmptyUserMessageWithText:text];
        } else
            [self removeEmptyTableUserMessage];
    }
    return sectionCount;
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    if([header respondsToSelector:@selector(textLabel)]){
        int headerFontSize;
        if([AppEnvironmentConstants preferredSizeSetting] < 5)
            headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
        else
            headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:5];
        header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                size:headerFontSize];
    }
}

#pragma  mark - TableView helpers
- (UIView *)friendlyTableEmptyUserMessageWithText:(NSString *)text
{
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                               0,
                                                               self.view.bounds.size.width,
                                                               self.view.bounds.size.height)];
    if(text == nil)
        text = @"";
    label.text = text;
    label.textColor = [UIColor darkGrayColor];
    //multi lines strings ARE possible, this is just a weird api detail
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [label sizeToFit];
    return label;
}

- (void)removeEmptyTableUserMessage
{
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

- (NSUInteger)numObjectsInTable
{
    NSNumber *totalObjCount;
    //used to avoid faulting objects when asking fetchResultsController how many objects exist
    NSString *totalObjCountPathNum = @"@sum.numberOfObjects";
    if(_displaySearchResults)
        totalObjCount = [self.searchFetchedResultsController.sections
                         valueForKeyPath:totalObjCountPathNum];
    else
        totalObjCount = [self.fetchedResultsController.sections valueForKeyPath:totalObjCountPathNum];
    return [totalObjCount integerValue];
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
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
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
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
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
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar text light and readable
    
    //hides empty cells at the end
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //all tableviews subclassing this class are on a white background.
    //(playback queue tableview is inheriting from something else, dont worry about that).
    //making the scroll indicator invisible.
    tableView.showsVerticalScrollIndicator = YES;
    tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    
    [self hideSearchBarByDefaultIfApplicable];
    tableView.contentOffset = CGPointMake(tableView.contentOffset.x,
                                          lastKnownTableViewVerticalContentOffset);
    
    if([self numObjectsInTable] == 0){ //dont need search bar anymore
        searchBar = nil;
        tableView.tableHeaderView = nil;
    }
    
    NSArray *visibleCells = [tableView visibleCells];
    if(visibleCells.count > 0)
    {
        UITableViewCell *aCell = visibleCells[0];
        UIFont *font = aCell.textLabel.font;
        if(([font.fontName isEqualToString:[AppEnvironmentConstants boldFontName]]
           && ![AppEnvironmentConstants boldNames])
           ||
           ([font.fontName isEqualToString:[AppEnvironmentConstants regularFontName]]
            && [AppEnvironmentConstants boldNames]))
        {
            //we inadvertantly just detected a previous change in settings. Reload table.
            [tableView reloadData];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
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
                                             selector:@selector(fontSizeChanged)
                                                 name:MZUserChangedFontSize
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
    self.automaticallyAdjustsScrollViewInsets = YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//only called if a more specific notification wasnt fired (such as font size update)
- (void)settingsPossiblyChanged
{
#warning should only use this when font size is changed (and nothing else). optimize!
    [tableView beginUpdates];
    [tableView endUpdates];
}

- (void)fontSizeChanged
{
    
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
            [self reflectNowPlayingChangesInTableview:notification];
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
    if(self.tableDataSource.displaySearchResults){
        oldPath = [self.tableDataSource indexPathInSearchTableForObject:songToReplace];
        newPath = [self.tableDataSource indexPathInSearchTableForObject:newSong];
    } else{
        oldPath = [self.fetchedResultsController indexPathForObject:songToReplace];
        newPath = [self.fetchedResultsController indexPathForObject:newSong];
    }
    
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
                                                         offsetHeightWhenPlayerVisible + MZTabBarHeight,
                                                         0);
    UIEdgeInsets defaultInsets = UIEdgeInsetsMake(currentInsets.top, 0, MZTabBarHeight, 0);
    [UIView animateWithDuration:0.75
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
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
    } completion:nil];
}

- (void)playerOnScreenStateChanged
{
    [self compensateTableViewInsetForPlayer];
}

@end
