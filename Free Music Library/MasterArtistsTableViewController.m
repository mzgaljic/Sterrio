//
//  MasterArtistsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterArtistsTableViewController.h"

@interface MasterArtistsTableViewController ()
@property (nonatomic, assign) int indexOfEditingArtist;
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, strong) UISearchBar* searchBar;
@end

@implementation MasterArtistsTableViewController
static BOOL PRODUCTION_MODE;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)setUpNavBarItems
{
    //right side of nav bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
                                                                               action:@selector(addButtonPressed)];
    NSArray *rightBarButtonItems = @[addButton];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    //left side of nav bar
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    UIImage *image = [UIImage imageNamed:@"Settings-Line"];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self
                                                                action:@selector(settingsButtonTapped)];
    UIBarButtonItem *posSpaceAdjust = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [posSpaceAdjust setWidth:28];
    
    self.navigationItem.leftBarButtonItems = @[settings, posSpaceAdjust, editButton];
}

- (void)nowPlayingTapped
{
    
}

- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        //leaving editing mode now
        [super setEditing:NO animated:YES];
        for(UIBarButtonItem *abutton in self.navigationItem.rightBarButtonItems){
            [self makeBarButtonItemNormal:abutton];
        }
    }
    else
    {
        //entering editing mode now
        [super setEditing:YES animated:YES];
        for(UIBarButtonItem *abutton in self.navigationItem.rightBarButtonItems){
            [self makeBarButtonItemGrey: abutton];
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
    barButton.style = UIBarButtonItemStyleBordered;
    barButton.enabled = true;
    return barButton;
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    if([self numberOfArtistsInCoreDataModel] > 0){
        //create search bar, add to viewController
        _searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        _searchBar.placeholder = @"Search Songs";
        _searchBar.keyboardType = UIKeyboardTypeASCIICapable;
        _searchBar.delegate = self;
        [self.searchBar sizeToFit];
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
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setUpSearchBar];  //must be called in viewWillAppear, and after allSongsLibrary is refreshed
    
    if(lastSortOrder != [AppEnvironmentConstants smartAlphabeticalSort])
    {
        [self setFetchedResultsControllerAndSortStyle];
        lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    }

    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft ||
       orientation == UIInterfaceOrientationLandscapeRight||
       orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
    
    if([self numberOfArtistsInCoreDataModel] == 0){ //dont need search bar anymore
        _searchBar = nil;
        self.tableView.tableHeaderView = nil;
    }
    
    [self.tableView reloadData];  //needed to update the font sizes, bold font, and cell height (if changed in settings)
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.topItem.title = @"Artists";
    
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    
    [self setFetchedResultsControllerAndSortStyle];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
    self.tableView.allowsSelectionDuringEditing = YES;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArtistItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Artist *artist;
    //get artist object at this index
    if(self.displaySearchResults)
        artist = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        artist = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // init cell fields
    cell.textLabel.attributedText = [ArtistTableViewFormatter formatArtistLabelUsingArtist:artist];
    if(! [ArtistTableViewFormatter artistNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[ArtistTableViewFormatter nonBoldArtistLabelFontSize]];
    [ArtistTableViewFormatter formatArtistDetailLabelUsingArtist:artist andCell:&cell];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ArtistTableViewFormatter preferredArtistCellHeight];
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        Artist *artist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        //check if any of this artists songs are currently playing (check standalone songs and all the artists albums songs).
        //if so, set the avplayer to nil (and pause it) so it doesn't crash!
        
        for(Song *aSong in artist.standAloneSongs)
        {
            if([[MusicPlaybackController nowPlayingSong] isEqual:aSong])
                [MusicPlaybackController songAboutToBeDeleted];
            [aSong removeAlbumArt];
        }
        for(Album *anAlbum in artist.albums)
        {
            for(Song *aSong in anAlbum.albumSongs)
            {
                if([[MusicPlaybackController nowPlayingSong] isEqual:aSong])
                    [MusicPlaybackController songAboutToBeDeleted];
            }
            [anAlbum removeAlbumArt];
        }
        
        //delete the artist and save changes
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Artist" inManagedObjectContext:[CoreDataManager context]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"artist_id == %@", artist.artist_id];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
        if(matchingData.count == 1)
            [[CoreDataManager context] deleteObject:matchingData[0]];
        [[CoreDataManager sharedInstance] saveContext];
        
        if([self numberOfArtistsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    /*
    //get the index of the tapped artist
    UITableView *tableView = self.tableView;
    for(int i = 0; i < self.allArtists.count; i++){
        UITableViewCell *cell =[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if(cell.selected){
            self.selectedRowIndexValue = i;
            break;
        }
    }
    
    //retrieve the artist object
    Artist *selectedArtist = [self.allArtists objectAtIndex:self.selectedRowIndexValue];
    
    //setup properties in ArtistItemViewController.h
    if([[segue identifier] isEqualToString: @"artistItemSegue"]){
        [[segue destinationViewController] setArtist:selectedArtist];
        
        int artistNumber = self.selectedRowIndexValue + 1;  //remember, for loop started at 0!
        if(artistNumber < 0 || artistNumber == 0)  //object not found in artist model
            artistNumber = -1;
    }
     */
}

#pragma mark - artist editing
- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"ArtistEditDone"]){
        //leave editing mode
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ArtistEditDone" object:nil];
    }
}

- (void)artistWasSavedDuringEditing:(NSNotification *)notification
{
    /*
    if([notification.name isEqualToString:@"ArtistSavedDuringEdit"]){
        [self commitNewSongChanges:(Song *)notification.object];
    }
     */
}

- (void)commitNewArtistChanges:(Artist *)changedSong
{
    /*
    if(changedSong){
        [[CoreDataManager sharedInstance] saveContext];
#warning register for the notification: DataManagerDidSaveFailedNotification  (look in CoreDataManager.m)
        
        self.indexOfEditingSong = -1;
        if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
        
        //[self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongSavedDuringEdit" object:nil];
    }
     */
}

#pragma mark - Adding music to library
//called when + sign is tapped - selector defined in setUpNavBarItems method!
- (void)addButtonPressed
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
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
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

#pragma mark - Rotation tab bar methods
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

#pragma mark - Counting Artists in core data
- (int)numberOfArtistsInCoreDataModel
{
    //count how many instances there are of the Artist entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Artist" inManagedObjectContext:context];
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
    request.predicate = nil;  //means i want all of the songs
    
    NSSortDescriptor *sortDescriptor;
    if([AppEnvironmentConstants smartAlphabeticalSort])
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortArtistName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    else
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"artistName"
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