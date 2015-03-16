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
@property (nonatomic, strong) MySearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//used so i can retain control over the "greying out" effect from this VC.
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@end

@implementation MasterSongsTableViewController
static BOOL PRODUCTION_MODE;
static BOOL haveCheckedCoreDataInit = NO;

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
    self.rightBarButtonItems = @[self.editButton];
    return self.rightBarButtonItems;
}

#pragma mark - Miscellaneous
- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}
                                   
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
    if([self numberOfSongsInCoreDataModel] > 0){
        //create search bar, add to viewController
        _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0) placeholderText:@"Search My Library"];
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
        self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    }
}


#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
        _searchBar = nil;
        self.tableView.tableHeaderView = nil;
    }
    [self setUpSearchBar];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForNavigationBar];
    self.navigationItem.leftBarButtonItems = [self leftBarButtonItemsForNavigationBar];
    [self setTableForCoreDataView:self.tableView];
    self.cellReuseId = @"SongItemCell";
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
    
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingModeCompleted:)
                                                 name:@"SongEditDone"
                                               object:nil];
    stackController = [[StackController alloc] init];
    
    [self setProductionModeValue];
    self.tableView.allowsSelectionDuringEditing = YES;
    
    //This is a ghetto version of an official welcome screen.
    if([AppEnvironmentConstants shouldDisplayWelcomeScreen]){
        NSString *msg = @"Thanks for being a beta tester. Bugs may be reported via the settings view or the Testflight app itself I believe.";
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Welcome"
                                                          message:msg
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
        NSString *msg2 = @"Some things to note:\n-The settings view will receive a complete overhaul at some point. I don't like it, and many of the settings seem a bit useless.\n-The process of adding album art to a song is tedious at the moment. I apologize, and I am working on improving this.";
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
        alert.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert.messageLabelFont = [UIFont systemFontOfSize:20];
        alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        
        alert2.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert2.messageLabelFont = [UIFont systemFontOfSize:20];
        alert2.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        
        alert3.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert3.messageLabelFont = [UIFont systemFontOfSize:20];
        alert3.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
        [alert3 show];
        [alert2 show];
        [alert show];
    } else if([AppEnvironmentConstants shouldDisplayWhatsNewScreen]){
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Whats New"
                                                           message:MZWhatsNewUserMsg
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles: nil];
        alert.titleLabelFont = [UIFont boldSystemFontOfSize:20];
        alert.messageLabelFont = [UIFont systemFontOfSize:20];
        alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:20];
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
    Song *song;
    if(self.displaySearchResults)
        song = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
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
    
    // Set up other aspects of the cell content.
    cell.editingAccessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR
                                                             color:[[UIColor defaultAppColorScheme] lighterColor]];
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    BOOL isNowPlaying = [[NowPlayingSong sharedInstance] isEqualToSong:song compareWithContext:self.playbackContext];
    if(isNowPlaying)
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
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                    [AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]]];
        if(albumArt == nil) //see if this song has an album. If so, check if it has art.
            if(song.album != nil)
                albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                   [AlbumArtUtilities albumArtFileNameToNSURL:song.album.albumArtFileName]]];
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
        #warning fix!
       // [MusicPlaybackController songAboutToBeDeleted:song deletionContext:SongPlaybackContextSongs];
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
    Song *selectedSong;
    if(self.displaySearchResults)
        selectedSong = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        selectedSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if([self.editButton.title isEqualToString:@"Edit"]){  //tapping song plays the song
        [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:self];
        [MusicPlaybackController newQueueWithSong:selectedSong withContext:self.playbackContext skipCurrentSong:YES];
        
    } else if([self.editButton.title isEqualToString:@"Done"]){  //tapping song triggers edit segue
        //now segue to modal view where user can edit the tapped song
        [self performSegueWithIdentifier:@"editingSongMasterSegue" sender:selectedSong];
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
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        Song *song = [self.fetchedResultsController objectAtIndexPath:
                    [self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak MasterSongsTableViewController *weakself = self;
        __weak Song *weakSong = song;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:[AppEnvironmentConstants expandingCellGestureInitialColor]
                                        padding:40
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           
                                           NSLog(@"Queing up: %@", weakSong.songName);
                                           PlaybackContext *context = [weakself contextForSpecificSong:weakSong];
                                           [[MZPlaybackQueue sharedInstance] addSongsToPlayingNextWithContexts:@[context]];
                                           [weakCell refreshContentView];
                                           return YES;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        
    }
    return nil;
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
        self.indexOfEditingSong = -1;
        if([self numberOfSongsInCoreDataModel] == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
    }
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

#pragma mark - Helper
- (PlaybackContext *)contextForSpecificSong:(Song *)aSong
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY song_id == %@", aSong.song_id];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy] prettyQueueName:@""];
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
    if(self.playbackContext == nil){
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:@"All Songs"];
    }
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
