//
//  MasterPlaylistTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterPlaylistTableViewController.h"

@interface MasterPlaylistTableViewController ()
@property(nonatomic, strong) UIAlertView *createPlaylistAlert;
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
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    UIImage *image = [UIImage imageNamed:@"Settings-Line"];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self
                                                                action:@selector(settingsButtonTapped)];
    UIBarButtonItem *posSpaceAdjust = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [posSpaceAdjust setWidth:28];
    self.editButton = editButton;
    
    self.leftBarButtonItems = @[settings, posSpaceAdjust, editButton];
    return self.leftBarButtonItems;
}

- (NSArray *)rightBarButtonItemsForNavigationBar
{
    //right side of nav bar
    NSInteger addItem = UIBarButtonSystemItemAdd;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:addItem
                                                                               target:self
                                                                               action:@selector(addButtonPressed)];
    self.rightBarButtonItems = @[addButton];
    return self.rightBarButtonItems;
}

- (NSString *)titleOfNavigationBar
{
    return @"Playlists";
}

#pragma mark - Miscellaneous
#pragma mark - Miscellaneous
- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        //leaving editing mode now
        [self setEditing:NO animated:YES];
        [self.tableView setEditing:NO animated:YES];
        
        if(self.rightBarButtonItems.count > 0){
            UIBarButtonItem *rightMostItem = self.rightBarButtonItems[self.rightBarButtonItems.count-1];
            [self makeBarButtonItemNormal:rightMostItem];
        }
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
        
        if(self.rightBarButtonItems.count > 0){
            UIBarButtonItem *rightMostItem = self.rightBarButtonItems[self.rightBarButtonItems.count-1];
            [self makeBarButtonItemGrey:rightMostItem];
        }
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

- (void)currentSongHasChanged
{
#warning needs implementation. should check which if the current song is in a playlist AND if it was actually played back from the playlist or not
    //want the now playing album to always be a specific color
    [self.tableView reloadData];
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //playlists tab is never the first one on screen. no need to animate it
    if([self numberOfPlaylistsInCoreDataModel] > 0){
        //create search bar, add to viewController
        _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0) placeholderText:@"Search My Library"];
        _searchBar.delegate = self;
        self.tableView.tableHeaderView = _searchBar;
        self.tableView.contentOffset = CGPointMake(0, self.searchBar.frame.size.height);
    }
    [self setSearchBar:self.searchBar];
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
    self.playbackContext = SongPlaybackContextPlaylists;
    [self setUpSearchBar];
    if([self numberOfPlaylistsInCoreDataModel] == 0){ //dont need search bar anymore
        _searchBar = nil;
        self.tableView.tableHeaderView = nil;
    }
    [self setUpSearchBar];
    
    //need to somewhat compesate since the last row was cut off (because in storyboard
    //it thinks the tableview should also span under the nav bar...which i dont want lol).
    int navBarHeight = [AppEnvironmentConstants navBarHeight];
    self.tableView.frame = CGRectMake(0,
                                      0,
                                      self.view.frame.size.width,
                                      self.view.frame.size.height - navBarHeight);
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self setTableForCoreDataView:self.tableView];
    self.playbackContext = SongPlaybackContextUnspecified;
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table View Data Source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PlaylistItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                            forIndexPath:indexPath];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
    
    MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR
                                                                               color:[[UIColor defaultAppColorScheme] lighterColor]];
    cell.editingAccessoryView = coloredDisclosureIndicator;
    cell.accessoryView = coloredDisclosureIndicator;
    
    // Configure the cell...
    Playlist *playlist;
    if(self.displaySearchResults)
        playlist = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        playlist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //init cell fields
    cell.textLabel.attributedText = [PlaylistTableViewFormatter formatPlaylistLabelUsingPlaylist:playlist];
    cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:[[UIColor defaultAppColorScheme] lighterColor]];
    if(! [PlaylistTableViewFormatter playlistNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[PlaylistTableViewFormatter nonBoldPlaylistLabelFontSize]];
    //playlist doesnt have detail label  :)
    
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
        
        //check if any of the songs in this playlist are currently playing, if so, set the avplayer to nil (and pause it) so it doesn't crash!
        [MusicPlaybackController groupOfSongsAboutToBeDeleted:[playlist.playlistSongs array]];
        
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

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:(Playlist *)sender];
    }
}

- (void)addButtonPressed
{
    _createPlaylistAlert = [[UIAlertView alloc] init];
    _createPlaylistAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    _createPlaylistAlert.title = @"New Playlist";
    [_createPlaylistAlert textFieldAtIndex:0].placeholder = @"Name your new playlist";
    _createPlaylistAlert.delegate = self;  //delgate of entire alertView
    [_createPlaylistAlert addButtonWithTitle:@"Cancel"];
    [_createPlaylistAlert addButtonWithTitle:@"Create"];
    [_createPlaylistAlert textFieldAtIndex:0].delegate = self;  //delegate for the textField
    [_createPlaylistAlert textFieldAtIndex:0].returnKeyType = UIReturnKeyDone;
    [_createPlaylistAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else{
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
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
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
