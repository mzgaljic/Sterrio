//
//  AllArtistsDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AllArtistsDataSource.h"
#import "StackController.h"
#import "MZTableViewCell.h"
#import "MusicPlaybackController.h"

@interface AllArtistsDataSource ()
{
    NSString *cellReuseIdDetailLabelNull;
    PlayableDataSearchDataSource *playableSearchBarDataSourceDelegate;
}
@property (nonatomic, assign, readwrite) ARTIST_DATA_SRC_TYPE dataSourceType;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) Artist *selectedArtist;  //for artist picker VC's

//@property (nonatomic, strong) NSMutableArray *selectedSongIds;
//@property (nonatomic, strong) NSOrderedSet *existingPlaylistSongs;

@end
@implementation AllArtistsDataSource

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
    self.actionableArtistDelegate = nil;
    //self.playlistSongAdderDelegate = nil;
    self.searchBarDataSourceDelegate = nil;
    
    //self.selectedSongIds = nil;
    //self.existingPlaylistSongs = nil;
    NSLog(@"%@ dealloced!", NSStringFromClass([self class]));
}

- (instancetype)initWithArtistDataSourceType:(ARTIST_DATA_SRC_TYPE)type
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;
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

- (instancetype)initWithArtistDataSourceType:(ARTIST_DATA_SRC_TYPE)type
                             selectedArtist:(Artist *)anArtist
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate
{
    if(self = [super init]){
        self.selectedArtist = anArtist;
        stackController = [[StackController alloc] init];
        self.dataSourceType = type;
        self.searchBarDataSourceDelegate = delegate;
    }
    return self;
}


#pragma mark - Overriding functionality
- (void)clearSearchResultsDataSource
{
    self.searchResults = [NSArray array];
    [self.tableView reloadData];
}

- (NSIndexPath *)indexPathInSearchTableForObject:(id)someObject
{
    if([someObject isMemberOfClass:[Album class]])
    {
        Artist *someArtist = (Artist *)someObject;
        NSUInteger albumIndex = [self.searchResults indexOfObject:someArtist];
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
    Artist *artist;
    if(self.displaySearchResults)
        artist = [self.searchResults objectAtIndex:indexPath.row];
    else
        artist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    MZTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
                                                            forIndexPath:indexPath];
    if (!cell)
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:self.cellReuseId];
    
    if(self.dataSourceType == ARTIST_DATA_SRC_TYPE_Default)
    {
        //check if artist is now playing context, if so make cell changes here...
        
    }
    else if(self.dataSourceType == ARTIST_DATA_SRC_TYPE_Single_Artist_Picker)
    {
        BOOL isCurrentlySelectedArtist = [self.selectedArtist.artistName isEqualToString:artist.artist_id];
        
        if(isCurrentlySelectedArtist){
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

    UIColor *appTheme = [[UIColor defaultAppColorScheme] lighterColor];
    short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
    MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                               color:appTheme];
    
    cell.editingAccessoryView = coloredDisclosureIndicator;
    cell.accessoryView = coloredDisclosureIndicator;
    cell.textLabel.attributedText = [ArtistTableViewFormatter formatArtistLabelUsingArtist:artist];
    cell.detailTextLabel.text = [self stringForArtistDetailLabelGivenArtist:artist];
    cell.delegate = self;
    
    #warning NOT setting artist textlabel color based on whether or not a song from this artist is playing (in same context)!
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.displaySearchResults)
        return NO;
    
    if(self.dataSourceType == ARTIST_DATA_SRC_TYPE_Single_Artist_Picker)
        return NO;
    else if (self.dataSourceType == ARTIST_DATA_SRC_TYPE_Default)
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
        Artist *artist = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        //remove songs from queue
        for(Song *aSong in artist.standAloneSongs)
        {
            [MusicPlaybackController songAboutToBeDeleted:aSong
                                          deletionContext:self.playbackContext];
            aSong.albumArt = nil;
        }
        for(Album *anAlbum in artist.albums)
        {
            for(Song *aSong in anAlbum.albumSongs)
                [MusicPlaybackController songAboutToBeDeleted:aSong
                                              deletionContext:self.playbackContext];
            anAlbum.albumArt = nil;
        }
        
        //delete the artist and save changes
        [[CoreDataManager context] deleteObject:artist];
        [[CoreDataManager sharedInstance] saveContext];
        
        if([self numObjectsInTable] == 0){ //dont need search bar anymore
            self.tableView.tableHeaderView = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Artist *tappedArtist;
    if(self.displaySearchResults)
        tappedArtist = [self.searchResults objectAtIndex:indexPath.row];
    else
        tappedArtist = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if(self.dataSourceType == ARTIST_DATA_SRC_TYPE_Default)
    {
        if(tableView.editing)
            [self.actionableArtistDelegate performEditSegueWithArtist:tappedArtist];
        else
            [self.actionableArtistDelegate performArtistDetailVCSegueWithArtist:tappedArtist];
    }
    else if(self.dataSourceType == ARTIST_DATA_SRC_TYPE_Single_Artist_Picker)
    {
        [self.actionableArtistDelegate userDidSelectArtistFromSinglePicker:tappedArtist];
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
    int headerFontSize;
    if([AppEnvironmentConstants preferredSizeSetting] < 5)
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    else
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:5];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
}

#pragma mark - MGSwipeTableCell delegates
- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction
{
    if(self.dataSourceType == ARTIST_DATA_SRC_TYPE_Default)
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
    __weak AllArtistsDataSource *weakSelf = self;
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        Artist *artist = [self.fetchedResultsController
                          objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak Artist *weakArtist = artist;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           NSLog(@"Queing up: %@", weakArtist.artistName);
                                           
                                           PlaybackContext *context = [weakSelf contextForSpecificArtist:weakArtist];
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

- (PlaybackContext *)contextForSpecificArtist:(Artist *)anArtist
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY artist.artist_id == %@", anArtist.artist_id];
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:50];
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
    
    NSMutableString *searchWithWildcards = [NSMutableString stringWithFormat:@"*%@*", query];
    if (searchWithWildcards.length > 3){
        for (int i = 2; i < query.length * 2; i += 2)
            [searchWithWildcards insertString:@"*" atIndex:i];
    }
    
    //matches against exact string ANYWHERE within the album name
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"artistName contains[cd] %@",  query];
    
    //matches partial string with song name as long as sequence of letters is correct.
    //see: http://stackoverflow.com/questions/15091155/nspredicate-match-any-characters
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"artistName LIKE[cd] %@",  searchWithWildcards];
    
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
    self.searchResults = modelObjects;
}

- (NSUInteger)playableDataSourceEntireModelCount
{
    return [self numObjectsInTable];
}


#pragma mark - Other Helpers
- (NSString *)stringForArtistDetailLabelGivenArtist:(Artist *)artist
{
    //count all the songs that are associated with albums for this artist
    NSMutableSet *allAlbumSongsFromArtist = [[NSMutableSet alloc] initWithCapacity:6];
    for(Album *artistAlbum in artist.albums)
    {
        NSSet *albumSongs = artistAlbum.albumSongs;
        NSSet *tempNewSet = [allAlbumSongsFromArtist setByAddingObjectsFromSet:albumSongs];
        allAlbumSongsFromArtist = [NSMutableSet setWithSet:tempNewSet];
    }
    NSSet *albumSongs = artist.standAloneSongs;
    NSSet *uniqueSongsByThisArtist = [allAlbumSongsFromArtist setByAddingObjectsFromSet:albumSongs];
    
    NSString *albumPart, *songPart;
    if((int)artist.albums.count == 1)
        albumPart = @"1 Album";
    else
        albumPart = [NSString stringWithFormat:@"%d Albums", (int)artist.albums.count];
    
    NSUInteger totalSongCount = uniqueSongsByThisArtist.count;
    if(totalSongCount == 1)
        songPart = @"1 Song ";
    else
        songPart = [NSString stringWithFormat:@"%d Songs", (int)totalSongCount];
    
    NSMutableString *finalDetailLabel = [NSMutableString stringWithString:albumPart];
    [finalDetailLabel appendString:@" "];
    [finalDetailLabel appendString:songPart];
    return finalDetailLabel;
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
