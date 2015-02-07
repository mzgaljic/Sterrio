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

@property (nonatomic, assign) int indexOfEditingSong;
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, strong) MySearchBar* searchBar;
@end

@implementation MasterPlaylistTableViewController
@synthesize createPlaylistAlert = _createPlaylistAlert;

- (void)setUpNavBarItems
{
    //right side of nav bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
                                                                               action:@selector(addButtonPressed)];
    NSArray *rightBarButtonItems = @[addButton];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    //left side of nav bar
    UIImage *image = [UIImage imageNamed:@"Settings-Line"];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self
                                                                action:@selector(settingsButtonTapped)];
    
    self.navigationItem.leftBarButtonItems = @[settings];
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
    if([self numberOfPlaylistsInCoreDataModel] > 0 && _searchBar == nil){
        //create search bar, add to viewController
        _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0) placeholderText:@"Search Playlists"];
        _searchBar.delegate = self;
        self.tableView.tableHeaderView = _searchBar;
    }
}

//User tapped the search box
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
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
    //dismiss search bar and hide cancel button
    [_searchBar setShowsCancelButton:NO animated:YES];
    [_searchBar resignFirstResponder];
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
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
static BOOL lastSortOrder;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(lastSortOrder != [AppEnvironmentConstants smartAlphabeticalSort])
    {
        [self setFetchedResultsControllerAndSortStyle];
        lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft ||
       orientation == UIInterfaceOrientationLandscapeRight||
       orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
    
    if([self numberOfPlaylistsInCoreDataModel] == 0){ //dont need search bar anymore
        _searchBar = nil;
        self.tableView.tableHeaderView = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"Playlists";
    
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
    [self.searchBar updateFontSizeIfNecessary];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    [self setFetchedResultsControllerAndSortStyle];
    
    [self setUpNavBarItems];
    self.tableView.allowsSelectionDuringEditing = YES;
    [self setUpSearchBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

#pragma mark - Table View Data Source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistItemCell" forIndexPath:indexPath];
    
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
    //could also selectively choose which rows may be deleted here.
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
    Playlist *selectedPlaylist;
    if(self.displaySearchResults)
        selectedPlaylist = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        selectedPlaylist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //now segue to push view where user can view the tapped playlist
   [self performSegueWithIdentifier:@"playlistItemSegue" sender:selectedPlaylist];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PlaylistTableViewFormatter preferredPlaylistCellHeight];
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:sender];
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
            [self.navigationController pushViewController:vc animated:YES];
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
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        [self setTabBarVisible:NO animated:NO];
        return YES;
    }
    else{
        [self setTabBarVisible:YES animated:NO];
        //fixes a bug when using another viewController with all these "hiding" nav bar features...and returning to this viewController
        self.tabBarController.tabBar.hidden = NO;
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
}

- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated
{
    // bail if the current state matches the desired state
    if ([self tabBarIsVisible] == visible) return;
    
    // get a frame calculation ready
    CGRect frame = self.tabBarController.tabBar.frame;
    CGFloat height = frame.size.height;
    CGFloat offsetY = (visible)? -height : height;
    
    // zero duration means no animation
    CGFloat duration = (animated)? 0.3 : 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        self.tabBarController.tabBar.frame = CGRectOffset(frame, 0, offsetY);
    }];
}

- (BOOL)tabBarIsVisible
{
    return self.tabBarController.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
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
