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
#import "PreviousPlaybackContext.h"

@interface AllPlaylistsDataSource ()
{
    NSString *cellReuseIdDetailLabelNull;
    PlayableDataSearchDataSource *playableSearchBarDataSourceDelegate;
}
@property (nonatomic, assign, readwrite) PLAYLIST_DATA_SRC_TYPE dataSourceType;
@property (nonatomic, strong) NSMutableArray *searchResults;

//@property (nonatomic, strong) NSMutableArray *selectedSongIds;
//@property (nonatomic, strong) NSOrderedSet *existingPlaylistSongs;
@end
@implementation AllPlaylistsDataSource

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
    
    //self.selectedSongIds = nil;
    //self.existingPlaylistSongs = nil;
    NSLog(@"%@ dealloced!", NSStringFromClass([self class]));
}

- (instancetype)initWithPlaylisttDataSourceType:(PLAYLIST_DATA_SRC_TYPE)type
                    searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate
{
    if(self = [super init]){
        stackController = [[StackController alloc] init];
        self.dataSourceType = type;
        self.searchBarDataSourceDelegate = delegate;
        //if(type == SONG_DATA_SRC_TYPE_Playlist_MultiSelect)
        //    self.selectedSongIds = [NSMutableArray array];
    }
    return self;
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
    cell.textLabel.text = playlist.playlistName;
    
    if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default)
    {
        //check if a song in this playlist is the now playing song
        BOOL playlistHasNowPlaying = NO;
        NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
        PlaybackContext *playlistDetailContext = [self playlistDetailContextForPlaylist:playlist];
        
        for(Song *playlistSong in playlist.playlistSongs)
        {
            //need to check both the general playlist context and the playlistDetailVC context.
            //...since an entire playlist or just a specific playlist can be queued up.
            if([nowPlayingObj isEqualToSong:playlistSong compareWithContext:self.playbackContext]
               ||
               [nowPlayingObj isEqualToSong:playlistSong compareWithContext:playlistDetailContext])
            {
                playlistHasNowPlaying = YES;
                break;
            }
        }

        if(playlistHasNowPlaying)
            cell.textLabel.textColor = [super colorForNowPlayingItem];
        else
            cell.textLabel.textColor = [UIColor blackColor];
        cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR
                                                          color:[[UIColor defaultAppColorScheme] lighterColor]];

    }
    
    cell.delegate = self;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.displaySearchResults)
        return NO;
    
    if (self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default)
        return YES;
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        Playlist *playlist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        [MusicPlaybackController groupOfSongsAboutToBeDeleted:[playlist.playlistSongs array]
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
    
    if(self.dataSourceType == PLAYLIST_DATA_SRC_TYPE_Default)
    {
        [self.actionablePlaylistDelegate performPlaylistDetailVCSegueWithPlaylist:selectedPlaylist];
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view
       forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    int headerFontSize;
    if([AppEnvironmentConstants preferredSizeSetting] < 5)
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    else
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:5];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
}

#pragma mark - efficiently updating individual cells as needed
- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification
{
    //VC's using the AllPlaylistsDataSource do NOT have a playback context. instead they
    //use the context of the specific playlist they initiate.
    
    Song *oldsong = (Song *)[notification object];
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    Song *newSong = nowPlaying.nowPlaying;
    PlaybackContext *oldSongPlaybackContext = [PreviousPlaybackContext contextBeforeNewSongBeganLoading];
    PlaybackContext *newSongPlaybackContext = nowPlaying.context;
    
    NSSet *playlistsOldSongIsIn = oldsong.playlistIAmIn;
    NSSet *playlistsNewSongIsIn = newSong.playlistIAmIn;
    
    //nothing to possibly update
    if(playlistsOldSongIsIn.count == 0
       && playlistsNewSongIsIn.count == 0)
        return;
    
    NSIndexPath *oldPath, *newPath;
    NSArray *visibleCells = [self.tableView visibleCells];
    for(UITableViewCell *aVisibeCell in visibleCells)
    {
        Playlist *aPlaylist;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:aVisibeCell];
        if(self.displaySearchResults)
            aPlaylist = [self.searchResults objectAtIndex:indexPath.row];
        else
            aPlaylist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        PlaybackContext *playlistDetailContext = [self playlistDetailContextForPlaylist:aPlaylist];
        
        //check if this playlist is in the old songs playlists (compare by playlist_id)
        BOOL oldSongPartOfThisPlaylist = [[playlistsOldSongIsIn valueForKey:@"playlist_id"]
                                          containsObject:aPlaylist.playlist_id];
        BOOL newSongPartOfThisPlaylist = [[playlistsNewSongIsIn valueForKey:@"playlist_id"]
                                          containsObject:aPlaylist.playlist_id];
        
        if(oldSongPartOfThisPlaylist)
        {
            if([playlistDetailContext isEqualToContext:oldSongPlaybackContext])
            {
                //old song was playing in this EXACT playlist, out of all the playlists its a part of.
                oldPath = indexPath;
            }
        }
        if(newSongPartOfThisPlaylist)
        {
            if([playlistDetailContext isEqualToContext:newSongPlaybackContext])
            {
                //new song is playing in this EXACT playlist, out of all the playlists its a part of.
                newPath = indexPath;
            }
        }
    }
    
    if(oldPath || newPath){
        [self.tableView beginUpdates];
        if(oldPath)
            [self.tableView reloadRowsAtIndexPaths:@[oldPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
        if(newPath != nil && ![newPath isEqual:newPath])
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
    swipeSettings.transition = MGSwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    UIColor *initialExpansionColor = [AppEnvironmentConstants expandingCellGestureInitialColor];
    __weak AllPlaylistsDataSource *weakSelf = self;
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        Playlist *playlist = [self.fetchedResultsController
                              objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak Playlist *weakPlaylist = playlist;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           NSLog(@"Queing up: %@", weakPlaylist.playlistName);
                                           PlaybackContext *context = [weakSelf contextForPlaylist:weakPlaylist];
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



- (PlaybackContext *)contextForPlaylist:(Playlist *)aPlaylist
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY playlistIAmIn.playlist_id == %@", aPlaylist.playlist_id];
    
    //picked playlistIAmIn because its a useless value...need that so the results of the
    //nsorderedset dont get re-ordered
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistIAmIn"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSString *playlistQueueDescription = [NSString stringWithFormat:@"\"%@\" Playlist", aPlaylist.playlistName];
    
    NSMutableString *uniquePlaylistContextID = [NSMutableString string];
    [uniquePlaylistContextID appendString:NSStringFromClass([PlaylistItemTableViewController class])];
    [uniquePlaylistContextID appendString:aPlaylist.playlist_id];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:playlistQueueDescription
                                               contextId:uniquePlaylistContextID];
}

- (PlaybackContext *)playlistDetailContextForPlaylist:(Playlist *)aPlaylist
{
    NSMutableString *playlistDetailContextId = [NSMutableString string];
    [playlistDetailContextId appendString:NSStringFromClass([PlaylistItemTableViewController class])];
    [playlistDetailContextId appendString:aPlaylist.playlist_id];
    
    PlaybackContext *playlistDetailContext = [[PlaybackContext alloc] initWithFetchRequest:nil
                                                                           prettyQueueName:@""
                                                                                 contextId:playlistDetailContextId];
    return playlistDetailContext;
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
    [request setFetchBatchSize:50];
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
