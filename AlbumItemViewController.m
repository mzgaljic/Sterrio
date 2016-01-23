//
//  AlbumItemViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumItemViewController.h"

#import "MZCoreDataModelDeletionService.h"
#import "AlbumArtUtilities.h"
#import "AlbumAlbumArt.h"
#import "Album.h"
#import "Song.h"
#import "MZAlbumSectionHeader.h"
#import "MusicPlaybackController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "AlbumDetailDisplayHelper.h"
#import "PlayableItem.h"
#import "PreviousNowPlayingInfo.h"

@interface AlbumItemViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation AlbumItemViewController
const int ALBUM_HEADER_HEIGHT = 120;

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //apending album id here because we must differentiate between queing up the entire album,
    //and queing up a specific album song
    NSMutableString *uniqueID = [NSMutableString string];
    [uniqueID appendString:NSStringFromClass([self class])];
    [uniqueID appendString:self.album.uniqueId];
    self.playbackContextUniqueId = uniqueID;
    self.emptyTableUserMessage = @"Album Empty";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setTableForCoreDataView:self.tableView];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.cellReuseId = @"albumSongCell";
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
    
    self.tableView.allowsSelectionDuringEditing = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.navBar.title = nil;
    [self generateAlbumSectionHeaderView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowPlayingSongsHasChanged:)
                                                 name:MZNewSongLoading
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@NO];
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - Table View Data Source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
        return ALBUM_HEADER_HEIGHT;
    else
        return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(section == 0){
        if(self.album.albumSongs.count > 0)
            return [self generateAlbumSectionHeaderView];
        else
            return nil;
    } else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *aSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
                                                             forIndexPath:indexPath];
    
    if (!cell)
        cell = [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:self.cellReuseId];
    cell.textLabel.text = aSong.songName;
    
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                          size:fontSize];
    
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
        //obtain object for the deleted song
        Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
        Album *songsAlbum = song.album;
        
        [MusicPlaybackController songAboutToBeDeleted:song deletionContext:self.playbackContext];
        [MZCoreDataModelDeletionService prepareSongForDeletion:song];
        
        [[CoreDataManager context] deleteObject:song];
        [[CoreDataManager sharedInstance] saveContext];
        
        if(songsAlbum == nil || songsAlbum.albumSongs.count == 0){
            [self.navigationController popViewControllerAnimated:YES];
        }
        songsAlbum.albumArt.isDirty = @YES;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation: UITableViewRowAnimationAutomatic];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Song *selectedSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [MusicPlaybackController newQueueWithSong:selectedSong withContext:self.playbackContext];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (NSInteger)tableView:(UITableView *)table
 numberOfRowsInSection:(NSInteger)section
{
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
        Song *aSong = [self.fetchedResultsController
                        objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak AlbumItemViewController *weakself = self;
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
        
        __weak AlbumItemViewController *weakSelf = self;
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

- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification
{
    if(self.playbackContext == nil)
        return;
    Song *oldSong = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading].songForItem;
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    Song *newSong = nowPlaying.nowPlayingItem.songForItem;
    NSIndexPath *oldPath, *newPath;
    
    //tries to obtain the path to the changed songs if possible.
    oldPath = [self.fetchedResultsController indexPathForObject:oldSong];
    newPath = [self.fetchedResultsController indexPathForObject:newSong];
    
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

#pragma mark - Helpers
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
                                               contextId:self.playbackContextUniqueId];
}

- (UIView *)generateAlbumSectionHeaderView
{
    if(self.album){
        CGRect albumHeaderFrame = CGRectMake(0, 0, self.view.frame.size.width, ALBUM_HEADER_HEIGHT);
        return [[MZAlbumSectionHeader alloc] initWithFrame:albumHeaderFrame
                                                     album:self.album];
    }
    else
        return nil;
}

#pragma mark - fetching and sorting
- (void)setFetchedResultsControllerAndSortStyle
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    NSPredicate *albumPredicate = [NSPredicate predicateWithFormat:@"album.uniqueId == %@", self.album.uniqueId];
    request.predicate = albumPredicate;
    [request setFetchBatchSize:MZDefaultCoreDataFetchBatchSize];
    [request setPropertiesToFetch:@[@"songName", @"duration"]];

    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    if(self.playbackContext == nil){
        NSString *queueName = [NSString stringWithFormat:@"\"%@\" Album", self.album.albumName];
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:queueName
                                                                   contextId:self.playbackContextUniqueId];
    }
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end