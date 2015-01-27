//
//  MasterSongsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterSongsTableViewController.h"

@interface MasterSongsTableViewController ()
@property (nonatomic, assign) int indexOfEditingSong;
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, strong) MySearchBar* searchBar;
@end

@implementation MasterSongsTableViewController
static BOOL PRODUCTION_MODE;
static BOOL haveCheckedCoreDataInit = NO;

#pragma mark - Miscellaneous
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
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = true;
    return barButton;
}

- (void)currentSongHasChanged
{
    //want the now playing song to always be a specific colo
    [self.tableView reloadData];
}


#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    if([self numberOfSongsInCoreDataModel] > 0 && _searchBar == nil){
        //create search bar, add to viewController
        _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0) placeholderText:@"Search Songs"];
        _searchBar.delegate = self;
        self.tableView.tableHeaderView = _searchBar;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
}

//user tapped search box
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
    if(searchText.length == 0)
    {
        self.displaySearchResults = NO;
        self.searchFetchedResultsController = nil;
    }
    else
    {
        self.displaySearchResults = YES;
        
        self.searchFetchedResultsController = nil;
        NSManagedObjectContext *context = [CoreDataManager context];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
        
        if([AppEnvironmentConstants smartAlphabeticalSort])
            
            request.predicate = [NSPredicate predicateWithFormat:@"smartSortSongName CONTAINS[cd] %@", searchText];
        else
            request.predicate = [NSPredicate predicateWithFormat:@"songName CONTAINS[cd] %@", searchText];
        
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
        //searchResults
        self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                  managedObjectContext:context
                                                                                    sectionNameKeyPath:nil
                                                                                             cacheName:nil];
    }
}


#pragma mark - View Controller life cycle
static BOOL lastSortOrder;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
        
    [self setUpSearchBar];
    //must be called in viewWillAppear, and after allSongsLibrary is refreshed
    if(self.searchFetchedResultsController)
    {
        self.searchFetchedResultsController = nil;
        [self setFetchedResultsControllerAndSortStyle];
        lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    }
    
    if(lastSortOrder != [AppEnvironmentConstants smartAlphabeticalSort])
    {
        [self setFetchedResultsControllerAndSortStyle];
        lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation != UIInterfaceOrientationPortrait)
        [self setTabBarVisible:NO animated:YES];
    else
        [self setTabBarVisible:YES animated:YES];
    
    if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
        _searchBar = nil;
        self.tableView.tableHeaderView = nil;
    }
    
    [self setFetchedResultsControllerAndSortStyle];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(haveCheckedCoreDataInit){
        [self.tableView reloadData];  //needed to update the font sizes and bold font (if changed in settings)
        //need to check because when user presses back button, tab bar isnt always hidden
        [self prefersStatusBarHidden];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingModeCompleted:)
                                                 name:@"SongEditDone"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(songWasSavedDuringEditing:)
                                                 name:@"SongSavedDuringEdit"
                                               object:nil];
    lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    
    stackController = [[StackController alloc] init];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
    self.tableView.allowsSelectionDuringEditing = YES;
    
    if([AppEnvironmentConstants isFirstTimeAppLaunched]){
        NSString *msg = @"Thanks for being a beta tester. The ugly tab bar below will be changed soon, pardon the hideous look. The rest of the application should look great though! Bugs may be reported via the settings view or the Testflight app itself I believe.";
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Welcome"
                                                          message:msg
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
        NSString *msg2 = @"Some things to note:\n-The settings view will receive a complete overhaul at some point. I don't like it, and many of the settings seem a bit useless.\n-Playing a saved video will NOT display a loading spinner. The spinner caused my app to crash and I am working to bring the loading spinner back. The same applies when skipping songs.\n-The process of adding album art to a song is tedious at the moment. I apologize, and I am working on verhauling this step as well.";
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
        alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        
        alert2.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert2.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert2.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        
        alert3.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert3.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        alert3.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        [alert3 show];
        [alert2 show];
        [alert show];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];

    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SongItemCell"];
    else
    {
        // If an existing cell is being reused, reset the image to the default until it is populated.
        // Without this code, previous images are displayed against the new people during rapid scrolling.
        cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor] width:cell.frame.size.height height:cell.frame.size.height];
    }
    
    // Set up other aspects of the cell content.
    Song *song;
    if(self.displaySearchResults)
        song = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        song = [self.fetchedResultsController objectAtIndexPath:indexPath];

    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    if([[MusicPlaybackController nowPlayingSong].song_id isEqual:song.song_id])
        cell.textLabel.textColor = [UIColor defaultAppColorScheme];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &songIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                    [AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]]];
        if(albumArt == nil) //see if this song has an album. If so, check if it has art.
            if(song.album != nil)
                albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                   [AlbumArtUtilities albumArtFileNameToNSURL:song.album.albumArtFileName]]];
        albumArt = [AlbumArtUtilities imageWithImage:albumArt scaledToSize:CGSizeMake(cell.frame.size.height, cell.frame.size.height)];
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                cell.imageView.image = albumArt;
            }
        });
    }];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    if(self.displaySearchResults)
        return NO;
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SongTableViewFormatter preferredSongCellHeight];
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //obtain object for the deleted song
        Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [MusicPlaybackController songAboutToBeDeleted:song];
        [song removeAlbumArt];
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:[CoreDataManager context]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"song_id == %@", song.song_id];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
        if(matchingData.count == 1)
            [[CoreDataManager context] deleteObject:matchingData[0]];
        [[CoreDataManager sharedInstance] saveContext];

        if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedRowIndexValue = (int)indexPath.row;
    UIBarButtonItem *editButton = self.navigationItem.leftBarButtonItems[2];
    Song *selectedSong;
    if(self.displaySearchResults)
        selectedSong = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        selectedSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if([editButton.title isEqualToString:@"Edit"]){  //tapping song plays the song
        short code = [GenreConstants noGenreSelectedGenreCode];
        [MusicPlaybackController newQueueWithSong:selectedSong album:nil artist:nil playlist:nil genreCode:code skipCurrentSong:YES];
        [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:self];
        
    } else if([editButton.title isEqualToString:@"Done"]){  //tapping song triggers edit segue
        
        //now segue to modal view where user can edit the tapped song
        [self performSegueWithIdentifier:@"editingSongMasterSegue" sender:selectedSong];
    }
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
        //leave editing mode
        [self.tableView reloadData];
    }
}

- (void)songWasSavedDuringEditing:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"SongSavedDuringEdit"]){
        [self commitNewSongChanges:(Song *)notification.object];
    }
}

- (void)commitNewSongChanges:(Song *)changedSong
{
    if(changedSong){
        [[CoreDataManager sharedInstance] saveContext];
//may want to register for the notification: DataManagerDidSaveFailedNotification  (crash during core data undo operation)
        
        self.indexOfEditingSong = -1;
        if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
        [self setFetchedResultsControllerAndSortStyle];  //in case song name changed, etc...
    }
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

#pragma mark - Counting Songs in core data
- (int)numberOfSongsInCoreDataModel
{
    //count how many instances there are of the Song entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:context];
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
    self.searchFetchedResultsController = nil;
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
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
