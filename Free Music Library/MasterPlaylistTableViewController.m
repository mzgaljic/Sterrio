//
//  MasterPlaylistTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterPlaylistTableViewController.h"

@interface MasterPlaylistTableViewController ()
@property(nonatomic, strong) SDCAlertView *createPlaylistAlert;
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;
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

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //playlists tab is never the first one on screen. no need to animate it
    if([self numberOfPlaylistsInCoreDataModel] > 0){
        //create search bar, add to viewController
        _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0) placeholderText:@"Search My Music"];
        _searchBar.delegate = self;
        self.tableView.tableHeaderView = _searchBar;
    }
    [super setSearchBar:self.searchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
}

//User tapped the search box
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchFetchedResultsController = nil;
    self.fetchedResultsController = nil;
    
    //show the cancel button
    [_searchBar setShowsCancelButton:YES animated:YES];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //search results already appear as the user types. Just hide the keyboard...
    [_searchBar resignFirstResponder];
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self setFetchedResultsControllerAndSortStyle];
    
    //dismiss search bar and hide cancel button
    [_searchBar setShowsCancelButton:NO animated:YES];
    [_searchBar resignFirstResponder];
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    #warning implementation incomplete
    
    if(searchText.length == 0)
    {
        self.displaySearchResults = NO;
    }
    else
    {
        self.displaySearchResults = YES;
        
        /*
         self.fetchedResultsController = nil;
         NSManagedObjectContext *context = [CoreDataManager context];
         NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
         
         if([AppEnvironmentConstants smartAlphabeticalSort])
         request.predicate = [NSPredicate predicateWithFormat:@"smartSortSongName == %@", searchText];
         else
         request.predicate = [NSPredicate predicateWithFormat:@"songName == %@", searchText];
         
         //fetchedResultsController is from custom super class
         self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
         managedObjectContext:context
         sectionNameKeyPath:nil
         cacheName:nil];
         */
        //now search through each song to find the query we need
        /**
         for (Song* someSong in _allSongsInLibrary)  //iterate through all songs
         {
         NSRange nameRange = [someSong.songName rangeOfString:searchText options:NSCaseInsensitiveSearch];
         if(nameRange.location != NSNotFound)
         {
         [_searchResults addObject:someSong];
         }
         //would maybe like to filter by BEST result? This only captures results...
         }
         */
    }
}

#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUpSearchBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //this works better than a unique random id since this class can be dealloced and re-alloced
    //later. Id must stay the same across all allocations.  :)
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    self.emptyTableUserMessage = @"No Playlists";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForNavigationBar];
    self.navigationItem.leftBarButtonItems = [self leftBarButtonItemsForNavigationBar];
    [self setTableForCoreDataView:self.tableView];
    self.cellReuseId = @"PlaylistItemCell";
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table View Data Source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Playlist *playlist;
    if(self.displaySearchResults)
        playlist = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        playlist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
                                                             forIndexPath:indexPath];
    cell.textLabel.attributedText = [PlaylistTableViewFormatter formatPlaylistLabelUsingPlaylist:playlist];
    PlaybackContext *playlistsContext = [self contextForPlaylist:playlist];
    NowPlayingSong *nowPlayingSongObj = [NowPlayingSong sharedInstance];
    BOOL currentSongFromPlaylist = ([playlist.playlistSongs containsObject:nowPlayingSongObj.nowPlaying] &&
                                    [nowPlayingSongObj.context isEqualToContext:playlistsContext]);
    if(currentSongFromPlaylist)
        cell.textLabel.textColor = [super colorForNowPlayingItem];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:[[UIColor defaultAppColorScheme] lighterColor]];
    if(! [PlaylistTableViewFormatter playlistNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[PlaylistTableViewFormatter nonBoldPlaylistLabelFontSize]];
    //playlist doesnt have detail label  :)
    
    cell.delegate = self;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.displaySearchResults)
        return NO;
    else
        return YES;
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        Playlist *playlist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        [MusicPlaybackController groupOfSongsAboutToBeDeleted:[playlist.playlistSongs array]
                                              deletionContext:self.playbackContext];
        
        //delete the playlist and save changes
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:[CoreDataManager context]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"playlist_id == %@", playlist.playlist_id];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
        if(matchingData.count == 1)
            [[CoreDataManager context] deleteObject:matchingData[0]];
        [[CoreDataManager sharedInstance] saveContext];
        
        if([self numberOfPlaylistsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    //dont want playlists to be selectable when in edit mode.
    if(self.editing)
        return;
    Playlist *selectedPlaylist;
    if(self.displaySearchResults)
        selectedPlaylist = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        selectedPlaylist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //now segue to push view where user can view the tapped playlist
    [self performSegueWithIdentifier:@"playlistItemSegue" sender:selectedPlaylist];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
    {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PlaylistTableViewFormatter preferredPlaylistCellHeight];
}

#pragma mark - MGSwipeTableCell delegates
- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction
{
    return [self tableView:self.tableView
     canEditRowAtIndexPath:[self.tableView indexPathForCell:cell]];
}

- (NSArray*)swipeTableCell:(MGSwipeTableCell*)cell
  swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*)swipeSettings
         expansionSettings:(MGSwipeExpansionSettings*)expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    UIColor *initialExpansionColor = [AppEnvironmentConstants expandingCellGestureInitialColor];
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        Playlist *playlist = [self.fetchedResultsController
                        objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak MasterPlaylistTableViewController *weakself = self;
        __weak Playlist *weakPlaylist = playlist;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           NSLog(@"Queing up: %@", weakPlaylist.playlistName);
                                           PlaybackContext *context = [weakself contextForPlaylist:weakPlaylist];
                                           [MusicPlaybackController queueUpNextSongsWithContexts:@[context]];
                                           [weakCell refreshContentView];
                                           return YES;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 2.7;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureDeleteItemColor];
        swipeSettings.transition = MGSwipeTransitionBorder;
        
        __weak MasterPlaylistTableViewController *weakSelf = self;
        MGSwipeButton *delete = [MGSwipeButton buttonWithTitle:@"Delete"
                                               backgroundColor:expansionSettings.expansionColor
                                                       padding:15
                                                      callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     NSIndexPath *indexPath;
                                     indexPath= [weakSelf.tableView indexPathForCell:sender];
                                     [weakSelf tableView:weakSelf.tableView
                                      commitEditingStyle:UITableViewCellEditingStyleDelete
                                       forRowAtIndexPath:indexPath];
                                     return NO; //don't autohide to improve delete animation
                                 }];
        return @[delete];
    }
    return nil;
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:(Playlist *)sender];
        [[segue destinationViewController] setParentVcPlaybackContext:self.playbackContext];
    }
}

- (void)displayCreatePlaylistAlert
{
    _createPlaylistAlert = [[SDCAlertView alloc] init];
    _createPlaylistAlert.alertViewStyle = SDCAlertViewStylePlainTextInput;
    _createPlaylistAlert.title = @"New Playlist";
    [_createPlaylistAlert textFieldAtIndex:0].placeholder = @"Name me";
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    UIFont *normalFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:fontSize];
    _createPlaylistAlert.textFieldFont = normalFont;
    _createPlaylistAlert.normalButtonFont = normalFont;
    _createPlaylistAlert.titleLabelFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                          size:fontSize];
    _createPlaylistAlert.suggestedButtonFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                               size:fontSize];
    _createPlaylistAlert.delegate = self;  //delgate of entire alertView
    [_createPlaylistAlert addButtonWithTitle:@"Cancel"];
    [_createPlaylistAlert addButtonWithTitle:@"Create"];
    [_createPlaylistAlert textFieldAtIndex:0].delegate = self;  //delegate for the textField
    [_createPlaylistAlert textFieldAtIndex:0].returnKeyType = UIReturnKeyDone;
    _createPlaylistAlert.buttonTextColor = [UIColor defaultAppColorScheme];
    [_createPlaylistAlert show];
}

- (void)tabBarAddButtonPressed
{
    [self displayCreatePlaylistAlert];
}

- (void)alertView:(SDCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView == _createPlaylistAlert){
        if(buttonIndex == 1){
            NSString *playlistName = [alertView textFieldAtIndex:0].text;
            playlistName = [playlistName removeIrrelevantWhitespace];
            
            if(playlistName.length == 0)  //was all whitespace, or user gave us an empty string
                return;
            
            Playlist *myNewPlaylist = [Playlist createNewPlaylistWithName:playlistName inManagedContext:[CoreDataManager context]];
            PlaylistSongAdderTableViewController *vc = [[PlaylistSongAdderTableViewController alloc] initWithPlaylist:myNewPlaylist];
            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navVC animated:YES completion:nil];
        }
        else  //canceled
            return;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)alertTextField
{
    NSString *playlistName = alertTextField.text;
    if(playlistName.length == 0){
        [alertTextField resignFirstResponder];  //dismiss keyboard.
        [_createPlaylistAlert dismissWithClickedButtonIndex:0 animated:YES];  //dismisses alertView
        return NO;
    }
    int numSpaces = 0;
    for(int i = 0; i < playlistName.length; i++){
        if([playlistName characterAtIndex:i] == ' ')
            numSpaces++;
    }
    if(numSpaces == playlistName.length){
        //playlist can't be all whitespace.
        [alertTextField resignFirstResponder];  //dismiss keyboard.
        [_createPlaylistAlert dismissWithClickedButtonIndex:0 animated:YES];  //dismisses alertView
        return NO;
    }
    
    //create the playlist
    Playlist *myNewPlaylist = [Playlist createNewPlaylistWithName:playlistName inManagedContext:[CoreDataManager context]];
    PlaylistSongAdderTableViewController *vc = [[PlaylistSongAdderTableViewController alloc] initWithPlaylist:myNewPlaylist];
    
    [alertTextField resignFirstResponder];  //dismiss keyboard.
    [_createPlaylistAlert dismissWithClickedButtonIndex:50 animated:YES];  //dismisses alertView, skip clickedButtonAtIndex method
    
    //now segue to modal view where user can pick songs for this playlist
    [self.navigationController pushViewController:vc animated:YES];
    
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

#pragma mark - Helpers
- (PlaybackContext *)contextForPlaylist:(Playlist *)aPlaylist
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY playlistIAmIn.playlist_id == %@", aPlaylist.playlist_id];
    
    //picked genreCode because its a useless value...need that so the results of the
    //nsorderedset dont get re-ordered
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistIAmIn"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSString *playlistQueueDescription = [NSString stringWithFormat:@"\"%@\" Playlist", aPlaylist.playlistName];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:playlistQueueDescription
                                               contextId:self.playbackContextUniqueId];
}

#pragma mark - Counting Playlists in core data
- (int)numberOfPlaylistsInCoreDataModel
{
    //count how many instances there are of the Song entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];
    NSError *error = nil;
    NSUInteger tempCount = [context countForFetchRequest: fetchRequest error: &error];
    if(error == nil){
        count = (int)tempCount;
    }
    return count;
}

#pragma mark - fetching and sorting
- (void)setFetchedResultsControllerAndSortStyle
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
    request.predicate = nil;  //means i want all of the playlists
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistName"
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
