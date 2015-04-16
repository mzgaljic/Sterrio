//
//  AllSongsDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/26/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AllSongsDataSource.h"

@interface AllSongsDataSource ()
{
    NSString *cellReuseIdDetailLabelNull;
    UILabel *tableViewEmptyMsgLabel;
    BOOL keyboardIsVisible;
    int emptyTableMsgKeyboardPadding;
    BOOL firstTimeCreatingEmptyTableMsg;
}
@property (nonatomic, assign, readwrite) SONG_DATA_SRC_TYPE dataSourceType;
@property (nonatomic, strong) NSMutableArray *selectedSongIds;
@property (nonatomic, strong) NSOrderedSet *existingPlaylistSongs;

@property (nonatomic, assign, readwrite) BOOL displaySearchResults;
@property (nonatomic, strong) NSArray *searchResults;
@end
@implementation AllSongsDataSource

- (void)setCellReuseId:(NSString *)cellReuseId
{
    _cellReuseId = cellReuseId;
    cellReuseIdDetailLabelNull = [NSString stringWithFormat:@"%@_nilDetail", cellReuseId];
}

- (NSOrderedSet *)existingPlaylistSongs
{
    if(_existingPlaylistSongs == nil && _playlistSongAdderDelegate != nil)
        _existingPlaylistSongs = [_playlistSongAdderDelegate existingPlaylistSongs];
    return _existingPlaylistSongs;
}


#pragma mark - Lifecycle
- (void)dealloc
{
    self.fetchedResultsController = nil;
    self.tableView = nil;
    self.playbackContext = nil;
    self.cellReuseId = nil;
    self.editableSongDelegate = nil;
    self.playlistSongAdderDelegate = nil;
    self.searchBarDataSourceDelegate = nil;
    
    self.selectedSongIds = nil;
    self.existingPlaylistSongs = nil;
    NSLog(@"all songs data source has dealloced!");
}

- (instancetype)initWithSongDataSourceType:(SONG_DATA_SRC_TYPE)type
               searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate
{
    if(self = [super init]){
        stackController = [[StackController alloc] init];
        self.dataSourceType = type;
        self.searchBarDataSourceDelegate = delegate;
        if(type == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
            self.selectedSongIds = [NSMutableArray array];
        
        self.displaySearchResults = NO;
        self.searchResults = [NSMutableArray array];
        keyboardIsVisible = NO;
        emptyTableMsgKeyboardPadding = [UIScreen mainScreen].bounds.size.height * 0.15;
        firstTimeCreatingEmptyTableMsg = YES;
    }
    return self;
}

#pragma mark - UITableViewDataSource
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *song;
    if(self.displaySearchResults)
        song = [self.searchResults objectAtIndex:indexPath.row];
    else
        song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *reuseID;
    if(song.artist || song.album)
        reuseID = self.cellReuseId;
    else
        reuseID = cellReuseIdDetailLabelNull;
    
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
                                                             forIndexPath:indexPath];
    if (!cell)
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:reuseID];
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
    
    if(self.dataSourceType == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
    {
        if([self.existingPlaylistSongs containsObject:song])
        {
            cell.textLabel.enabled = NO;
            cell.detailTextLabel.enabled = NO;
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        else
        {
            cell.textLabel.enabled = YES;
            cell.detailTextLabel.enabled = YES;
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            
            if([_selectedSongIds containsObject:song.song_id])
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            else
                [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    
    
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
                int diff = abs((int)cellImg.size.width - (int)cellImg.size.height);
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
    if(self.dataSourceType == SONG_DATA_SRC_TYPE_Default)
        cell.delegate = self;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.displaySearchResults)
        return NO;

    if(self.dataSourceType == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
        return NO;
    else if (self.dataSourceType == SONG_DATA_SRC_TYPE_Default)
        return YES;
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
        Song *song;
        if(self.displaySearchResults)
            song = [self.searchResults objectAtIndex:indexPath.row];
        else
            song = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        [MusicPlaybackController songAboutToBeDeleted:song deletionContext:self.playbackContext];
        [MZCoreDataModelDeletionService prepareSongForDeletion:song];
        
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
            self.tableView.tableHeaderView = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Song *selectedSong;
    if(self.displaySearchResults)
        selectedSong = [self.searchResults objectAtIndex:indexPath.row];
    else
        selectedSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if(self.dataSourceType == SONG_DATA_SRC_TYPE_Default)
    {
        if(! tableView.editing){
            
            BOOL playerEnabled = [SongPlayerCoordinator isPlayerEnabled];
            BOOL playerOnScreen = [SongPlayerCoordinator isPlayerOnScreen];
            BOOL nowPlayingAndActive = [[NowPlayingSong sharedInstance] isEqualToSong:selectedSong compareWithContext:self.playbackContext] && playerEnabled && playerOnScreen;
            
            if(nowPlayingAndActive){
                UIViewController *visibleVc = [super topViewController];
                [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:visibleVc];
            }
            
            [MusicPlaybackController newQueueWithSong:selectedSong withContext:self.playbackContext];
        }
        else if(tableView.editing)  //tapping song triggers edit segue
            [self.editableSongDelegate performEditSegueWithSong:selectedSong];
    }
    else if(self.dataSourceType == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
    {
        //do stuff for adding song to list of songs to place in playlist
        
        if([self.existingPlaylistSongs containsObject:selectedSong])
            return;
        
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        
        if([selectedCell accessoryType] == UITableViewCellAccessoryNone) //selected row
        {
            [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
            [_selectedSongIds addObject:selectedSong.song_id];
            
            [self.playlistSongAdderDelegate setSuccessNavBarButtonStringValue:Done_String];
        }
        else
        {  //deselected row
            [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
            [_selectedSongIds removeObject:selectedSong.song_id];
            PLAYLIST_STATUS status = [self.playlistSongAdderDelegate currentPlaylistStatus];
            
            if(_selectedSongIds.count == 0 && status == PLAYLIST_STATUS_In_Creation)
                //only happens when playlist created from scratch
                [self.playlistSongAdderDelegate setSuccessNavBarButtonStringValue:AddLater_String];
            
            else if(_selectedSongIds.count == 0 && status == PLAYLIST_STATUS_Created_But_Empty)
                [self.playlistSongAdderDelegate setSuccessNavBarButtonStringValue:@""];
            
            else if(_selectedSongIds.count == 0 && status == PLAYLIST_STATUS_Normal_Playlist)
                [self.playlistSongAdderDelegate setSuccessNavBarButtonStringValue:@""];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.displaySearchResults)
        return UITableViewCellEditingStyleNone;
    
    if(aTableView.editing)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.displaySearchResults)
    {
        if(self.searchResults.count > 0)
        {
            [self removeTableUserMessage];
            return 1;
        }
        else
        {
            NSString *text = @"No Search Results";
            UILabel *aLabel = (UILabel *)[self friendlyTableUserMessageWithText:text];
            tableView.backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            
            CGPoint newLabelCenter;
            if(firstTimeCreatingEmptyTableMsg){
                firstTimeCreatingEmptyTableMsg = NO;
                newLabelCenter = tableView.backgroundView.center;
            } else
                newLabelCenter = CGPointMake(tableView.backgroundView.center.x,
                                             tableView.backgroundView.center.y - emptyTableMsgKeyboardPadding);
                
            aLabel.center = newLabelCenter;
            [tableView.backgroundView addSubview:aLabel];
            return 0;
        }
    }
    else
    {
        NSUInteger numObjsInTable = [self numObjectsInTable];
        if(numObjsInTable == 0){
            NSString *text = self.emptyTableUserMessage;
            tableView.backgroundView = [self friendlyTableUserMessageWithText:text];
        } else
            [self removeTableUserMessage];
        return self.fetchedResultsController.sections.count;
    }
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if(self.displaySearchResults)
        return self.searchResults.count;
    else
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
        return sectionInfo.numberOfObjects;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    int headerFontSize;
    if([AppEnvironmentConstants preferredSizeSetting] < 5)
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    else
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:5];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
}

#pragma  mark - TableView helpers
- (UIView *)friendlyTableUserMessageWithText:(NSString *)text
{
    if(tableViewEmptyMsgLabel){
        if([tableViewEmptyMsgLabel.text isEqualToString:text])
            return tableViewEmptyMsgLabel;
        
        tableViewEmptyMsgLabel.text = text;
        [tableViewEmptyMsgLabel sizeToFit];
        return tableViewEmptyMsgLabel;
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableViewEmptyMsgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       self.tableView.bounds.size.width,
                                                                       self.tableView.bounds.size.height)];
    if(text == nil)
        text = @"";
    tableViewEmptyMsgLabel.text = text;
    tableViewEmptyMsgLabel.textColor = [UIColor darkGrayColor];
    //multi lines strings ARE possible, this is just a weird api detail
    tableViewEmptyMsgLabel.numberOfLines = 0;
    tableViewEmptyMsgLabel.textAlignment = NSTextAlignmentCenter;
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    tableViewEmptyMsgLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                 size:fontSize];
    [tableViewEmptyMsgLabel sizeToFit];
    return tableViewEmptyMsgLabel;
}

- (void)removeTableUserMessage
{
    [tableViewEmptyMsgLabel removeFromSuperview];
    self.tableView.backgroundView = nil;
    tableViewEmptyMsgLabel = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

- (NSUInteger)numObjectsInTable
{
    //used to avoid faulting objects when asking fetchResultsController how many objects exist
    NSString *totalObjCountPathNum = @"@sum.numberOfObjects";
    NSNumber *totalObjCount = [self.fetchedResultsController.sections valueForKeyPath:totalObjCountPathNum];
    return [totalObjCount integerValue];
}

#pragma mark - MGSwipeTableCell delegates
- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction
{
    if(self.dataSourceType == SONG_DATA_SRC_TYPE_Default)
        return YES;
    else
        return NO;
}

- (NSArray*)swipeTableCell:(MGSwipeTableCell*)cell
  swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*)swipeSettings
         expansionSettings:(MGSwipeExpansionSettings*)expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    UIColor *initialExpansionColor = [AppEnvironmentConstants expandingCellGestureInitialColor];
    __weak AllSongsDataSource *weakself = self;
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        Song *song = [self.fetchedResultsController objectAtIndexPath:
                      [self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 99999;
        
        __weak Song *weakSong = song;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           
                                           NSLog(@"Queing up: %@", weakSong.songName);
                                           PlaybackContext *context = [weakself contextForSpecificSong:weakSong];
                                           [MusicPlaybackController queueUpNextSongsWithContexts:@[context]];
                                           [weakCell refreshContentView];
                                           return YES;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 2.7;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureDeleteItemColor];
        swipeSettings.transition = MGSwipeTransitionBorder;
        
        MGSwipeButton *delete = [MGSwipeButton buttonWithTitle:@"Delete"
                                               backgroundColor:expansionSettings.expansionColor
                                                       padding:15
                                                      callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     NSIndexPath *indexPath;
                                     indexPath = [weakself.tableView indexPathForCell:sender];
                                     [weakself tableView:weakself.tableView
                                      commitEditingStyle:UITableViewCellEditingStyleDelete
                                       forRowAtIndexPath:indexPath];
                                     return NO; //don't autohide to improve delete animation
                                 }];
        return @[delete];
    }
    
    return nil;
}

- (PlaybackContext *)contextForSpecificSong:(Song *)aSong
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"song_id == %@", aSong.song_id];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContext.contextId];
}

- (Song *)songObjectGivenSongId:(NSString *)songId
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Song"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"song_id == %@", songId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSArray *results = [[CoreDataManager context] executeFetchRequest:fetchRequest error:nil];
    if(results.count == 1)
        return results[0];
    else
        return nil;
}

- (NSArray *)minimallyFaultedArrayOfSelectedPlaylistSongs
{
    if(self.dataSourceType == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
    {
        //incomplete implementation
        NSMutableArray *selectedSongs = [NSMutableArray arrayWithCapacity:_selectedSongIds.count];
        Song *aSong;
        for(NSString *aSongId in _selectedSongIds)
        {
            aSong = [self songObjectGivenSongId:aSongId];
            if(aSong != nil)
                [selectedSongs addObject:aSong];
        }
        return selectedSongs;
    }
    else
        return nil;
}


#pragma mark - UISearchBarDelegate implementation
- (MySearchBar *)setUpSearchBar
{
    MySearchBar *searchBar;
    if([self numberOfSongsInCoreDataModel] > 0){
        //create search bar, add to viewController
        searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)
                                       placeholderText:@"Search My Music"];
        searchBar.delegate = self;
        self.tableView.tableHeaderView = searchBar;
    }
    return searchBar;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    keyboardIsVisible = NO;
    [self animateTableEmtpyLabelUp:NO];
}

//user tapped search box
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    keyboardIsVisible = YES;
    
    if(searchBar.text.length == 0)
        self.searchResults = [NSArray array];
    
    //show the cancel button
    [searchBar setShowsCancelButton:YES animated:YES];
    [self.searchBarDataSourceDelegate searchBarIsBecomingActive];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:[NSNumber numberWithBool:YES]];
    BOOL oldDisplayResultsVal = self.displaySearchResults;
    self.displaySearchResults = YES;
    
    if(! oldDisplayResultsVal){
        //user is now transitioning into the "search" mode
        [self.tableView reloadData];
    }
    
    [self animateTableEmtpyLabelUp:YES];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //search results already appear as the user types. Just hide the keyboard...
    [searchBar resignFirstResponder];
    keyboardIsVisible = NO;
    self.displaySearchResults = YES;
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.displaySearchResults = NO;
    keyboardIsVisible = NO;
    firstTimeCreatingEmptyTableMsg = YES;
    
    //dismiss search bar and hide cancel button
    [searchBar setShowsCancelButton:NO animated:YES];
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [self.searchBarDataSourceDelegate searchBarIsBecomingInactive];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:[NSNumber numberWithBool:NO]];
    
    [self removeTableUserMessage];
    [self.tableView reloadData];
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.searchResults = [NSArray array];
    self.displaySearchResults = YES;
    if(searchText.length == 0){
        [self.tableView reloadData];
        [self animateTableEmtpyLabelUp:YES];
        return;
    } else{
        [self removeTableUserMessage];
    }
    searchText = [searchText removeIrrelevantWhitespace];
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:50];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    request.sortDescriptors = @[sortDescriptor];
    
    NSMutableString *searchWithWildcards = [NSMutableString stringWithFormat:@"*%@*", searchText];
    if (searchWithWildcards.length > 3){
        for (int i = 2; i < searchText.length * 2; i += 2)
            [searchWithWildcards insertString:@"*" atIndex:i];
    }
    
    //matches against exact string ANYWHERE within the song name
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"songName contains[cd] %@",  searchText];
    
    //matches partial string with song name as long as sequence of letters is correct.
    //see: http://stackoverflow.com/questions/15091155/nspredicate-match-any-characters
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"songName LIKE[cd] %@",  searchWithWildcards];
    request.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    if ([AppEnvironmentConstants isUserOniOS8OrAbove])
    {
        __weak AllSongsDataSource *weakself = self;
        NSAsynchronousFetchRequest *asynchronousFetchRequest =
        [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:request
                                                 completionBlock:^(NSAsynchronousFetchResult *result) {
                                                     if (! result.operationError)
                                                     {
                                                         weakself.searchResults = result.finalResult;
                                                     }
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [weakself.tableView reloadData];
                                                     });
                                                 }];
        [context executeRequest:asynchronousFetchRequest error:NULL];
    }
    else
    {
        self.searchResults = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:nil]];
        [self.tableView reloadData];
    }
}

#pragma mark - Changing interface based on keyboard
- (void)animateTableEmtpyLabelUp:(BOOL)animateUp
{
    if(tableViewEmptyMsgLabel)
    {
        UIView *backgroundView = self.tableView.backgroundView;
        float duration = 1;
        float delay = 0.3;
        float springDamping = 0.80;
        float initialVelocity = 0.5;
        
        //see if the center values are roughly the same...
        if(fabs(tableViewEmptyMsgLabel.center.y -  backgroundView.center.y) <= 20)
        {
            if(! animateUp)
                return;
            CGRect newLabelFrame = CGRectMake(tableViewEmptyMsgLabel.frame.origin.x,
                                              tableViewEmptyMsgLabel.frame.origin.y - emptyTableMsgKeyboardPadding,
                                              tableViewEmptyMsgLabel.frame.size.width,
                                              tableViewEmptyMsgLabel.frame.size.height);
            [UIView animateWithDuration:duration
                                  delay:delay
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:initialVelocity
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [tableViewEmptyMsgLabel setFrame:newLabelFrame];
                             }
                             completion:nil];
        }
        else
        {
            if(animateUp)
                return;
            [UIView animateWithDuration:duration
                                  delay:delay
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:initialVelocity
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 tableViewEmptyMsgLabel.center = backgroundView.center;
                             }
                             completion:nil];
        }
    }
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

@end
