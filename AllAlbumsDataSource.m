//
//  AllAlbumsDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AllAlbumsDataSource.h"
#import "StackController.h"
#import "MZTableViewCell.h"
#import "MusicPlaybackController.h"
#import "AlbumAlbumArt+Utilities.h"
#import "PlayableItem.h"

@interface AllAlbumsDataSource ()
{
    NSString *cellReuseIdDetailLabelNull;
    PlayableDataSearchDataSource *playableSearchBarDataSourceDelegate;
}
@property (nonatomic, assign, readwrite) ALBUM_DATA_SRC_TYPE dataSourceType;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) Album *selectedAlbum;  //for album picker VC's

//@property (nonatomic, strong) NSMutableArray *selectedSongIds;
//@property (nonatomic, strong) NSOrderedSet *existingPlaylistSongs;
@end

@implementation AllAlbumsDataSource

- (void)setCellReuseId:(NSString *)cellReuseId
{
    _cellReuseId = cellReuseId;
    cellReuseIdDetailLabelNull = [NSString stringWithFormat:@"%@_nilDetail", cellReuseId];
}

/*
- (NSOrderedSet *)existingPlaylistSongs
{
    if(_existingPlaylistSongs == nil && _playlistSongAdderDelegate != nil)
        _existingPlaylistSongs = [_playlistSongAdderDelegate existingPlaylistSongs];
    return _existingPlaylistSongs;
}
 */

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    
    if(! playableSearchBarDataSourceDelegate)
        playableSearchBarDataSourceDelegate = [[PlayableDataSearchDataSource alloc] initWithTableView:self.tableView
                                                                 playableDataSearchDataSourceDelegate:self
                                                                          searchBarDataSourceDelegate:self];
}

#pragma mark - LifeCycle
- (void)dealloc
{
    playableSearchBarDataSourceDelegate = nil;
    self.fetchedResultsController = nil;
    self.tableView = nil;
    self.playbackContext = nil;
    self.cellReuseId = nil;
    self.actionableAlbumDelegate = nil;
    //self.playlistSongAdderDelegate = nil;
    self.searchBarDataSourceDelegate = nil;
    stackController = nil;
    
    //self.selectedSongIds = nil;
    //self.existingPlaylistSongs = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%@ dealloced!", NSStringFromClass([self class]));
}

- (instancetype)initWithAlbumDataSourceType:(ALBUM_DATA_SRC_TYPE)type
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;
{
    if(self = [super init]){
        stackController = [[StackController alloc] init];
        self.dataSourceType = type;
        self.searchBarDataSourceDelegate = delegate;
        //if(type == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
        //    self.selectedSongIds = [NSMutableArray array];
        [self setupAppThemeColorObserver];
    }
    return self;
}

- (instancetype)initWithAlbumDataSourceType:(ALBUM_DATA_SRC_TYPE)type
                              selectedAlbum:(Album *)anAlbum
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate
{
    if(self = [super init]){
        self.selectedAlbum = anAlbum;
        stackController = [[StackController alloc] init];
        self.dataSourceType = type;
        self.searchBarDataSourceDelegate = delegate;
        
        [self setupAppThemeColorObserver];
    }
    return self;
}

- (void)setupAppThemeColorObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCellsDueToAppThemeChange)
                                                 name:@"app theme color has possibly changed"
                                               object:nil];
}

#pragma mark - Overriding functionality
- (void)clearSearchResultsDataSource
{
    [self.searchResults removeAllObjects];
}

- (NSIndexPath *)indexPathInSearchTableForObject:(id)someObject
{
    if([someObject isMemberOfClass:[Album class]])
    {
        Album *someAlbum = (Album *)someObject;
        NSUInteger albumIndex = [self.searchResults indexOfObject:someAlbum];
        if(albumIndex == NSNotFound)
            return nil;
        else{
            return [NSIndexPath indexPathForRow:albumIndex inSection:0];
        }
    }
    else
        return nil;
}

#pragma mark - Custom stuff
//exposed so that the Album VC can check if any visible Album cells contain "dirty" album art.
- (Album *)albumAtIndexPath:(NSIndexPath *)indexPath
{
    Album *album;
    if(self.displaySearchResults)
        album = [self.searchResults objectAtIndex:indexPath.row];
    else
        album = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return album;
}

#pragma mark - UITableViewDataSource
static char albumIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Album *album = [self albumAtIndexPath:indexPath];
    
    NSString *reuseID;
    if(album.artist)
        reuseID = self.cellReuseId;
    else
        reuseID = cellReuseIdDetailLabelNull;
    
    MZTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
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
    
    cell.textLabel.text = album.albumName;
    
    if(![reuseID isEqualToString:cellReuseIdDetailLabelNull])
        cell.detailTextLabel.text = album.artist.artistName;
    else
        cell.detailTextLabel.text = nil;
    
    if(self.dataSourceType == ALBUM_DATA_SRC_TYPE_Default)
    {
        //Set up other aspects of the cell content.
        short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
        UIColor *appTheme = [[UIColor defaultAppColorScheme] lighterColor];
        MSCellAccessory *chevron = [MSCellAccessory accessoryWithType:flatIndicator
                                                                color:appTheme];
        cell.editingAccessoryView = chevron;
        cell.accessoryView = chevron;
        
        //check if a song in this album is the now playing song
        BOOL albumHasNowPlaying = NO;
        NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
        
        NSMutableString *albumDetailContextId = [NSMutableString string];
        [albumDetailContextId appendString:NSStringFromClass([AlbumItemViewController class])];
        [albumDetailContextId appendString:album.uniqueId];
        
        PlaybackContext *albumDetailContext = [[PlaybackContext alloc] initWithFetchRequest:nil
                                                                            prettyQueueName:@"" contextId:albumDetailContextId];
        for(Song *albumSong in album.albumSongs)
        {
            //need to check both the general album context and the albumDetailVC context.
            //...since an entire album or just a specific album can be queued up.
            if([nowPlayingObj.nowPlayingItem isEqualToSong:albumSong withContext:self.playbackContext]
               ||
               [nowPlayingObj.nowPlayingItem isEqualToSong:albumSong withContext:albumDetailContext])
            {
                albumHasNowPlaying = YES;
                break;
            }
        }
        
        if(albumHasNowPlaying)
            cell.textLabel.textColor = [super colorForNowPlayingItem];
        else
            cell.textLabel.textColor = [UIColor blackColor];
    }
    else if(self.dataSourceType == ALBUM_DATA_SRC_TYPE_Single_Album_Picker)
    {
        BOOL isCurrentlySelectedAlbum = [self.selectedAlbum.uniqueId isEqualToString:album.uniqueId];
        
        if(isCurrentlySelectedAlbum){
            UIColor *appThemeSuperLight = [[[[[UIColor defaultAppColorScheme] lighterColor] lighterColor] lighterColor] lighterColor];
            cell.backgroundColor = appThemeSuperLight;
            [cell setUserInteractionEnabled:NO];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.detailTextLabel.textColor = [UIColor whiteColor];
        } else{
            cell.backgroundColor = [UIColor clearColor];
            [cell setUserInteractionEnabled:YES];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
    }
    
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &albumIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    __weak Album *weakalbum = album;
    cell.anAlbumArtClass = album.albumArt;
    [cell layoutIfNeeded];
    CGSize cellImgSize = cell.imageView.frame.size;
    
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        __block UIImage *albumArt;
        if(weakalbum){
            
            //this is a background queue. get the object (image blob) on background context!
            NSManagedObjectContext *context = [CoreDataManager stackControllerThreadContext];
            [context performBlockAndWait:^{
                albumArt = [weakalbum.albumArt imageWithSize:cellImgSize];
            }];
            
            if(albumArt == nil)
                return;  //no album art loaded lol.
        }
        
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &albumIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                
                __weak UIImage *cellImg = albumArt;
                //calculate how much one length varies from the other.
                int diff = abs((int)albumArt.size.width - (int)albumArt.size.height);
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
    
    if(self.dataSourceType == ALBUM_DATA_SRC_TYPE_Single_Album_Picker)
        return NO;
    else if (self.dataSourceType == SONG_DATA_SRC_TYPE_Default)
        return YES;
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AppEnvironmentConstants preferredSongCellHeight];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //obtain object for the deleted album
        Album *album;
        if(self.displaySearchResults)
            album = [self.searchResults objectAtIndex:indexPath.row];
        else
             album = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        [MZCoreDataModelDeletionService prepareAlbumForDeletion:album];
        
        //remove songs from queue if they are in it
        for(Song *aSong in album.albumSongs)
        {
            [MusicPlaybackController songAboutToBeDeleted:aSong
                                          deletionContext:self.playbackContext];
            aSong.albumArt = nil;
        }
        
        //delete the album and save changes
        [[CoreDataManager context] deleteObject:album];
        [[CoreDataManager sharedInstance] saveContext];
        
        //this class is responsible for animating this cell since the fetchedResultsController
        //isnt active when displaying search results.
        if(self.displaySearchResults)
        {
            BOOL lastRow =(self.searchResults.count == 1);
            [self.tableView beginUpdates];
            
            if(lastRow)
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                              withRowAnimation:UITableViewRowAnimationMiddle];
            else
                //just delete this row in the section
                [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationMiddle];
            
            [self.searchResults removeObjectAtIndex:indexPath.row];
            [self.tableView endUpdates];
        }
        
        if([self numObjectsInTable] == 0){ //dont need search bar anymore
            if(self.displaySearchResults){
                MySearchBar *searchbar = (MySearchBar *)self.tableView.tableHeaderView;
                [searchbar resignFirstResponder];
                self.displaySearchResults = NO;
                [self.searchBarDataSourceDelegate searchBarIsBecomingInactive];
            }
            self.tableView.tableHeaderView = nil;
            [self.tableView reloadData];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Album *tappedAlbum;
    if(self.displaySearchResults)
        tappedAlbum = [self.searchResults objectAtIndex:indexPath.row];
    else
        tappedAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if(self.dataSourceType == ALBUM_DATA_SRC_TYPE_Default)
    {
        if(tableView.editing)
            [self.actionableAlbumDelegate performEditSegueWithAlbum:tappedAlbum];
        else
            [self.actionableAlbumDelegate performAlbumDetailVCSegueWithAlbum:tappedAlbum];
    }
    else if(self.dataSourceType == ALBUM_DATA_SRC_TYPE_Single_Album_Picker)
    {
        [self.actionableAlbumDelegate userDidSelectAlbumFromSinglePicker:tappedAlbum];
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
        if(self.searchResults.count > 0){
            [playableSearchBarDataSourceDelegate removeEmptyTableUserMessage];
            return 1;
        }
        else{
            NSString *text = @"No Search Results";
            [playableSearchBarDataSourceDelegate displayEmptyTableUserMessageWithText:text];
            return 0;
        }
    }
    else
    {
        if([self numObjectsInTable] == 0){
            NSString *text = self.emptyTableUserMessage;
            [playableSearchBarDataSourceDelegate displayEmptyTableUserMessageWithText:text];
        } else
            [playableSearchBarDataSourceDelegate removeEmptyTableUserMessage];
        
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
    int headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
}

#pragma mark - efficiently updating individual cells as needed
- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification
{
    if(self.playbackContext == nil)
        return;
    Song *oldsong = (Song *)[notification object];
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    Song *newSong = nowPlaying.nowPlayingItem.songForItem;
    
    Album *oldAlbum = oldsong.album;
    Album *newAlbum = newSong.album;
    NSIndexPath *oldPath, *newPath;
    
    //tries to obtain the path to the changed albums if possible.
    if(self.displaySearchResults){
        oldPath = [self indexPathInSearchTableForObject:oldAlbum];
        newPath = [self indexPathInSearchTableForObject:newAlbum];
    } else{
        oldPath = [self.fetchedResultsController indexPathForObject:oldAlbum];
        newPath = [self.fetchedResultsController indexPathForObject:newAlbum];
    }
    
    if(oldPath || newPath){
        [self.tableView beginUpdates];
        if(oldPath)
            [self.tableView reloadRowsAtIndexPaths:@[oldPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        if(newPath != nil && newPath != oldPath)
            [self.tableView reloadRowsAtIndexPaths:@[newPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}


#pragma mark - MGSwipeTableCell delegates
- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction
{
    if(self.dataSourceType == ALBUM_DATA_SRC_TYPE_Default)
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
    NSIndexPath *cellPath = [self.tableView indexPathForCell:cell];
    __weak NSIndexPath *weakPath = cellPath;
    __weak AllAlbumsDataSource *weakSelf = self;
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        
        Album *album = [self.fetchedResultsController objectAtIndexPath:cellPath];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak Album *weakAlbum = album;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MZPlaybackQueue presentQueuedHUD];
                                           PlaybackContext *context = [weakSelf contextForSpecificAlbum:weakAlbum];
                                           NSArray *cnxt = @[context];
                                           [MusicPlaybackController queueUpNextSongsWithContexts:cnxt];
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
                                     [weakSelf tableView:weakSelf.tableView
                                      commitEditingStyle:UITableViewCellEditingStyleDelete
                                       forRowAtIndexPath:weakPath];
                                     return NO; //don't autohide to improve delete animation
                                 }];
        return @[delete];
    }
    
    return nil;
}

- (PlaybackContext *)contextForSpecificAlbum:(Album *)anAlbum
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY album.album_id == %@", anAlbum.uniqueId];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContext.contextId];
}

/*
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
 */

- (MySearchBar *)setUpSearchBar
{
    return [playableSearchBarDataSourceDelegate setUpSearchBar];
}

#pragma mark - SearchBarDataSourceDelegate implementation
- (NSString *)placeholderTextForSearchBar
{
    return [self.searchBarDataSourceDelegate placeholderTextForSearchBar];
}

- (void)searchBarIsBecomingActive
{
    [self.searchBarDataSourceDelegate searchBarIsBecomingActive];
}

- (void)searchBarIsBecomingInactive
{
    [self.searchBarDataSourceDelegate searchBarIsBecomingInactive];
}

#pragma mark - PlayableDataSearchDataSourceDelegate implementation
- (NSFetchRequest *)fetchRequestForSearchBarQuery:(NSString *)query
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:50];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    request.predicate = [self generateCompoundedPredicateGivenQuery:query];
    return request;
}

- (void)searchResultsShouldBeDisplayed:(BOOL)displaySearchResults
{
    self.displaySearchResults = displaySearchResults;
}

- (void)searchResultsFromUsersQuery:(NSArray *)modelObjects
{
    [self.searchResults removeAllObjects];
    [self.searchResults addObjectsFromArray:modelObjects];
}

- (NSUInteger)playableDataSourceEntireModelCount
{
    return [self numObjectsInTable];
}

- (NSPredicate *)generateCompoundedPredicateGivenQuery:(NSString *)query
{
    NSMutableString *searchWithWildcards = [NSMutableString stringWithFormat:@"*%@*", query];
    if (searchWithWildcards.length > 3){
        for (int i = 2; i < query.length * 2; i += 2)
            [searchWithWildcards insertString:@"*" atIndex:i];
    }
    
    //matches against exact string ANYWHERE within the album name
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"albumName contains[cd] %@",  query];
    
    //matches partial string with song name as long as sequence of letters is correct.
    //see: http://stackoverflow.com/questions/15091155/nspredicate-match-any-characters
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"albumName LIKE[cd] %@",  searchWithWildcards];
    
    //matches against exact string ANYWHERE within the albums artist name
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"self.artist.artistName contains[cd] %@",  query];
    
    //matches partial string with albums artist name as long as sequence of letters is correct. (see link few lines above)
    NSPredicate *predicate4 = [NSPredicate predicateWithFormat:@"self.artist.artistName LIKE[cd] %@",  searchWithWildcards];
    return [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1,
                                                               predicate2,
                                                               predicate3,
                                                               predicate4]];
}

#pragma mark - Miscellaneous
- (void)updateCellsDueToAppThemeChange
{
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    if(visiblePaths.count > 0){
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:visiblePaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (NSUInteger)numObjectsInTable
{
    if(self.displaySearchResults)
        return self.searchResults.count;
    else
    {
        //used to avoid faulting objects when asking fetchResultsController how many objects exist
        NSString *totalObjCountPathNum = @"@sum.numberOfObjects";
        NSNumber *totalObjCount = [self.fetchedResultsController.sections valueForKeyPath:totalObjCountPathNum];
        return [totalObjCount integerValue];
    }
}

@end
