//
//  PlaylistItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItemTableViewController.h"

@interface PlaylistItemTableViewController()
@property (nonatomic, assign) int lastTableViewModelCount;
@property (nonatomic, strong) UITextField *txtField;
@property (nonatomic, assign) BOOL currentlyEditingPlaylistName;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PlaylistItemTableViewController
@synthesize playlist = _playlist, numSongsNotAddedYet = _numSongsNotAddedYet, txtField = _txtField;


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _playlist = nil;
    _txtField = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //this works better than a unique random id since this class can be dealloced and re-alloced
    //later. Id must stay the same across all allocations.  :)
    self.playbackContextUniqueId = NSStringFromClass([self class]);
    [self setUpNavBarItems];
    self.navBar = self.navigationItem;
    [[UITextField appearance] setTintColor:[[UIColor defaultAppColorScheme] lighterColor]];  //sets the cursor color of the playlist name textbox editor
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setTableForCoreDataView:self.tableView];
    self.cellReuseId = @"playlistSongItemCell";
    
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
    
    stackController = [[StackController alloc] init];
    self.tableView.allowsSelectionDuringEditing = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _numSongsNotAddedYet = (int)([self numberOfSongsInCoreDataModel] - _playlist.playlistSongs.count);
    _lastTableViewModelCount = (int)_playlist.playlistSongs.count;
    
    if(_numSongsNotAddedYet == 0)
        _addBarButton.enabled = NO;
    
    //set song/album details for currently selected song
    NSString *navBarTitle = _playlist.playlistName;
    self.navBar.title = navBarTitle;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)setUpNavBarItems
{
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addButtonPressed)];
    self.addBarButton = addButton;
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;  //place both buttons on the nav bar
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
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

    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    BOOL songIsNowPlaying = [[NowPlayingSong sharedInstance] isEqualToSong:song compareWithContext:self.playbackContext];
    if(songIsNowPlaying)
        cell.textLabel.textColor = [super colorForNowPlayingItem];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &songIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                    [AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]]];
        if(albumArt == nil) //see if this song has an album. If so, check if it has art.
            if(song.album != nil)
                albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                   [AlbumArtUtilities albumArtFileNameToNSURL:song.album.albumArtFileName]]];
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                
                __weak UIImage *cellImg = albumArt;
                //calculate how much one length varies from the other.
                int diff = abs(albumArt.size.width - albumArt.size.height);
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
    //could also selectively choose which rows may be deleted here.
    if(_lastTableViewModelCount == 0)
        return NO;
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SongTableViewFormatter preferredSongCellHeight];
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        [MusicPlaybackController songAboutToBeDeleted:[_playlist.playlistSongs objectAtIndex:indexPath.row] deletionContext:self.playbackContext];
        
        //remove song from playlist only (not song from library in general)
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:_playlist.playlistSongs];
        [set removeObjectAtIndex:indexPath.row];
        _playlist.playlistSongs = set;
        [[CoreDataManager sharedInstance] saveContext];
        
        //keep track of how many songs i can still add in this playlist (so we know when to grey out plus button)
        _numSongsNotAddedYet++;
        _lastTableViewModelCount--;
        if(_numSongsNotAddedYet == 0)
            _addBarButton.enabled = NO;
        else
            _addBarButton.enabled = YES;
    }
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:_playlist.playlistSongs];
    [set moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndexPath.row] toIndex:toIndexPath.row];
    _playlist.playlistSongs = set;
    [[CoreDataManager sharedInstance] saveContext];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    Song *selectedSong = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:self];
    [MusicPlaybackController newQueueWithSong:selectedSong withContext:self.playbackContext];
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
        Song *song = [self.fetchedResultsController
                        objectAtIndexPath:[self.tableView indexPathForCell:cell]];
        
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
                                        padding:40
                                       callback:^BOOL(MGSwipeTableCell *sender) {
                                           [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongQueued];
                                           NSLog(@"Queing up: %@", weakSong.songName);
                                           PlaybackContext *context = [weakself contextForPlaylistSong:weakSong];
                                           [MusicPlaybackController queueUpNextSongsWithContexts:@[context]];
                                           [weakCell refreshContentView];
                                           return YES;
                                       }]];
    } else if(direction == MGSwipeDirectionRightToLeft){
        expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 1.1;
        expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
        expansionSettings.expansionColor = [AppEnvironmentConstants expandingCellGestureDeleteItemColor];
        swipeSettings.transition = MGSwipeTransitionClipCenter;
        swipeSettings.threshold = 50;
        
        __weak PlaylistItemTableViewController *weakSelf = self;
        MGSwipeButton *delete = [MGSwipeButton buttonWithTitle:@"Delete"
                                               backgroundColor:initialExpansionColor
                                                       padding:50
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

#pragma mark - Button actions
- (void)editTapped:(id)sender
{
    if(self.tableView.editing)
    {
        [self.navBar setRightBarButtonItems:_originalRightBarButtonItems animated:YES];
        [self.navBar setLeftBarButtonItems:_originalLeftBarButtonItems animated:YES];
        
        _originalLeftBarButtonItems = nil;
        _originalRightBarButtonItems = nil;
        
        [self.tableView setEditing:NO animated:YES];
        [self setEditing:self.tableView.editing animated:YES];
        [self.navigationItem setHidesBackButton:NO animated:YES];
        _currentlyEditingPlaylistName = NO;
        
        [UIView animateWithDuration:1 animations:^{
            self.navBar.titleView = nil;
            self.navBar.title = _playlist.playlistName;
        }];
        
        //needed to avoid weird things happening after editing and re-ordering cell.
        float delaySeconds = 0.3;
        __block PlaylistItemTableViewController *blockSelf = self;
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC);
        dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
            [blockSelf setFetchedResultsControllerAndSortStyle];
            [blockSelf.tableView reloadData];
        });
    }
    else
    {
        _currentlyEditingPlaylistName = YES;
        [UIView animateWithDuration:1 animations:^{
            //allows for renaming the playlist
            [self setUpUITextField];
            [self.tableView setEditing:YES animated:YES];
            [self setEditing:self.tableView.editing animated:YES];
        } completion:^(BOOL finished) {
        }];
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)addButtonPressed
{
    //start listening for notifications (so we know when the modal song picker dissapears)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songPickerWasDismissed:) name:@"song picker dismissed" object:nil];
    
    PlaylistSongAdderTableViewController *vc = [[PlaylistSongAdderTableViewController alloc] initWithPlaylist:_playlist];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)songPickerWasDismissed:(NSNotification *)someNSNotification
{
    if([someNSNotification.name isEqualToString:@"song picker dismissed"]){
        if(someNSNotification.object != nil)  //songs added to playlist, created a new one to replace the old one. need to update our VC model.
        {
            _playlist = (Playlist *) someNSNotification.object;
            [self setFetchedResultsControllerAndSortStyle];
        }

        if(_lastTableViewModelCount < _playlist.playlistSongs.count){  //songs added
            int x = (int)(_playlist.playlistSongs.count - _lastTableViewModelCount);
            _numSongsNotAddedYet = _numSongsNotAddedYet - x;
            _lastTableViewModelCount = _lastTableViewModelCount + x;
        }//else nothing changed (remember, we can't remove songs using the song picker)
        
        if(_numSongsNotAddedYet == 0)
            _addBarButton.enabled = NO;
        else
            _addBarButton.enabled = YES;
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
    
    [_txtField addTarget:self action:@selector(userTappedUITextField) forControlEvents:UIControlEventEditingDidBegin];
    
    _txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _txtField.autoresizesSubviews = YES;
    _txtField.layer.cornerRadius = 5.0;
    [_txtField setBorderStyle:UITextBorderStyleRoundedRect];
    _txtField.text = _playlist.playlistName;
    if([AppEnvironmentConstants boldNames])
        _txtField.font = [UIFont boldSystemFontOfSize:20];
    else
        _txtField.font = [UIFont systemFontOfSize:20];
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
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else{
        return NO;
    }
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
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];
    NSError *error = nil;
    NSUInteger tempCount = [context countForFetchRequest: fetchRequest error: &error];
    if(error == nil){
        count = (int)tempCount;
    }
    return count;
}

#pragma mark - Helper
- (PlaybackContext *)contextForPlaylistSong:(Song *)aSong
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    NSPredicate *playlistSongsPredicate = [NSPredicate predicateWithFormat:@"ANY playlistIAmIn.playlist_id == %@ ", _playlist.playlist_id];
    NSPredicate *desiredSongInPlaylist = [NSPredicate predicateWithFormat:@"ANY song_id == %@", aSong.song_id];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[playlistSongsPredicate, desiredSongInPlaylist]];\
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistIAmIn"
                                                                     ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    return [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                         prettyQueueName:@""
                                               contextId:self.playbackContextUniqueId];
}

#pragma mark - fetching and sorting
- (void)setFetchedResultsControllerAndSortStyle
{
    self.fetchedResultsController = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY playlistIAmIn.playlist_id == %@", _playlist.playlist_id];
    
    //picked genreCode because its a useless value...need that so the results of the
    //nsorderedset dont get re-ordered
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistIAmIn"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    if(self.playbackContext == nil){
        self.playbackContext = [[PlaybackContext alloc] initWithFetchRequest:[request copy]
                                                             prettyQueueName:@""
                                                                   contextId:self.playbackContextUniqueId];
    }
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[CoreDataManager context]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
