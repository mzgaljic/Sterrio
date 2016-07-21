//
//  PlaylistItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

@import CoreFoundation;  //for CFMutableSet
#import "PlaylistItemTableViewController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "MZTableViewCell.h"
#import "AlbumAlbumArt+Utilities.h"
#import "SongAlbumArt+Utilities.h"
#import "PlaylistItem.h"
#import "Song+Utilities.h"
#import "PlaylistItem+Utilities.h"
#import "PlayableItem.h"
#import "PreviousNowPlayingInfo.h"
#import "MainScreenViewController.h"

@interface PlaylistItemTableViewController()
{
    UILabel *tableViewEmptyMsgLabel;
    int numTimesViewWillAppearCalledSinceVcLoad;
}

@property (nonatomic, strong) UITextField *txtField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) SSBouncyButton *centerButton;

@property (nonatomic, strong) NSString *playbackContextUniqueId;
@property (nonatomic, strong) NSAttributedString *emptyTableUserMessage;
@property (nonatomic, strong) NSString *cellReuseId;
@property (nonatomic, strong) PlaybackContext *playbackContext;

@property (nonatomic, assign) BOOL currentlyEditingPlaylistName;
@end

@implementation PlaylistItemTableViewController
@synthesize playlist = _playlist, txtField = _txtField;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    stackController = nil;
    self.playbackContext = nil;
    self.emptyTableUserMessage = nil;
    self.playbackContextUniqueId = nil;
    self.centerButton = nil;
    self.txtField = nil;
    _playlist = nil;
    _txtField = nil;
    
    
    if(self.presentedViewController == nil){
        //in case user leaves VC without explicitly leaving editing mode in the table.
        [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    numTimesViewWillAppearCalledSinceVcLoad = 0;
    
    //caution, updating this uniqueID logic means i MUST update the same logic in AllPlaylistsDataSource.
    NSMutableString *uniqueID = [NSMutableString string];
    [uniqueID appendString:NSStringFromClass([self class])];
    [uniqueID appendString:self.playlist.uniqueId];
    self.playbackContextUniqueId = uniqueID;
    
    self.emptyTableUserMessage = [MZCommons makeAttributedString:@"Playlist Empty"];
    [self setUpNavBarItems];
    self.navBar = self.navigationItem;
    [[UITextField appearance] setTintColor:[AppEnvironmentConstants appTheme].mainGuiTint];  //sets the cursor color of the playlist name textbox editor
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.cellReuseId = @"playlistSongItemCell";
    
    stackController = [[StackController alloc] init];
    self.tableView.allowsSelectionDuringEditing = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowPlayingSongsHasChanged:)
                                                 name:MZNewSongLoading
                                               object:nil];
    
    [self initPlaybackContext];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //plus sign at bottom of screen can cut off the last cell if there are enough songs in the playlist.
    int buttonOffsetFromBottom = (MZTabBarHeight - self.centerButton.frame.size.height)/2;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, MZTabBarHeight + buttonOffsetFromBottom, 0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //set song/album details for currently selected song
    NSString *navBarTitle = _playlist.playlistName;
    self.navBar.title = navBarTitle;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(numTimesViewWillAppearCalledSinceVcLoad == 0)
        [self presentCenterButtonAnimated];
    numTimesViewWillAppearCalledSinceVcLoad++;
}

- (void)setUpNavBarItems
{
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    NSArray *rightBarButtonItems = @[editButton];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;  //place both buttons on the nav bar
}

- (void)presentCenterButtonAnimated
{
    if(dismissingCenterBtnInProgress){
        [self.centerButton removeFromSuperview];
        self.centerButton = nil;
        dismissingCenterBtnInProgress = NO;
    }
    
    UIImage *img =[MZCommons centerButtonImage];
    img = [UIImage colorOpaquePartOfImage:[AppEnvironmentConstants appTheme].mainGuiTint :img];
    self.centerButton = [[SSBouncyButton alloc] initAsImage];
    [self.centerButton setImage:img forState:UIControlStateNormal];
    [self.centerButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    [self.centerButton addTarget:self
                          action:@selector(tabBarAddButtonWithDelay)
                forControlEvents:UIControlEventTouchUpInside];
    int btnDiameter = img.size.width;
    CGRect beginFrame = CGRectMake(self.view.frame.size.width/2 - btnDiameter/2,
                                   self.view.frame.size.height,
                                   btnDiameter,
                                   btnDiameter);
    CGRect endFrame = CGRectMake(beginFrame.origin.x,
                                 beginFrame.origin.y - MZTabBarHeight,
                                 btnDiameter,
                                 btnDiameter);
    self.centerButton.frame = beginFrame;
    [self.centerButton setBackgroundColor:[UIColor whiteColor]];
    float cornerRadius = self.centerButton.frame.size.height / 2;
    [self.centerButton.layer setCornerRadius:cornerRadius];
    [self.view addSubview:self.centerButton];
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.55
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.centerButton.frame = endFrame;
                     }
                     completion:nil];
}

static BOOL dismissingCenterBtnInProgress = NO;
- (void)dismissCenterButtonAnimated
{
    CGRect currentRect = self.centerButton.frame;
    CGRect moveOffScreen = CGRectMake(currentRect.origin.x,
                                      currentRect.origin.y + MZTabBarHeight,
                                      currentRect.size.width,
                                      currentRect.size.height);
    dismissingCenterBtnInProgress = YES;
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:1
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.centerButton.frame = moveOffScreen;
                     } completion:^(BOOL finished) {
                         [self.centerButton removeFromSuperview];
                         self.centerButton = nil;
                         dismissingCenterBtnInProgress = NO;
                     }];
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlaylistItem *item = [self playlistItemForIndexPath:indexPath];
    Song *song = item.song;
    
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

    cell.textLabel.text = song.songName;
    NSMutableString *detailText = [NSMutableString new];
    NSString *artistName = song.artist.artistName;
    NSString *albumName = song.album.albumName;
    if(artistName != nil && albumName != nil){
        [detailText appendString:artistName];
        [detailText appendString:@" — "];
        [detailText appendString:albumName];
    } else if(artistName == nil && albumName == nil){
        detailText = nil;
    } else if(artistName == nil && albumName != nil){
        [detailText appendString:albumName];
    } else if(artistName != nil && albumName == nil){
        [detailText appendString:artistName];
    } //else  --case should never happen

    cell.detailTextLabel.text = detailText;
    
    NowPlaying *nowPlayingObj = [NowPlaying sharedInstance];
    BOOL songIsNowPlaying = [nowPlayingObj.playableItem isEqualToPlaylistItem:item withContext:self.playbackContext];
    
    if(songIsNowPlaying) {
        cell.textLabel.textColor = [AppEnvironmentConstants appTheme].mainGuiTint;
        cell.isRepresentingANowPlayingItem = YES;
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.isRepresentingANowPlayingItem = NO;
    }
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &songIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    __weak Song *weakSong = song;
    
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        __block UIImage *albumArt;
        if(weakSong){
            NSString *artObjId = weakSong.albumArt.uniqueId;
            if(artObjId){
                
                //this is a background queue. get the object (image blob) on background context!
                NSManagedObjectContext *context = [CoreDataManager stackControllerThreadContext];
                [context performBlockAndWait:^{
                    albumArt = [weakSong.albumArt imageFromImageData];
                }];
                
                if(albumArt == nil)
                    albumArt = [UIImage imageNamed:@"Sample Album Art"];
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
    
    cell.delegate = self;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AppEnvironmentConstants preferredSongCellHeight];
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        PlaylistItem *item = [self playlistItemForIndexPath:indexPath];
        [MusicPlaybackController playlistItemAboutToBeDeleted:item];
        
        //NOTE: Deleting the playlistItem (and saving context) will trigger code to run that
        //fixes the index of every playlistItem after the deleted one within this playlist.
        //IMPORTANT: order of these calls is crucial.
        NSMutableSet *set = [NSMutableSet setWithSet:_playlist.playlistItems];
        [[CoreDataManager context] deleteObject:item];
        [set removeObject:item];
        _playlist.playlistItems = set;
        [[CoreDataManager sharedInstance] saveContext];
        
        [self.tableView beginUpdates];
        if(_playlist.playlistItems.count == 0){
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                          withRowAnimation:UITableViewRowAnimationMiddle];
        } else{
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationMiddle];
            
            if(_playlist.playlistItems.count > 0){
                //need to update all visible cells in front of the deleted indexpath to ensure that
                //the cells are refreshed and represent the new correct PlaylistItem (after indexes are
                //changed).
                
                NSMutableArray *pathsToReload = [NSMutableArray array];
                for(NSIndexPath *aPath in self.tableView.indexPathsForVisibleRows){
                    if(aPath.row > indexPath.row)
                        [pathsToReload addObject:aPath];
                }
                [self.tableView reloadRowsAtIndexPaths:pathsToReload
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        [self.tableView endUpdates];
    }
}

- (void)reloadEntireTable
{
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return _playlist.playlistItems.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.playlist.playlistItems.count == 0){
        NSAttributedString *text = self.emptyTableUserMessage;
        [self displayEmptyTableUserMessageWithText:text];
    } else
        [self removeEmptyTableUserMessage];
    
    return (_playlist.playlistItems.count > 0) ? 1 : 0;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if([fromIndexPath isEqual:toIndexPath])
        return;
    
    NSPredicate *itemAtOriginPathPredicate, *itemAtDestPathPredicate;
    itemAtOriginPathPredicate = [NSPredicate predicateWithFormat:@"index == %i", fromIndexPath.row];
    itemAtDestPathPredicate = [NSPredicate predicateWithFormat:@"index == %i", toIndexPath.row];
    
    NSSet *set1 = [_playlist.playlistItems filteredSetUsingPredicate:itemAtOriginPathPredicate];
    NSSet *set2 = [_playlist.playlistItems filteredSetUsingPredicate:itemAtDestPathPredicate];
    PlaylistItem *item1 = [set1 anyObject];
    PlaylistItem *item2 = [set2 anyObject];
    
    NSNumber *tempIndex = item1.index;
    item1.index = item2.index;
    item2.index = tempIndex;
    [[CoreDataManager sharedInstance] saveContext];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    PlaylistItem *item = [self playlistItemForIndexPath:indexPath];
    [MusicPlaybackController newQueueWithPlaylistItem:item withContext:self.playbackContext];
}

#pragma mark - Table Helpers
- (PlaylistItem *)playlistItemForIndexPath:(NSIndexPath *)indexPath
{
    NSPredicate *extractItemAtThisIndex;
    extractItemAtThisIndex = [NSPredicate predicateWithFormat:@"index == %i", indexPath.row];
    NSSet *setWithPlaylistItem = [_playlist.playlistItems filteredSetUsingPredicate:extractItemAtThisIndex];
    
    PlaylistItem *myItem;
    
    if(setWithPlaylistItem.count > 1)
    {
        //multiple songs claim to be at this index. let the oldest item win.
        
        __block PlaylistItem *oldestItem;
        [setWithPlaylistItem enumerateObjectsUsingBlock:^(PlaylistItem *item, BOOL *stop) {
            if(oldestItem == nil)
                oldestItem = item;
            else
            {
                NSDate *date1 = oldestItem.creationDate;
                NSDate *date2 = item.creationDate;
                
                if ([date1 compare:date2] == NSOrderedDescending)
                {
                    //date1 is newer than date2
                    oldestItem = item;  //found an older date
                }
                else if ([date1 compare:date2] == NSOrderedAscending)
                {
                    //date1 is older than date2
                    oldestItem = oldestItem;  //no change
                }
                else
                {
                    //dates are exactly the same
                    oldestItem = oldestItem;  //lets just arbitrarily keep it the same.
                }
            }
        }];
        
        myItem = oldestItem;
        NSMutableArray *allItems = [NSMutableArray arrayWithArray:[_playlist.playlistItems allObjects]];
        
        //increment the remaining items claiming to be at this index...
        [setWithPlaylistItem enumerateObjectsUsingBlock:^(PlaylistItem *item, BOOL *stop) {
            if(! [oldestItem isEqualToPlaylistItem:item])
            {
                NSUInteger index = [allItems indexOfObjectIdenticalTo:item];
                if(index != NSNotFound)
                {
                    item.index = [NSNumber numberWithShort:[item.index shortValue] + 1];
                    [allItems replaceObjectAtIndex:index withObject:item];
                }
            }
        }];
        
        _playlist.playlistItems = [NSSet setWithArray:allItems];
        
        //commit changes
        [[CoreDataManager sharedInstance] saveContext];
    }
    else
        myItem = [setWithPlaylistItem anyObject];

    return myItem;
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
    swipeSettings.transition = MGSwipeTransitionClipCenter;
    swipeSettings.keepButtonsSwiped = NO;
    expansionSettings.buttonIndex = 0;
    expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
    expansionSettings.threshold = 1.0;
    expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunctionCubicOut;
    expansionSettings.fillOnTrigger = NO;
    UIColor *initialExpansionColor = [MZAppTheme expandingCellGestureInitialColor];
    
    if(direction == MGSwipeDirectionLeftToRight){
        //queue
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        PlaylistItem *item = [self playlistItemForIndexPath:indexPath];
        __weak PlaylistItem *weakItem = item;
        expansionSettings.expansionColor = [MZAppTheme expandingCellGestureQueueItemColor];
        __weak PlaylistItemTableViewController *weakself = self;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:MZCellSpotifyStylePaddingValue
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MZCommons presentQueuedHUD];
                                           PlaybackContext *context = [weakself contextForPlaylistItem:weakItem];
                                           [MusicPlaybackController queueSongsOnTheFlyWithContext:context];
                                           [weakCell refreshContentView];
                                           return NO;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.expansionColor = [MZAppTheme expandingCellGestureDeleteItemColor];
        __weak PlaylistItemTableViewController *weakSelf = self;
        MGSwipeButton *delete = [MGSwipeButton buttonWithTitle:@"Delete"
                                               backgroundColor:initialExpansionColor
                                                       padding:MZCellSpotifyStylePaddingValue
                                                      callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     NSIndexPath *indexPath;
                                     indexPath= [weakSelf.tableView indexPathForCell:sender];
                                     [weakSelf tableView:weakSelf.tableView
                                      commitEditingStyle:UITableViewCellEditingStyleDelete
                                       forRowAtIndexPath:indexPath];
                                     return NO;
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
    NowPlaying *nowPlaying = [NowPlaying sharedInstance];
    PlayableItem *oldPlayableItem = [PreviousNowPlayingInfo playableItemBeforeNewSongBeganLoading];
    PlaylistItem *oldItem = oldPlayableItem.playlistItemForItem;
    PlaylistItem *newItem = nowPlaying.playableItem.playlistItemForItem;
    NSIndexPath *oldPath, *newPath;
    
    if(oldItem)
        oldPath = [NSIndexPath indexPathForRow:[oldItem.index integerValue] inSection:0];
    if(newItem)
        newPath = [NSIndexPath indexPathForRow:[newItem.index integerValue] inSection:0];
    
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

#pragma mark - Button actions
- (void)editTapped:(id)sender
{
    if(self.tableView.editing)
    {
        [self.navBar setRightBarButtonItems:_originalRightBarButtonItems animated:NO];
        [self.navBar setLeftBarButtonItems:_originalLeftBarButtonItems animated:YES];
        
        _originalLeftBarButtonItems = nil;
        _originalRightBarButtonItems = nil;
        
        [self.tableView setEditing:NO animated:YES];
        [self setEditing:self.tableView.editing animated:YES];
        [self.navigationItem setHidesBackButton:NO animated:YES];
        _currentlyEditingPlaylistName = NO;
        
        [UIView animateWithDuration:0.7 animations:^{
            self.navBar.titleView = nil;
            self.navBar.title = _playlist.playlistName;
        }];
        
        [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
        
        //needed to make sure the interface appears ok after re-ordering, etc.
        //[self.tableView reloadData];
        
        [self presentCenterButtonAnimated];
    }
    else
    {
        //things can get VERY screwy if merges occur while user is re-ordering their playlists songs.
        [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:YES];
        
        _currentlyEditingPlaylistName = YES;
        [UIView animateWithDuration:0.7 animations:^{
            //allows for renaming the playlist
            [self setUpUITextField];
            [self.tableView setEditing:YES animated:YES];
            [self setEditing:self.tableView.editing animated:YES];
        } completion:nil];
        
        [self dismissCenterButtonAnimated];
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)tabBarAddButtonWithDelay
{
    [self performSelector:@selector(tabBarAddButtonPressed) withObject:nil afterDelay:0.2];
}

- (void)tabBarAddButtonPressed
{
    PlaylistSongAdderTableViewController *vc = [PlaylistSongAdderTableViewController alloc];
    vc = [vc initWithPlaylistsUniqueId:_playlist.uniqueId playlistName:_playlist.playlistName];
    [vc setVcToNotifyAboutRotation:self];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navVC animated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@YES];
}

#pragma mark - UITextField methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *newName = textField.text;
    if([newName isEqualToString:_playlist.playlistName]){
        [textField resignFirstResponder];
        [self userTappedCancel];
        return YES;
    }
    [textField resignFirstResponder];
    [self commitNewPlaylistName:newName];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (void)setUpUITextField
{
    //so we can restore their state afterwards
    _originalLeftBarButtonItems = self.navBar.leftBarButtonItems;
    _originalRightBarButtonItems = self.navBar.rightBarButtonItems;
    
    //purposely using huge width...making sure its always as big as possible on screen.
    _txtField = [[UITextField alloc] initWithFrame :CGRectMake(15, 100, self.view.frame.size.width - (65), 27)];
    
    [_txtField addTarget:self
                  action:@selector(userTappedUITextField)
        forControlEvents:UIControlEventEditingDidBegin];
    
    _txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _txtField.autoresizesSubviews = YES;
    _txtField.layer.cornerRadius = 5.0;
    [_txtField setBorderStyle:UITextBorderStyleRoundedRect];
    _txtField.text = _playlist.playlistName;
    _txtField.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:20];
    _txtField.returnKeyType = UIReturnKeyDone;
    _txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    _txtField.backgroundColor = [UIColor whiteColor];
    _txtField.textColor = [UIColor blackColor];
    [_txtField setDelegate:self];
    _txtField.textAlignment = NSTextAlignmentCenter;
    
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self.navBar setRightBarButtonItems:@[editButton] animated:YES];
    [self.navBar setLeftBarButtonItems:nil animated:NO];
    self.navBar.titleView = _txtField;
}

- (void)userTappedCancel
{
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    [self.navBar setRightBarButtonItem:editButton animated:YES];
    _txtField.text = _playlist.playlistName;  //restore original playlist name
    
    [_txtField resignFirstResponder];
}

- (void)commitNewPlaylistName:(NSString *)newName
{
    _playlist.playlistName = newName;
    [[CoreDataManager sharedInstance] saveContext];
    _txtField.text = _playlist.playlistName;  //make change visible in nav bar
    
    //bring back UI to the normal editing mode (leaving playlist editing mode)
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    [self.navBar setRightBarButtonItem:editButton animated:YES];
    
    //dismiss keyboard
    [_txtField resignFirstResponder];
}

- (void)userTappedUITextField
{
    [self.navBar setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                     target:self action:@selector(userTappedCancel)] animated:YES];
}


#pragma mark - Rotation status bar methods
static BOOL hidingCenterBtnAnimationComplete = YES;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    hidingCenterBtnAnimationComplete = NO;
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:1
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.centerButton.alpha = 0;
                         [self.centerButton removeFromSuperview];
                     } completion:^(BOOL finished) {
                         hidingCenterBtnAnimationComplete = YES;
                     }];
    
    [self setNeedsStatusBarAppearanceUpdate];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustCenterBtnFrameAfterRotation];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)adjustCenterBtnFrameAfterRotation
{
    int btnDiameter = self.centerButton.frame.size.height;
    int viewWidth = self.view.frame.size.width;
    int viewHeight = self.view.frame.size.height;
    CGRect oldFrame = CGRectMake((viewWidth/2) - (btnDiameter/2),
                                viewHeight,
                                btnDiameter,
                                btnDiameter);
    CGRect newFrame = CGRectMake((viewWidth/2) - (btnDiameter/2),
                                 viewHeight - MZTabBarHeight,
                                 btnDiameter,
                                 btnDiameter);
    self.centerButton.frame = oldFrame;
    
    [UIView animateWithDuration:0.35
                          delay:0
         usingSpringWithDamping:0.55
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         if(! hidingCenterBtnAnimationComplete){
                             [self.centerButton removeFromSuperview];
                         }
                         [self.view addSubview:self.centerButton];
                         self.centerButton.alpha = 1;
                         self.centerButton.frame = newFrame;
                     }
                     completion:nil];
}

- (BOOL)prefersStatusBarHidden
{
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        return YES;
    else
        return NO;
}

#pragma mark - Helpers
- (PlaybackContext *)contextForPlaylistItem:(PlaylistItem *)playlistItem
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaylistItem"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", playlistItem.uniqueId];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    request.predicate = predicate;
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContextUniqueId];
}

- (void)displayEmptyTableUserMessageWithText:(NSAttributedString *)text
{
    UILabel *aLabel = (UILabel *)[self friendlyTableUserMessageWithText:text];
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    //code assumes there is no search feature in this VC.
    CGPoint newLabelCenter = self.tableView.backgroundView.center;
    
    aLabel.center = newLabelCenter;
    aLabel.alpha = 0.3;
    [self.tableView.backgroundView addSubview:aLabel];
    [UIView animateWithDuration:0.4 animations:^{
        aLabel.alpha = 1;
    }];
    
}

- (UIView *)friendlyTableUserMessageWithText:(NSAttributedString *)text
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if(tableViewEmptyMsgLabel){
        [tableViewEmptyMsgLabel removeFromSuperview];
        tableViewEmptyMsgLabel = nil;
    }
    tableViewEmptyMsgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       self.tableView.bounds.size.width,
                                                                       self.tableView.bounds.size.height)];
    if(text == nil)
        text = [MZCommons makeAttributedString:@""];
    tableViewEmptyMsgLabel.attributedText = text;
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

- (void)removeEmptyTableUserMessage
{
    [tableViewEmptyMsgLabel removeFromSuperview];
    self.tableView.backgroundView = nil;
    tableViewEmptyMsgLabel = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}


#pragma mark - Playback Context
- (void)initPlaybackContext
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaylistItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY playlist.uniqueId == %@", _playlist.uniqueId];
    [request setFetchBatchSize:MZDefaultCoreDataFetchBatchSize];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    if(self.playbackContext == nil){
        NSString *queueName = [NSString stringWithFormat:@"\"%@\" Playlist",_playlist.playlistName];
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:queueName
                                                                   contextId:self.playbackContextUniqueId];
    }
}

//copy pasted from AllSongsDataSource
- (NSAttributedString *)generateDetailLabelAttrStringForSong:(Song *)aSong
{
    NSString *artistString = aSong.artist.artistName;
    NSString *albumString = aSong.album.albumName;
    if(artistString != nil && albumString != nil){
        NSMutableString *newArtistString = [NSMutableString stringWithString:artistString];
        [newArtistString appendString:@" — "];  //this is a special dash called an 'em dash'.
        
        NSMutableString *entireString = [NSMutableString stringWithString:newArtistString];
        [entireString appendString:albumString];
        NSRange grayRange = [entireString rangeOfString:entireString];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        
        [attrString beginEditing];
        [attrString addAttribute: NSForegroundColorAttributeName
                           value:[UIColor grayColor]
                           range:grayRange];
        [attrString endEditing];
        return attrString;
        
    } else if(artistString == nil && albumString == nil)
        return nil;
    
    else if(artistString == nil && albumString != nil){
        NSMutableString *entireString = [NSMutableString stringWithString:albumString];
        
        NSArray *components = @[albumString];
        NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:0]];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        
        [attrString beginEditing];
        [attrString addAttribute: NSForegroundColorAttributeName
                           value:[UIColor grayColor]
                           range:grayRange];
        [attrString endEditing];
        return attrString;
        
    } else if(artistString != nil && albumString == nil){
        
        NSMutableString *entireString = [NSMutableString stringWithString:artistString];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        return attrString;
        
    } else  //case should never happen
        return nil;
}


@end
