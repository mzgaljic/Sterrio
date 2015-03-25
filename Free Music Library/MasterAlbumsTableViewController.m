//
//  MasterAlbumsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterAlbumsTableViewController.h"

@interface MasterAlbumsTableViewController()
@property (nonatomic, assign) int indexOfEditingArtist;
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@end

@implementation MasterAlbumsTableViewController
static BOOL PRODUCTION_MODE;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

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
    //albums tab is never the first one on screen. no need to animate it
    if([self numberOfAlbumsInCoreDataModel] > 0){
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
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    //this works better than a unique random id since this class can be dealloced and re-alloced
    //later. Id must stay the same across all allocations.  :)
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    self.emptyTableUserMessage = @"No Albums";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForNavigationBar];
    self.navigationItem.leftBarButtonItems = [self leftBarButtonItemsForNavigationBar];
    [self setTableForCoreDataView:self.tableView];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.cellReuseId = @"AlbumItemCell";
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
    
    stackController = [[StackController alloc] init];
    [self setProductionModeValue];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Album *album;
    if(self.displaySearchResults)
        album = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        album = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
                                                             forIndexPath:indexPath];
    if (!cell)
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:self.cellReuseId];
    else
    {
        // If an existing cell is being reused, reset the image to the default until it is
        // populated. Without this code, previous images are displayed against the new people
        // during rapid scrolling.
        cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor] width:cell.frame.size.height height:cell.frame.size.height];
    }
    
    //Set up other aspects of the cell content.
    MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR
                                                                               color:[[UIColor defaultAppColorScheme] lighterColor]];
    cell.editingAccessoryView = coloredDisclosureIndicator;
    cell.accessoryView = coloredDisclosureIndicator;
    
    cell.textLabel.text = @"empty string";
    cell.textLabel.attributedText = [AlbumTableViewFormatter formatAlbumLabelUsingAlbum:album];
    if(! [AlbumTableViewFormatter albumNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[AlbumTableViewFormatter nonBoldAlbumLabelFontSize]];
    [AlbumTableViewFormatter formatAlbumDetailLabelUsingAlbum:album andCell:&cell];
    
    //check if a song in this album is the now playing song
#warning this check is wrong! should be fixed to be more accurate (use context)
    BOOL albumHasNowPlaying = NO;
    for(Song *albumSong in album.albumSongs)
    {
        if([[MusicPlaybackController nowPlayingSong].song_id isEqual:albumSong.song_id]){
            albumHasNowPlaying = YES;
            break;
        }
    }
    
    if(albumHasNowPlaying)
        cell.textLabel.textColor = [super colorForNowPlayingItem];
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
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:[AlbumArtUtilities albumArtFileNameToNSURL:album.albumArtFileName]]];
        
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.

                __weak UIImage *cellImg = albumArt;
                //calculate how much one length varies from the other.
                int diff = abs(albumArt.size.width - albumArt.size.height);
                if(diff > 10){
                    //image is not a perfect (or close to perfect) square. Compensate for this...
                    cellImg = [albumArt imageScaledToFitSize:cell.imageView.frame.size];
                }
                [UIView transitionWithView:cell.imageView
                                  duration:MZCellImageViewFadeDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = cellImg;
                                } completion:nil];
            }
        });
    }];
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
        //obtain object for the deleted album
        Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        //remove songs from queue if they are in it
        for(Song *aSong in album.albumSongs)
        {
            [MusicPlaybackController songAboutToBeDeleted:aSong
                                          deletionContext:self.playbackContext];
            [aSong removeAlbumArt];
        }
        
        //delete the album and save changes
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:[CoreDataManager context]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album_id == %@", album.album_id];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
        if(matchingData.count == 1)
            [[CoreDataManager context] deleteObject:matchingData[0]];
        [[CoreDataManager sharedInstance] saveContext];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(self.editing)
        return;
    else{
        Album *tappedAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self performSegueWithIdentifier:@"albumItemSegue" sender:tappedAlbum];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AlbumTableViewFormatter preferredAlbumCellHeight];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
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
        Album *album = [self.fetchedResultsController
                     objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak MasterAlbumsTableViewController *weakself = self;
        __weak Album *weakAlbum = album;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           NSLog(@"Queing up: %@", weakAlbum.albumName);
                                           
                                           PlaybackContext *context = [weakself contextForSpecificAlbum:weakAlbum];
                                           [MusicPlaybackController queueUpNextSongsWithContexts:@[context]];
                                           [weakCell refreshContentView];
                                           return YES;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 2.7;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureDeleteItemColor];
        swipeSettings.transition = MGSwipeTransitionBorder;
        
        __weak MasterAlbumsTableViewController *weakSelf = self;
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

#pragma mark - other stuff
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"albumItemSegue"]){
        [[segue destinationViewController] setAlbum:(Album *)sender];
    }
}

- (NSAttributedString *)BoldAttributedStringWithString:(NSString *)aString withFontSize:(float)fontSize
{
    if(! aString)
        return nil;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:aString];
    [attributedText addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:NSMakeRange(0, [aString length])];
    return attributedText;
}

#pragma mark - artist editing
- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"AlbumEditDone"]){
        //leave editing mode
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AlbumEditDone" object:nil];
    }
}

- (void)albumWasSavedDuringEditing:(NSNotification *)notification
{
    /*
     if([notification.name isEqualToString:@"AlbumSavedDuringEdit"]){
     [self commitNewSongChanges:(Song *)notification.object];
     }
     */
}

- (void)commitNewAlbumChanges:(Artist *)changedAlbum
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

#pragma mark - Helper
- (PlaybackContext *)contextForSpecificAlbum:(Album *)anAlbum
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY album.album_id == %@", anAlbum.album_id];
    
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
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContextUniqueId];
}

#pragma mark - Counting Albums in core data
- (int)numberOfAlbumsInCoreDataModel
{
    //count how many instances there are of the Artist entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:context];
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    request.predicate = nil;  //means i want all of the albums
    
    NSSortDescriptor *sortDescriptor;
    if([AppEnvironmentConstants smartAlphabeticalSort])
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    else
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"albumName"
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