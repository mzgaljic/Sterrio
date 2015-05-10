//
//  ArtistItemAlbumViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ArtistItemAlbumViewController.h"

#import "MZCoreDataModelDeletionService.h"
#import "AlbumArtUtilities.h"
#import "Album.h"
#import "Song.h"
#import "MZAlbumSectionHeader.h"
#import "MusicPlaybackController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "AlbumDetailDisplayHelper.h"
#import "PlayableItem.h"
#import "PreviousNowPlayingInfo.h"

@interface ArtistItemAlbumViewController ()
{
    NSString *playbackContextUUID;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *artistsStandAloneSongs;
@property (nonatomic, strong) NSArray *artistAlbums;
@property (nonatomic, strong) PlaybackContext *playbackContext;
@end

@implementation ArtistItemAlbumViewController

const int ARTISTS_ALBUM_HEADER_HEIGHT = 120;

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //appending artist id here because we must differentiate between queing up the entire artist,
    //and queing up a specific artists song
    NSMutableString *uniqueID = [NSMutableString string];
    [uniqueID appendString:NSStringFromClass([self class])];
    [uniqueID appendString:self.artist.uniqueId];
    playbackContextUUID = uniqueID;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self fetchAndInitArtistInfo];
    
    self.tableView.allowsSelectionDuringEditing = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.title = self.artist.artistName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowPlayingSongsHasChanged:)
                                                 name:MZNewSongLoading
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@NO];
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.artistsStandAloneSongs = nil;
    self.playbackContext = nil;
    self.parentVc = nil;
    playbackContextUUID = nil;
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - Table View Data Source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section != 0)
        return ARTISTS_ALBUM_HEADER_HEIGHT;
    else if(section == 0 && self.artistsStandAloneSongs.count == 0)
        return ARTISTS_ALBUM_HEADER_HEIGHT;
    else
        return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(section == 0 && self.artistsStandAloneSongs.count > 0)
    {
        //standalone songs, no header needed.
        return nil;
    }
    else
    {
        //generate header for album in this section.
        Album *albumAtSection;
        if(self.artistsStandAloneSongs.count > 0)
            albumAtSection = self.artistAlbums[section -1];
        else
            albumAtSection = self.artistAlbums[section];
        
        return [self generateAlbumSectionHeaderViewForAlbum:albumAtSection];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *aSong;
    NSString *reuseId = @"artistDetailSongCell";
    
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId
                                                             forIndexPath:indexPath];
    
    if (!cell)
        cell = [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleValue1
                                       reuseIdentifier:reuseId];
    
    if(self.artistAlbums.count > 0
       && self.artistsStandAloneSongs.count > 0
       && indexPath.section == 0
       && indexPath.row == self.artistsStandAloneSongs.count)
    {
        //this cell represents the extra cell for padding.
        cell.hidden = YES;
        return cell;
    }
    else
        cell.hidden = NO;
    
    if(indexPath.section == 0 && self.artistsStandAloneSongs.count > 0)
    {
        aSong = self.artistsStandAloneSongs[indexPath.row];
    }
    else
    {
        Album *albumAtSection;
        if(self.artistsStandAloneSongs.count > 0)
            albumAtSection = self.artistAlbums[indexPath.section -1];
        else
            albumAtSection = self.artistAlbums[indexPath.section];

        NSArray *albumSongs = [self albumSongsInAlphabeticalOrderGivenAlbum:albumAtSection];
        aSong = albumSongs[indexPath.row];
    }
    
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                          size:fontSize];
    
    cell.textLabel.text = aSong.songName;
    
    NSUInteger duration = [aSong.duration integerValue];
    cell.detailTextLabel.text = [AlbumDetailDisplayHelper convertSecondsToPrintableNSStringWithSeconds:duration];
    cell.detailTextLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                size:fontSize];
    
    NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
    BOOL isNowPlaying = [nowPlayingObj.nowPlayingItem isEqualToSong:aSong withContext:self.playbackContext];
    if(! isNowPlaying){
        isNowPlaying = [nowPlayingObj.nowPlayingItem isEqualToSong:aSong withContext:self.parentVcPlaybackContext];
    }
    if(isNowPlaying)
        cell.textLabel.textColor = [AppEnvironmentConstants nowPlayingItemColor];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    cell.delegate = self;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        
        [self.tableView beginUpdates];
        Song *aSong;
        if(indexPath.section == 0 && self.artistsStandAloneSongs.count > 0){
            aSong = self.artistsStandAloneSongs[indexPath.row];
            if(self.artistsStandAloneSongs.count == 1){
                //will need to delete this section.
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                              withRowAnimation:UITableViewRowAnimationMiddle];
            }
            else
                [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationMiddle];
        }
        else{
            Album *albumAtSection;
            if(self.artistsStandAloneSongs.count > 0)
                albumAtSection = self.artistAlbums[indexPath.section -1];
            else
                albumAtSection = self.artistAlbums[indexPath.section];
            
            NSArray *albumSongs = [self albumSongsInAlphabeticalOrderGivenAlbum:albumAtSection];
            aSong = albumSongs[indexPath.row];
            
            if(albumAtSection.albumSongs.count == 1){
                //will have to remove section corresponding to this album
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                              withRowAnimation:UITableViewRowAnimationMiddle];
            }
            else
                [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationMiddle];
        }
        
        
        [MZCoreDataModelDeletionService prepareSongForDeletion:aSong];
        
        [[CoreDataManager context] deleteObject:aSong];
        [[CoreDataManager sharedInstance] saveContext];
        
        [self fetchAndInitArtistInfo];
        
        [self.tableView endUpdates];
        
        //parent vc tableview doesnt update song count after deletion. this fixes that.
        UITableView *parentTableview = [self.parentVc performSelector:@selector(tableView)];
        [parentTableview reloadData];
        
        if(self.artistsStandAloneSongs.count == 0 && self.artistAlbums.count == 0)
            [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Song *selectedSong;
    if(indexPath.section == 0 && self.artistsStandAloneSongs.count > 0)
        selectedSong = self.artistsStandAloneSongs[indexPath.row];
    else{
        Album *albumAtSection;
        if(self.artistsStandAloneSongs.count == 0)
            albumAtSection = self.artistAlbums[indexPath.section];
        else
            albumAtSection = self.artistAlbums[indexPath.section -1];
        
        NSArray *albumSongs = [self albumSongsInAlphabeticalOrderGivenAlbum:albumAtSection];
        selectedSong = albumSongs[indexPath.row];
    }
    
    [MusicPlaybackController newQueueWithSong:selectedSong withContext:self.playbackContext];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    if(section == 0 && self.artistsStandAloneSongs.count > 0)
    {
        int standAlongSongsCount = (int)self.artistsStandAloneSongs.count;
        if(standAlongSongsCount == 0)
            return standAlongSongsCount;
        else if(standAlongSongsCount > 0 && self.artistAlbums.count > 0)
            return standAlongSongsCount +1;  //1 extra empty row desired as padding
        else
            return standAlongSongsCount;
    }
    else
    {
        Album *albumAtSection;
        if(self.artistsStandAloneSongs.count > 0)
            albumAtSection = self.artistAlbums[section -1];
        else
            albumAtSection = self.artistAlbums[section];
        
        return albumAtSection.albumSongs.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //1 is for the standalone songs section
    int standAloneSongsSection = 0;
    if(self.artistsStandAloneSongs.count > 0)
        standAloneSongsSection = 1;
    
    int numArtistsAlbums = (int)self.artistAlbums.count;
    return standAloneSongsSection + numArtistsAlbums;
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
    __weak ArtistItemAlbumViewController *weakself = self;
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        NSIndexPath *path = [self.tableView indexPathForCell:cell];
        Song *aSong;
        if(path.section == 0 && self.artistsStandAloneSongs.count > 0){
            aSong = self.artistsStandAloneSongs[path.row];
        }
        else{
            Album *albumAtSection;
            if(self.artistsStandAloneSongs.count > 0)
                albumAtSection = self.artistAlbums[path.section -1];
            else
                albumAtSection = self.artistAlbums[path.section];
            
            NSArray *albumSongs = [self albumSongsInAlphabeticalOrderGivenAlbum:albumAtSection];
            aSong = albumSongs[path.row];
        }
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak Song *weakSong = aSong;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MZPlaybackQueue presentQueuedHUD];
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


#pragma mark - efficiently updating individual cells as needed
- (void)nowPlayingSongsHasChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:MZNewSongLoading]){
        if([NSThread isMainThread]){
            [self reflectNowPlayingChangesInTableview:notification];
        } else{
            [self performSelectorOnMainThread:@selector(reflectNowPlayingChangesInTableview:)
                                   withObject:notification
                                waitUntilDone:NO];
        }
    }
}

- (NSIndexPath *)indexPathForSong:(Song *)aSong
{
    if(self.artistsStandAloneSongs.count > 0)
    {
        NSUInteger index = [self.artistsStandAloneSongs indexOfObjectIdenticalTo:aSong];
        if(index != NSNotFound)
            return [NSIndexPath indexPathForRow:index inSection:0];
    }
    if(self.artistAlbums.count > 0)
    {
        Album *anAlbum;
        for(int i = 0; i < self.artistAlbums.count; i++)
        {
            anAlbum = self.artistAlbums[i];
            NSArray *albumSongs = [self albumSongsInAlphabeticalOrderGivenAlbum:anAlbum];
            NSUInteger index = [albumSongs indexOfObjectIdenticalTo:aSong];
            if(index != NSNotFound)
            {
                if(self.artistsStandAloneSongs.count > 0)
                    return [NSIndexPath indexPathForRow:index inSection:i +1];
                else
                    return [NSIndexPath indexPathForRow:index inSection:i];
            }
        }
    }
    return nil;
}

- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification
{
    if(self.playbackContext == nil)
        return;
    
    Song *oldSong = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading].songForItem;
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    Song *newSong = nowPlaying.nowPlayingItem.songForItem;
    NSIndexPath *oldPath, *newPath;
    
    //tries to obtain the path to the changed songs if possible.
    oldPath = [self indexPathForSong:oldSong];
    newPath = [self indexPathForSong:newSong];
    
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


#pragma mark - Utility stuff
- (UIView *)generateAlbumSectionHeaderViewForAlbum:(Album *)anAlbum
{
    if(anAlbum){
        CGRect albumHeaderFrame = CGRectMake(0,
                                             0,
                                             self.view.frame.size.width,
                                             ARTISTS_ALBUM_HEADER_HEIGHT);
        return [[MZAlbumSectionHeader alloc] initWithFrame:albumHeaderFrame
                                                     album:anAlbum];
    }
    else
        return nil;
}

- (NSArray *)albumSongsInAlphabeticalOrderGivenAlbum:(Album *)anAlbum
{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    NSMutableArray *sortMe = [NSMutableArray arrayWithArray:[anAlbum.albumSongs allObjects]];
    [sortMe sortUsingDescriptors:@[sortDescriptor]];
    return sortMe;
}

- (PlaybackContext *)contextForSpecificSong:(Song *)aSong
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", aSong.uniqueId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:playbackContextUUID];
}


#pragma mark - Fetching
- (void)fetchAndInitArtistInfo
{
    [self fetchAndSetStandAloneSongs];
    [self fetchAndSetArtistAlbums];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"self.artist.uniqueId == %@",
                               self.artist.uniqueId];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"self.album.artist.uniqueId == %@",
                               self.artist.uniqueId];
    NSArray *predicates = @[predicate1, predicate2];
    NSPredicate *allArtistSongsPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    request.predicate = allArtistSongsPredicate;
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    
    if(self.playbackContext == nil){
        NSString *queueName = [NSString stringWithFormat:@"Artist: %@", self.artist.artistName];
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:queueName
                                                                   contextId:playbackContextUUID];
    }
}

- (void)fetchAndSetStandAloneSongs
{
    //fetch and set artists standalone songs (manually fetched to avoid weird duplicate issue)
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"artist.uniqueId == %@",
                               self.artist.uniqueId];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"album = $NO_ALBUM"];
    predicate2 = [predicate2 predicateWithSubstitutionVariables:@{@"NO_ALBUM" : [NSNull null]}];
    NSArray *predicates = @[predicate1, predicate2];
    NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    request.predicate = finalPredicate;
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];

    request.sortDescriptors = @[sortDescriptor];
    //[request setFetchBatchSize:40];
    
    self.artistsStandAloneSongs = [[CoreDataManager context] executeFetchRequest:request error:nil];
}

- (void)fetchAndSetArtistAlbums
{
    //fetch all albums by this artist
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"artist.uniqueId == %@",
                               self.artist.uniqueId];
    request.predicate = predicate;
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];

    request.sortDescriptors = @[sortDescriptor];
    //[request setFetchBatchSize:10];
    
    self.artistAlbums = [[CoreDataManager context] executeFetchRequest:request error:nil];
}

@end
