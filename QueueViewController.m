//
//  QueueViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "QueueViewController.h"
#import "MZTableViewCell.h"
#import "SongAlbumArt+Utilities.h"
#import "PlayableItem.h"
#import "PlaylistItem.h"
#import "AllSongsDataSource.h"
#import "MZNewPlaybackQueue.h"

@interface QueueViewController ()
{
    UIView *cellBackgroundBlurView;
    UIView *sectionHeaderBackgroundBlurView;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MZPlaybackQueueSnapshot *snapshot;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) NSMutableDictionary *cachedBlurViewsSectionDict;
@property (nonatomic, assign) BOOL didLoadNewSongByTappingInQueue;
@end

@implementation QueueViewController : UIViewController
short const TABLE_SECTION_FOOTER_HEIGHT = 25;

#pragma mark - View Controller life cycle
- (id)initWithPlaybackQueueSnapshot:(MZPlaybackQueueSnapshot *)snapshot
{
    if(self = [super init]) {
        _snapshot = snapshot;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    stackController = [[StackController alloc] init];
    _cachedBlurViewsSectionDict = [NSMutableDictionary new];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewSongLoading)
                                                 name:MZNewSongLoading
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUpCustomNavBar];
    
    if(self.tableView == nil) {
        int y = [AppEnvironmentConstants navBarHeight] + [AppEnvironmentConstants statusBarHeight];
        int navBarHeight = [AppEnvironmentConstants navBarHeight];
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       y,
                                                                       self.view.frame.size.width,
                                                                       self.view.frame.size.height - navBarHeight)];
        self.tableView.backgroundColor = [UIColor clearColor];
        [self.tableView setSeparatorColor:[UIColor whiteColor]];
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:self.tableView];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

//FYI: another class assumes this method exists so don't delete this method.
- (void)preDealloc
{
    _tableView.delegate = nil;
    _tableView = nil;
    _snapshot = nil;
    _navBar = nil;
    cellBackgroundBlurView = nil;
    sectionHeaderBackgroundBlurView = nil;
    stackController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - Custom Nav Bar
- (void)setUpCustomNavBar
{
    int y = [AppEnvironmentConstants statusBarHeight];
    int vcWidth = self.view.frame.size.width;
    int navBarHeight = [AppEnvironmentConstants navBarHeight];
    _navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, y, vcWidth, navBarHeight)];
    
    //this VC has a very dark theme, make nav bar buttons and text white.
    _navBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    _navBar.tintColor = [UIColor whiteColor];
    [self.view addSubview:_navBar];
    
    //make nav bar transparent, let blurred one show through.
    [_navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    _navBar.shadowImage = [UIImage new];
    _navBar.translucent = YES;
    self.view.backgroundColor = [UIColor clearColor];
    _navBar.backgroundColor = [UIColor clearColor];
    
    UIImage *arrowDownImg = [UIImage imageNamed:@"UIButtonBarArrowDown"];
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithImage:arrowDownImg
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(dismissQueueTapped)];
    
    UINavigationItem *navigItem = [[UINavigationItem alloc] initWithTitle:@"Playback Queue"];
    navigItem.leftBarButtonItem = closeBtn;
    _navBar.items = @[navigItem];
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SongQueueItemCell";
    MZTableViewCell *cell = (MZTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor]
                                             width:cell.frame.size.height
                                            height:cell.frame.size.height];
    cell.displayQueueSongsMode = YES;
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    //make the selection style blurred
    if(cellBackgroundBlurView == nil){
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        cellBackgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        cellBackgroundBlurView.frame = cell.contentView.bounds;
    }
    [cell setSelectedBackgroundView:cellBackgroundBlurView];

    // Set up other aspects of the cell content.
    PlayableItem *item = [self itemForIndexPath:indexPath];
    Song *song = item.songForItem;
    
    //init cell fields
    cell.textLabel.text = song.songName;
    cell.detailTextLabel.text = [AllSongsDataSource generateLabelStringForSong:song];
    
    if(indexPath.section == [QueueViewController nowplayingSectionNumber:_snapshot]) {
        cell.textLabel.textColor = [[[AppEnvironmentConstants appTheme].mainGuiTint lighterColor] lighterColor];
        cell.isRepresentingANowPlayingItem = YES;
    } else {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.isRepresentingANowPlayingItem = NO;
    }
    
    cell.isRepresentingAQueuedSong = [self isUpNextSongPresentAtIndexPath:indexPath];
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &songIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    __weak Song *weaksong = song;
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        __block UIImage *albumArt;
        if(weaksong){
            NSString *artObjId = weaksong.albumArt.uniqueId;
            if(artObjId){
                
                //this is a background queue. get the object (image blob) on background context!
                NSManagedObjectContext *context = [CoreDataManager stackControllerThreadContext];
                [context performBlockAndWait:^{
                    albumArt = [weaksong.albumArt imageFromImageData];
                }];
                
                if(albumArt == nil) {
                    albumArt = [UIImage imageNamed:@"Sample Album Art"];
                }
            }
        }
        
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                [UIView transitionWithView:cell.imageView
                                  duration:MZCellImageViewFadeDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = albumArt;
                                } completion:nil];
            }
        });
    }];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == [QueueViewController historyItemsSectionNumber:_snapshot]) {
        return @"History";
    } else if(section == [QueueViewController nowplayingSectionNumber:_snapshot]) {
        return @"";
    } else if(section == [QueueViewController upNextItemsSectionNumber:_snapshot]) {
        return ([_snapshot upNextQueuedItemsRange].location != NSNotFound) ? @"Up Next" : @"";
    } else if(section == [QueueViewController futureItemsSectionNumber:_snapshot]) {
        return ([_snapshot upNextQueuedItemsRange].location == NSNotFound) ? @"Up Next" : @"";
    }
    NSLog(@"Missing if statement for 'titleForHeaderInSection' method. Section value: %li.", (long)section);
    @throw NSInternalInconsistencyException;
}

//setting section header background and text color
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view
       forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    header.textLabel.backgroundColor = [UIColor clearColor];
    int headerFontSize;
    if([AppEnvironmentConstants preferredSongCellHeight]
       < [AppEnvironmentConstants maximumSongCellHeight] - 18) {
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    } else {
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:[AppEnvironmentConstants maximumSongCellHeight] - 18];
    }
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
    CGRect oldFrame = header.textLabel.frame;
    header.textLabel.frame = CGRectMake(oldFrame.origin.x + 10,
                                        oldFrame.origin.y,
                                        oldFrame.size.width - 10,
                                        oldFrame.size.height);

    NSNumber *key = [NSNumber numberWithInteger:section];
    UIView *blurView = _cachedBlurViewsSectionDict[key];
    if(blurView == nil) {
        //make background clear, place blur view across the entire header (execpt the uilabel)
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        blurView.frame = view.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        //1st time setting up this tableview section header. Lets cache blurView for performance.
        //(so we don't need to recreate it each time user scrolls into new section.)
        _cachedBlurViewsSectionDict[key] = blurView;
    }
    view.tintColor = [UIColor clearColor];
    //don't want duplicates in the view tree - bad for performance!
    if(blurView.superview != nil) {
        [blurView removeFromSuperview];
    }
    [view addSubview:blurView];
    [view sendSubviewToBack:blurView];
    [view bringSubviewToFront:header.textLabel];
}

//setting footer header background (using footer view to pad between sections in this case)
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view
       forSection:(NSInteger)section
{
    view.tintColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    BOOL futureItemsExist = [_snapshot futureItemsRange].location != NSNotFound;
    if(section == [QueueViewController upNextItemsSectionNumber:_snapshot] && futureItemsExist) {
        return 0;
    }
    return TABLE_SECTION_FOOTER_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSUInteger sectionCount = 0;
    sectionCount += ([QueueViewController historyItemsSectionNumber:_snapshot] == NSNotFound) ? 0 : 1;
    sectionCount += ([QueueViewController nowplayingSectionNumber:_snapshot] == NSNotFound) ? 0 : 1;
    sectionCount += ([QueueViewController upNextItemsSectionNumber:_snapshot] == NSNotFound) ? 0 : 1;
    sectionCount += ([QueueViewController futureItemsSectionNumber:_snapshot] == NSNotFound) ? 0 : 1;
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self itemArrayForSection:section].count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel] * 1.2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger nowPlayingSectionNumber = [QueueViewController nowplayingSectionNumber:_snapshot];
    if(indexPath.section == nowPlayingSectionNumber) {
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
        [MusicPlaybackController resumePlayback];
    } else {
        _didLoadNewSongByTappingInQueue = YES;
        @try {
            PlayableItem *tappedItem = [self itemForIndexPath:indexPath];
            NSUInteger indexesToMove = 0;
            indexesToMove += indexPath.row + 1;
            PlayableItem *oldItem = [[NowPlaying sharedInstance] playableItem];
            PlayableItem *item = [[MZNewPlaybackQueue sharedInstance] seekBy:indexesToMove
                                                                 inDirection:SeekForward];
            if(![tappedItem isEqualToItem:item]) {
                [MyAlerts displayAlertWithAlertType:ALERT_TYPE_Issue_Tapping_Song_InQueue];
            }
            [[NowPlaying sharedInstance] setNewPlayableItem:item];
            [VideoPlayerWrapper startPlaybackOfItem:item
                                       goingForward:YES
                                    oldPlayableItem:oldItem];
            
            MZPlaybackQueueSnapshot *oldSnapshot = _snapshot;
            [oldSnapshot prepareForDeletion];
            _snapshot = [[MZNewPlaybackQueue sharedInstance] snapshotOfPlaybackQueue];
            //figure out which sections will cease to exist...
            NSIndexSet *sectionsToDelete = [QueueViewController sectionsToDeleteByComparing:oldSnapshot
                                                                              toNewSnapshot:_snapshot];
            
            NSMutableIndexSet *sectionsToUpdate = [NSMutableIndexSet indexSetWithIndex:indexPath.section];
            //just in case the new model makes the tapped section cease to exist...
            [sectionsToUpdate removeIndexes:sectionsToDelete];
            
            //now update the UI
            [self.tableView beginUpdates];
            NSIndexPath *nowPlayingPath = [NSIndexPath indexPathForRow:0 inSection:nowPlayingSectionNumber];
            [self.tableView reloadRowsAtIndexPaths:@[nowPlayingPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView deleteSections:sectionsToDelete
                          withRowAnimation:UITableViewRowAnimationBottom];
            [self.tableView reloadSections:sectionsToUpdate
                          withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } @catch (NSException *exception) {
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_Issue_Tapping_Song_InQueue];
        }
        _didLoadNewSongByTappingInQueue = NO;
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Tableview datasource helper
- (PlayableItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
    return [[self itemArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSArray *)itemArrayForSection:(NSUInteger)section
{
    NSUInteger historyItemsSection = [QueueViewController historyItemsSectionNumber:_snapshot];
    NSUInteger nowPlayingSection = [QueueViewController nowplayingSectionNumber:_snapshot];
    NSUInteger upNextSectionNumber = [QueueViewController upNextItemsSectionNumber:_snapshot];
    NSUInteger futureItemsSectionNumber = [QueueViewController futureItemsSectionNumber:_snapshot];
    if(section == historyItemsSection) {
        return _snapshot.historySongs;
    } else if(section == nowPlayingSection) {
        PlayableItem *item = [[NowPlaying sharedInstance] playableItem];
        return (item == nil) ? @[] : @[item];
    } else if(section == upNextSectionNumber) {
        return _snapshot.upNextQueuedSongs;
    } else if(section == futureItemsSectionNumber) {
        return _snapshot.futureSongs;
    } else {
        NSLog(@"if statement is missing a case.");
        @throw NSInternalInconsistencyException;
    }
}

- (BOOL)isUpNextSongPresentAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger upNextSectionNumber = [QueueViewController upNextItemsSectionNumber:_snapshot];
    return indexPath.section == upNextSectionNumber;
}

- (void)handleNewSongLoading
{
    if(_didLoadNewSongByTappingInQueue == YES) {
        return;
    }
    MZPlaybackQueueSnapshot *oldSnapshot = _snapshot;
    [oldSnapshot prepareForDeletion];
    _snapshot = [[MZNewPlaybackQueue sharedInstance] snapshotOfPlaybackQueue];
    //figure out which sections will cease to exist...
    NSIndexSet *sectionsToDelete = [QueueViewController sectionsToDeleteByComparing:oldSnapshot
                                                                      toNewSnapshot:_snapshot];
    NSUInteger nowPlayingSectionNumber = [QueueViewController nowplayingSectionNumber:oldSnapshot];
    NSUInteger historyItemsSectionNumber = [QueueViewController historyItemsSectionNumber:oldSnapshot];
    NSUInteger upNextItemsSectionNumber = [QueueViewController upNextItemsSectionNumber:oldSnapshot];
    NSUInteger futureItemsSectionNumber = [QueueViewController futureItemsSectionNumber:oldSnapshot];
    NSMutableIndexSet *sectionsToUpdate = [NSMutableIndexSet new];
    if(historyItemsSectionNumber != NSNotFound) {
        [sectionsToUpdate addIndex:historyItemsSectionNumber];
    }
    if(nowPlayingSectionNumber != NSNotFound) {
        [sectionsToUpdate addIndex:nowPlayingSectionNumber];
    }
    if(upNextItemsSectionNumber != NSNotFound) {
        [sectionsToUpdate addIndex:upNextItemsSectionNumber];
    }
    if(futureItemsSectionNumber != NSNotFound) {
        [sectionsToUpdate addIndex:futureItemsSectionNumber];
    }
    //just in case the new model makes the tapped section cease to exist...
    [sectionsToUpdate removeIndexes:sectionsToDelete];
    
    //now update the UI
    [self.tableView beginUpdates];
    if(nowPlayingSectionNumber != NSNotFound && ![sectionsToDelete containsIndex:nowPlayingSectionNumber]) {
        NSIndexPath *nowPlayingPath = [NSIndexPath indexPathForRow:0 inSection:nowPlayingSectionNumber];
        [self.tableView reloadRowsAtIndexPaths:@[nowPlayingPath]
                              withRowAnimation:UITableViewRowAnimationFade];

    }
    [self.tableView deleteSections:sectionsToDelete
                  withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView reloadSections:sectionsToUpdate
                  withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

#pragma mark - Section helpers
//a brute-force (and surprisingly efficient) way of determing which sections need to be deleted
//when the model (queue-snapshot) changes.
+ (NSIndexSet *)sectionsToDeleteByComparing:(MZPlaybackQueueSnapshot *)oldSnapshot
                              toNewSnapshot:(MZPlaybackQueueSnapshot *)newSnapshot
{
    NSMutableIndexSet *sectionsToDelete = [NSMutableIndexSet new];
    if([QueueViewController historyItemsSectionNumber:oldSnapshot] != NSNotFound
       && [QueueViewController historyItemsSectionNumber:newSnapshot] == NSNotFound) {
        [sectionsToDelete addIndex:[QueueViewController historyItemsSectionNumber:oldSnapshot]];
    }
    if([QueueViewController nowplayingSectionNumber:oldSnapshot] != NSNotFound
       && [QueueViewController nowplayingSectionNumber:newSnapshot] == NSNotFound) {
        [sectionsToDelete addIndex:[QueueViewController nowplayingSectionNumber:oldSnapshot]];
    }
    if([QueueViewController upNextItemsSectionNumber:oldSnapshot] != NSNotFound
       && [QueueViewController upNextItemsSectionNumber:newSnapshot] == NSNotFound) {
        [sectionsToDelete addIndex:[QueueViewController upNextItemsSectionNumber:oldSnapshot]];
    }
    if([QueueViewController futureItemsSectionNumber:oldSnapshot] != NSNotFound
       && [QueueViewController futureItemsSectionNumber:newSnapshot] == NSNotFound) {
        [sectionsToDelete addIndex:[QueueViewController futureItemsSectionNumber:oldSnapshot]];
    }
    return sectionsToDelete;
}

+ (NSUInteger)historyItemsSectionNumber:(MZPlaybackQueueSnapshot *)queueSnapshot
{
    return (queueSnapshot.rangeOfHistoryItems.location == NSNotFound) ? NSNotFound : 0;
}

+ (NSUInteger)nowplayingSectionNumber:(MZPlaybackQueueSnapshot *)queueSnapshot
{
    if([queueSnapshot nowPlayingIndex] == NSNotFound) {
        return NSNotFound;
    }
    if([self historyItemsSectionNumber:queueSnapshot] == NSNotFound) {
        return 0;
    } else {
        return 1;
    }
}

+ (NSUInteger)upNextItemsSectionNumber:(MZPlaybackQueueSnapshot *)queueSnapshot
{
    if(queueSnapshot.upNextQueuedItemsRange.location == NSNotFound) {
        return NSNotFound;
    }
    NSUInteger temp = [self nowplayingSectionNumber:queueSnapshot];
    if(temp == NSNotFound) {
        return NSNotFound;
    } else {
        return temp + 1;
    }
}

+ (NSUInteger)futureItemsSectionNumber:(MZPlaybackQueueSnapshot *)queueSnapshot
{
    if(queueSnapshot.futureItemsRange.location == NSNotFound) {
        return NSNotFound;
    }
    NSUInteger upNextItemsSectionNumber = [self upNextItemsSectionNumber:queueSnapshot];
    if(upNextItemsSectionNumber == NSNotFound) {
        NSUInteger temp = [self nowplayingSectionNumber:queueSnapshot];
        if(temp == NSNotFound) {
            return NSNotFound;
        } else {
           return [self nowplayingSectionNumber:queueSnapshot] + 1;
        }
    } else {
        return upNextItemsSectionNumber + 1;
    }
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    float widthOfScreenRoationIndependant;
    float heightOfScreenRotationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b) {
        heightOfScreenRotationIndependant = b;
        widthOfScreenRoationIndependant = a;
    } else {
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft
       || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        int y = 0;
        int vcWidth = heightOfScreenRotationIndependant;
        int vcHeight = widthOfScreenRoationIndependant;
        //smaller landscape nav bar
        int navBarHeight = [AppEnvironmentConstants navBarHeight] - 4;
        _navBar.frame = CGRectMake(0, y, vcWidth, navBarHeight);
        
        self.tableView.frame = CGRectMake(0, navBarHeight, vcWidth, vcHeight - navBarHeight);
    } else {
        int y = [AppEnvironmentConstants statusBarHeight];
        int vcWidth = widthOfScreenRoationIndependant;
        int vcHeight = heightOfScreenRotationIndependant;
        int navBarHeight = [AppEnvironmentConstants navBarHeight];
        _navBar.frame = CGRectMake(0, y, vcWidth, navBarHeight);
        
        y = [AppEnvironmentConstants navBarHeight] + [AppEnvironmentConstants statusBarHeight];
        self.tableView.frame = CGRectMake(0, y, vcWidth, vcHeight - navBarHeight);
    }
}

- (void)dismissQueueTapped
{
    [self preDealloc];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
