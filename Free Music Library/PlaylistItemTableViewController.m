//
//  PlaylistItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItemTableViewController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "MZTableViewCell.h"
#import "AlbumAlbumArt+Utilities.h"
#import "SongAlbumArt+Utilities.h"
#import "PlaylistItem.h"
#import "Song+Utilities.h"

@interface PlaylistItemTableViewController()
{
    UILabel *tableViewEmptyMsgLabel;
    int numTimesViewWillAppearCalledSinceVcLoad;
}

@property (nonatomic, strong) UITextField *txtField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) SSBouncyButton *centerButton;

@property (nonatomic, strong) NSString *playbackContextUniqueId;
@property (nonatomic, strong) NSString *emptyTableUserMessage;
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
    
    self.emptyTableUserMessage = @"Playlist Empty";
    [self setUpNavBarItems];
    self.navBar = self.navigationItem;
    [[UITextField appearance] setTintColor:[[UIColor defaultAppColorScheme] lighterColor]];  //sets the cursor color of the playlist name textbox editor
    
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
    
    UINavigationController *parentNav = (UINavigationController *)self.parentViewController;
    MainScreenViewController *mainVc = (MainScreenViewController *)parentNav.parentViewController;
    UIImage *img = mainVc.centerButtonImg;
    img = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme] :img];
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
    Song *song = [self songForIndexPath:indexPath];
    
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseId
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
    cell.detailTextLabel.attributedText = [self generateDetailLabelAttrStringForSong:song];
    
    NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
    BOOL songIsNowPlaying = [nowPlayingObj isEqualToSong:song
                                                        compareWithContext:self.playbackContext];
    
    if(songIsNowPlaying)
        cell.textLabel.textColor = [AppEnvironmentConstants nowPlayingItemColor];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
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
                
                //this is a background queue. fetch the object (image blob) using background context!
                NSManagedObjectContext *context = [CoreDataManager stackControllerThreadContext];
                NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"SongAlbumArt"];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", artObjId];
                request.predicate = predicate;
                
                [context performBlockAndWait:^{
                    NSArray *result = [context executeFetchRequest:request error:nil];
                    if(result.count == 1)
                        albumArt = [result[0] imageFromImageData];
                }];
                
                if(albumArt == nil)
                    return;  //no art loaded lol.
            }
        }

        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
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
        Song *songToRemove = [self songForIndexPath:indexPath];
        [MusicPlaybackController songAboutToBeDeleted:songToRemove deletionContext:self.playbackContext];
        
    
        NSMutableSet *set = [NSMutableSet setWithSet:_playlist.playlistItems];
        __block PlaylistItem *songsPlaylistItem;
        NSNumber *songIndex = [NSNumber numberWithShort:indexPath.row];
        
        [set enumerateObjectsUsingBlock:^(PlaylistItem *item, BOOL *stop) {
            //find the playlistItem corresponding to the EXACT song we are removing (taking
            //multiple instances of the same song into account here).
            
            if([item.index isEqualToNumber:songIndex] && [item.song isEqualToSong:songToRemove]){
                songsPlaylistItem = item;
                *stop = YES;
            }
        }];
        
        [set removeObject:songsPlaylistItem];
        _playlist.playlistItems = set;
        [[CoreDataManager sharedInstance] saveContext];
    }
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return _playlist.playlistItems.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.playlist.playlistItems.count == 0){
        NSString *text = self.emptyTableUserMessage;
        [self displayEmptyTableUserMessageWithText:text];
    } else
        [self removeEmptyTableUserMessage];
    
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableSet *set = [NSMutableSet setWithSet:_playlist.playlistItems];
    Song *songBeingMoved = [self songForIndexPath:fromIndexPath];
    
    NSNumber *songIndex = [NSNumber numberWithShort:fromIndexPath.row];
    __block PlaylistItem *songsPlaylistItem;
    
    [set enumerateObjectsUsingBlock:^(PlaylistItem *item, BOOL *stop) {
        //find the playlistItem corresponding to the EXACT song we are moving (taking
        //multiple instances of the same song into account here).
        
        if([item.index isEqualToNumber:songIndex] && [item.song isEqualToSong:songBeingMoved]){
            songsPlaylistItem = item;
            *stop = YES;
        }
    }];
    
    songsPlaylistItem.index = [NSNumber numberWithShort:toIndexPath.row];
    _playlist.playlistItems = set;
    [[CoreDataManager sharedInstance] saveContext];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Song *selectedSong = [self songForIndexPath:indexPath];
    [MusicPlaybackController newQueueWithSong:selectedSong withContext:self.playbackContext];
}

#pragma mark - Table Helpers
- (Song *)songForIndexPath:(NSIndexPath *)indexPath
{
    NSSet *playlistItems = _playlist.playlistItems;
    NSPredicate *extractItemAtThisIndex;
    extractItemAtThisIndex = [NSPredicate predicateWithFormat:@"index == %i", indexPath.row];
    NSSet *setWithPlaylistItem = [playlistItems filteredSetUsingPredicate:extractItemAtThisIndex];
#warning fix this assert
    //NSAssert(setWithPlaylistItem.count == 1, @"Fatal Error: Multiple PlaylistItems contain the same index within playlist: %@", _playlist.playlistName);
    
    PlaylistItem *myItem = [setWithPlaylistItem anyObject];
    return myItem.song;
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
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        Song *song = [self songForIndexPath:indexPath];
        
        expansionSettings.fillOnTrigger = NO;
        expansionSettings.threshold = 1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureQueueItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 9999;
        
        __weak PlaylistItemTableViewController *weakself = self;
        __weak Song *weakSong = song;
        __weak MGSwipeTableCell *weakCell = cell;
        return @[[MGSwipeButton buttonWithTitle:@"Queue"
                                backgroundColor:initialExpansionColor
                                        padding:15
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MZPlaybackQueue presentQueuedHUD];
                                           PlaybackContext *context = [weakself contextForPlaylistSong:weakSong];
                                           [MusicPlaybackController queueUpNextSongsWithContexts:@[context]];
                                           [weakCell refreshContentView];
                                           return YES;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 2.7;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureDeleteItemColor];
        swipeSettings.transition = MGSwipeTransitionBorder;
        
        __weak PlaylistItemTableViewController *weakSelf = self;
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
    Song *oldSong = (Song *)[notification object];
    NowPlayingSong *nowPlaying = [NowPlayingSong sharedInstance];
    Song *newSong = nowPlaying.nowPlaying;
    NSIndexPath *oldPath, *newPath;
    
    //broken
    /*
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
     */
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
    //start listening for notifications (so we know when the modal song picker dissapears)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songPickerWasDismissed:) name:@"song picker dismissed" object:nil];
    
    PlaylistSongAdderTableViewController *vc = [PlaylistSongAdderTableViewController alloc];
    vc = [vc initWithPlaylistsUniqueId:_playlist.uniqueId playlistName:_playlist.playlistName];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navVC animated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@YES];
}

- (void)songPickerWasDismissed:(NSNotification *)someNSNotification
{
    if([someNSNotification.name isEqualToString:@"song picker dismissed"]){
        //MIGHT need to manually re-fetch the playlist due to new changes, but unlikely.
#warning might need to add implementation.
    }
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

#pragma mark - Counting Songs in core data
- (int)numberOfSongsInCoreDataModel
{
    //count how many instances there are of the Song entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:YES];
    NSError *error = nil;
    NSUInteger tempCount = [context countForFetchRequest: fetchRequest error: &error];
    if(error == nil){
        count = (int)tempCount;
    }
    return count;
}

#pragma mark - Helpers
- (PlaybackContext *)contextForPlaylistSong:(Song *)aSong
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PlaylistItem"];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"ANY playlist.uniqueId == %@", _playlist.uniqueId];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"ANY song.uniqueId == %@", aSong.uniqueId];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContextUniqueId];
}

- (void)displayEmptyTableUserMessageWithText:(NSString *)text
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

- (UIView *)friendlyTableUserMessageWithText:(NSString *)text
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
        [newArtistString appendString:@" "];
        
        NSMutableString *entireString = [NSMutableString stringWithString:newArtistString];
        [entireString appendString:albumString];
        
        NSArray *components = @[newArtistString, albumString];
        //NSRange untouchedRange = [entireString rangeOfString:[components objectAtIndex:0]];
        NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:1]];
        
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
