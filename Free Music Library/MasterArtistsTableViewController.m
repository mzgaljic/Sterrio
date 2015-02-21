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
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@end

@implementation MasterArtistsTableViewController
static BOOL PRODUCTION_MODE;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

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
    return @"Artists";
}


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
#warning needs implementation. should check which artist the now playing song is in...if it has one.
    //want the now playing album to always be a specific color
    [self.tableView reloadData];
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //artists tab is never the first one on screen. no need to animate it
    if([self numberOfArtistsInCoreDataModel] > 0){
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
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUpSearchBar];
    
    if([self numberOfArtistsInCoreDataModel] == 0){ //dont need search bar anymore
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
    self.contentType = MZContentArtists;
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
    self.contentType = MZContentUnspecified;
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
    
    [self setProductionModeValue];
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
    static NSString *cellIdentifier = @"ArtistItemCell";
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
    if(self.displaySearchResults)
        return NO;
    else
        return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        Artist *artist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        //remove songs from queue
        for(Song *aSong in artist.standAloneSongs)
        {
            [MusicPlaybackController songAboutToBeDeleted:aSong];
            [aSong removeAlbumArt];
        }
        for(Album *anAlbum in artist.albums)
        {
            for(Song *aSong in anAlbum.albumSongs)
                [MusicPlaybackController songAboutToBeDeleted:aSong];
            
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ArtistTableViewFormatter preferredArtistCellHeight];
}

#pragma mark - other stuff
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"artistItemSegue"]){
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Unfinished"
                                                          message:@"This action is coming soon."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
        alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        [alert show];
    }

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