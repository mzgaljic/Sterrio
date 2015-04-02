//
//  AlbumItemViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumItemViewController.h"

@interface AlbumItemViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIView *albumHeader;
@end

@implementation AlbumItemViewController
const int ALBUM_HEADER_HEIGHT = 120;

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    //this works better than a unique random id since this class can be dealloced and re-alloced
    //later. Id must stay the same across all allocations.  :)
    NSMutableString *uniqueID = [NSMutableString string];
    [uniqueID appendString:NSStringFromClass([self class])];
    [uniqueID appendString:self.album.album_id];
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
}

- (void)dealloc
{
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
            return self.albumHeader;
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
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:self.cellReuseId];
    cell.textLabel.text = aSong.songName;
    
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                          size:fontSize];
    
    NSUInteger duration = [aSong.duration integerValue];
    cell.detailTextLabel.text = [self convertSecondsToPrintableNSStringWithSeconds:duration];
    cell.detailTextLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                size:fontSize];
    
    NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
    BOOL isNowPlaying = [nowPlayingObj isEqualToSong:aSong
                                                    compareWithContext:self.playbackContext];
    if(! isNowPlaying){
        isNowPlaying = [nowPlayingObj isEqualToSong:aSong
                                 compareWithContext:self.parentVcPlaybackContext];
    }
    if(isNowPlaying)
        cell.textLabel.textColor = [super colorForNowPlayingItem];
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
        [MusicPlaybackController songAboutToBeDeleted:song deletionContext:self.playbackContext];
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
        
        /*
        //this is for deleting the song from this album. not useful here.
        Song *deletedSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [MusicPlaybackController songAboutToBeDeleted:deletedSong
                                      deletionContext:self.playbackContext];
        
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:self.album.albumSongs];
        [mutableSet removeObject:deletedSong];
        self.album.albumSongs = mutableSet;
        [[CoreDataManager sharedInstance] saveContext];
         */
        
        [self generateAlbumSectionHeaderView];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
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
    //artist cells have a similar size to what is desired here (text only cells)
    return [ArtistTableViewFormatter preferredArtistCellHeight];
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
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           NSLog(@"Queing up: %@", aSong.songName);
                                           
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


#pragma mark - Helpers
- (NSString *)convertSecondsToPrintableNSStringWithSeconds:(NSUInteger)value
{
    NSString *secondsToStringReturn;
    
    NSUInteger totalSeconds = value;
    int seconds = (int)(totalSeconds % MZSecondsInAMinute);
    NSUInteger totalMinutes = totalSeconds / MZSecondsInAMinute;
    int minutes = (int)(totalMinutes % MZMinutesInAnHour);
    int hours = (int)(totalMinutes / MZMinutesInAnHour);
    
    if(minutes < 10 && hours == 0)  //we can shorten the text
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
    else if(hours > 0)
    {
        if(hours <= 9)
            secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d:%02d",hours,minutes,seconds];
        else
            secondsToStringReturn = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes, seconds];
    }
    else
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    return secondsToStringReturn;
}

- (PlaybackContext *)contextForSpecificSong:(Song *)aSong
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY song_id == %@", aSong.song_id];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContextUniqueId];
}

- (void)generateAlbumSectionHeaderView
{
    if(self.album){
        CGRect albumHeaderFrame = CGRectMake(0, 0, self.view.frame.size.width, ALBUM_HEADER_HEIGHT);
        self.albumHeader = [[MZAlbumSectionHeader alloc] initWithFrame:albumHeaderFrame
                                                                 album:self.album];
    }
}

#pragma mark - fetching and sorting
- (void)setFetchedResultsControllerAndSortStyle
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    NSPredicate *albumPredicate = [NSPredicate predicateWithFormat:@"ANY album.album_id == %@", self.album.album_id];
    request.predicate = albumPredicate;
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                                     ascending:YES];
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