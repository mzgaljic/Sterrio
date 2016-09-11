//
//  AllPlaylistsDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/22/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AllPlaylistsDataSource.h"
#import "StackController.h"
#import "MZTableViewCell.h"
#import "MusicPlaybackController.h"
#import "PreviousNowPlayingInfo.h"
#import "PlaylistItem.h"
#import "PlayableItem.h"

@interface AllPlaylistsDataSource ()
{
    NSString *cellReuseIdDetailLabelNull;
    PlayableDataSearchDataSource *playableSearchBarDataSourceDelegate;
}
@property (nonatomic, assign, readwrite) PLAYLIST_DATA_SRC_TYPE dataSourceType;
@property (nonatomic, strong) NSMutableArray *searchResults;

@end
@implementation AllPlaylistsDataSource

- (void)setCellReuseId:(NSString *)cellReuseId
{
    _cellReuseId = cellReuseId;
    cellReuseIdDetailLabelNull = [NSString stringWithFormat:@"%@_nilDetail", cellReuseId];
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    
    if(! playableSearchBarDataSourceDelegate)
        playableSearchBarDataSourceDelegate = [[PlayableDataSearchDataSource alloc] initWithTableView:self.tableView playableDataSearchDataSourceDelegate:self
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
    self.actionablePlaylistDelegate = nil;
    //self.playlistSongAdderDelegate = nil;
    self.searchBarDataSourceDelegate = nil;
    stackController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%@ dealloced!", NSStringFromClass([self class]));
}

- (instancetype)initWithPlaylisttDataSourceType:(PLAYLIST_DATA_SRC_TYPE)type
                    searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate
{
    if(self = [super init]){
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
    if([someObject isMemberOfClass:[Playlist class]])
    {
        Playlist *somePlaylist = (Playlist *)someObject;
        NSUInteger albumIndex = [self.searchResults indexOfObject:somePlaylist];
        if(albumIndex == NSNotFound)
            return nil;
        else{
            return [NSIndexPath indexPathForRow:albumIndex inSection:0];
        }
    }
    else
        return nil;
}

- (NSUInteger)tableObjectsCount
{
    return [self numObjectsInTable];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Playlist *playlist;
    if(self.displaySearchResults)
        playlist = [self.searchResults objectAtIndex:indexPath.row];
    else
        playlist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    MZTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
                                                            forIndexPath:indexPath];
    if (!cell)
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:self.cellReuseId];
    
    cell.optOutOfImageView = YES;
    cell.usesOnlyTextLabel = YES;
    cell.textLabel.text = playlist.playlistName;
    
    if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default) {
        //check if a song in this playlist is the now playing song
        //we dont care if there are duplicates of a song, as long as the song is
        //within the playlist someplace, this check (in code) can be vague...
        
        __block BOOL playlistHasNowPlaying = NO;
        NowPlaying *nowPlayingObj = [NowPlaying sharedInstance];
        PlaybackContext *playlistDetailContext = [self playlistDetailContextForPlaylist:playlist];
        
        NSSet *items = playlist.playlistItems;
        
        [items enumerateObjectsUsingBlock:^(PlaylistItem *item, BOOL *stop) {
            
            if([nowPlayingObj.playableItem isEqualToPlaylistItem:item withContext:playlistDetailContext]
               ||
               [nowPlayingObj.playableItem isEqualToPlaylistItem:item withContext:self.playbackContext])
            {
                playlistHasNowPlaying = YES;
                *stop = YES;
            }
        }];

        if(playlistHasNowPlaying) {
            cell.textLabel.textColor = [super colorForNowPlayingItem];
            cell.isRepresentingANowPlayingItem = YES;
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
            cell.isRepresentingANowPlayingItem = NO;
        }
        cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR
                                                          color:[[AppEnvironmentConstants appTheme].mainGuiTint lighterColor]];

    } else if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_AddSongToPlaylist) {
        cell.accessoryView = nil;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.isRepresentingANowPlayingItem = NO;
    }
    
    cell.delegate = self;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.displaySearchResults)
        return NO;
    
    if (self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default) {
        return YES;
    } else if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_AddSongToPlaylist) {
        return NO;
    }
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel] + 4;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //obtain object for the deleted playlist
        Playlist *playlist;
        if(self.displaySearchResults)
            playlist = [self.searchResults objectAtIndex:indexPath.row];
        else
            playlist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        CLSLog(@"User trying to delete playlist: %@ context:%@", playlist.playlistName, self.playbackContext);
        
        NSSet *items = playlist.playlistItems;
        NSMutableArray *songsBeingDeleted = [NSMutableArray array];
        [items enumerateObjectsUsingBlock:^(PlaylistItem *item, BOOL *stop) {
            [songsBeingDeleted addObject:item.song];
        }];
    
        [MusicPlaybackController groupOfSongsAboutToBeDeleted:songsBeingDeleted
                                              deletionContext:self.playbackContext];
        
        [[CoreDataManager context] deleteObject:playlist];
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
    
    Playlist *selectedPlaylist;
    if(self.displaySearchResults)
        selectedPlaylist = [self.searchResults objectAtIndex:indexPath.row];
    else
        selectedPlaylist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default) {
        [self.actionablePlaylistDelegate performPlaylistDetailVCSegueWithPlaylist:selectedPlaylist];
    } else if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_AddSongToPlaylist) {
        [self.actionablePlaylistDelegate userSelectedPlaylist:selectedPlaylist];
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
            NSAttributedString *text = [MZCommons makeAttributedString:@"No Search Results"];
            [playableSearchBarDataSourceDelegate displayEmptyTableUserMessageWithText:text];
            return 0;
        }
    }
    else
    {
        if([self numObjectsInTable] == 0){
            NSAttributedString *text = self.emptyTableUserMessage;
            [playableSearchBarDataSourceDelegate displayEmptyTableUserMessageWithText:text];
        } else {
            [playableSearchBarDataSourceDelegate removeEmptyTableUserMessage];
        }
        
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view
       forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    int headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
}

#pragma mark - efficiently updating individual cells as needed
- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification
{
    //VC's using the AllPlaylistsDataSource do NOT have a playback context. instead they
    //use the context of the specific playlist they initiate.
    PlayableItem *oldItem = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading];
    
    PlaylistItem *oldPlaylistItem = oldItem.playlistItemForItem;
    NowPlaying *nowPlaying = [NowPlaying sharedInstance];
    PlaylistItem *newPlaylistItem = nowPlaying.playableItem.playlistItemForItem;
    
    //nothing to possibly update
    if(oldPlaylistItem == nil && newPlaylistItem == nil)
        return;
    
    Playlist *oldItemPlaylist = oldPlaylistItem.playlist;
    Playlist *newItemPlaylist = newPlaylistItem.playlist;
    
    NSIndexPath *oldPath, *newPath;
    if(self.displaySearchResults){
        NSUInteger oldRow = [self.searchResults indexOfObject:oldItemPlaylist];
        if(oldRow != NSNotFound)
            oldPath = [NSIndexPath indexPathForRow:oldRow inSection:0];
        
        NSUInteger newRow = [self.searchResults indexOfObject:newPlaylistItem];
        if(newRow != NSNotFound)
            newPath = [NSIndexPath indexPathForRow:newRow inSection:0];
    }
    else{
        oldPath = [self.fetchedResultsController indexPathForObject:oldItemPlaylist];
        newPath = [self.fetchedResultsController indexPathForObject:newItemPlaylist];
    }
    
    if(oldPath || newPath){
        [self.tableView beginUpdates];
        if(oldPath)
            [self.tableView reloadRowsAtIndexPaths:@[oldPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
        if(newPath && ![newPath isEqual:oldPath])
            [self.tableView reloadRowsAtIndexPaths:@[newPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

#pragma mark - MGSwipeTableCell delegates
- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction
{
    if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default)
        return YES;
    else
        return NO;
}

- (NSArray*)swipeTableCell:(MGSwipeTableCell*)cell
  swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*)swipeSettings
         expansionSettings:(MGSwipeExpansionSettings*)expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionClipCenter;
    swipeSettings.keepButtonsSwiped = NO;
    expansionSettings.buttonIndex = 0;
    expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
    expansionSettings.threshold = 1.0;
    expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunctionCubicOut;
    expansionSettings.fillOnTrigger = NO;
    UIColor *initialExpansionColor = [MZAppTheme expandingCellGestureInitialColor];
    __weak AllPlaylistsDataSource *weakSelf = self;
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        Playlist *playlist = [self.fetchedResultsController
                              objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        expansionSettings.expansionColor = [MZAppTheme expandingCellGestureQueueItemColor];
        __weak Playlist *weakPlaylist = playlist;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:MZCellSpotifyStylePaddingValue
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MZCommons presentQueuedHUD];
                                           PlaybackContext *context = [weakSelf contextForPlaylist:weakPlaylist];
                                           [MusicPlaybackController queueSongsOnTheFlyWithContext:context];
                                           [weakCell refreshContentView];
                                           return NO;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.expansionColor = [MZAppTheme expandingCellGestureDeleteItemColor];
        MGSwipeButton *delete = [MGSwipeButton buttonWithTitle:@"Delete"
                                               backgroundColor:initialExpansionColor
                                                       padding:MZCellSpotifyStylePaddingValue
                                                      callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     NSIndexPath *indexPath;
                                     indexPath = [weakSelf.tableView indexPathForCell:sender];
                                     [weakSelf tableView:weakSelf.tableView
                                      commitEditingStyle:UITableViewCellEditingStyleDelete
                                       forRowAtIndexPath:indexPath];
                                     return NO;
                                 }];
        return @[delete];
    }
    return nil;
}



- (PlaybackContext *)contextForPlaylist:(Playlist *)aPlaylist
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaylistItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY playlist.uniqueId == %@", aPlaylist.uniqueId];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSString *playlistQueueDescription = [NSString stringWithFormat:@"\"%@\" Playlist", aPlaylist.playlistName];
    
    NSMutableString *uniquePlaylistContextID = [NSMutableString string];
    [uniquePlaylistContextID appendString:NSStringFromClass([PlaylistItemTableViewController class])];
    [uniquePlaylistContextID appendString:aPlaylist.uniqueId];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:playlistQueueDescription
                                               contextId:uniquePlaylistContextID];
}

//caution, changing this method means i HAVE TO update the same logic in the playlist detail VC.
- (PlaybackContext *)playlistDetailContextForPlaylist:(Playlist *)aPlaylist
{
    NSMutableString *playlistDetailContextId = [NSMutableString string];
    [playlistDetailContextId appendString:NSStringFromClass([PlaylistItemTableViewController class])];
    [playlistDetailContextId appendString:aPlaylist.uniqueId];
    
    PlaybackContext *playlistDetailContext = [[PlaybackContext alloc] initWithFetchRequest:nil
                                                                           prettyQueueName:@""
                                                                                 contextId:playlistDetailContextId];
    return playlistDetailContext;
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

- (MySearchBar *)setUpSearchBar
{
    return [playableSearchBarDataSourceDelegate setUpSearchBar];
}

#pragma mark - PlayableDataSearchDataSourceDelegate implementation
- (NSFetchRequest *)fetchRequestForSearchBarQuery:(NSString *)query
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:MZDefaultCoreDataFetchBatchSize];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    request.sortDescriptors = @[sortDescriptor];
    
    NSMutableString *searchWithWildcards = [NSMutableString stringWithFormat:@"*%@*", query];
    if (searchWithWildcards.length > 3){
        for (int i = 2; i < query.length * 2; i += 2)
            [searchWithWildcards insertString:@"*" atIndex:i];
    }
    
    //matches against exact string ANYWHERE within the album name
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"playlistName contains[cd] %@",  query];
    
    //matches partial string with song name as long as sequence of letters is correct.
    //see: http://stackoverflow.com/questions/15091155/nspredicate-match-any-characters
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"playlistName LIKE[cd] %@",  searchWithWildcards];
    
    request.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1,predicate2]];
    return request;
}

//also overriding superclass at the same time with this method.
- (void)searchResultsShouldBeDisplayed:(BOOL)displaySearchResults
{
    self.displaySearchResults = displaySearchResults;
}

- (void)searchResultsFromUsersQuery:(NSArray *)modelObjects
{
    self.searchResults = [NSMutableArray arrayWithArray:modelObjects];
}

- (NSUInteger)playableDataSourceEntireModelCount
{
    return [self numObjectsInTable];
}

#pragma mark - Other Helpers
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
