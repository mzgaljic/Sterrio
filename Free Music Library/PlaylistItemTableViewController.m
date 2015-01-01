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
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self setFetchedResultsControllerAndSortStyle];
    [self setUpNavBarItems];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = YES;

    _numSongsNotAddedYet = (int)([self numberOfSongsInCoreDataModel] - _playlist.playlistSongs.count);
    _lastTableViewModelCount = (int)_playlist.playlistSongs.count;
    
    if(_numSongsNotAddedYet == 0)
        _addBarButton.enabled = NO;
    
    //set song/album details for currently selected song
    NSString *navBarTitle = _playlist.playlistName;
    self.navBar.title = navBarTitle;
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
    UIBarButtonItem *addButton = self.addBarButton;
    
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;  //place both buttons on the nav bar
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

#pragma mark - Table View Data Source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistSongItemCell" forIndexPath:indexPath];
    // Configure the cell...
    Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"playlistSongItemCell"];
    else
    {
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:[AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]]];
        albumArt = [AlbumArtUtilities imageWithImage:albumArt scaledToSize:CGSizeMake(cell.frame.size.height, cell.frame.size.height)];
        cell.imageView.image = albumArt;
    }
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
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
    [MusicPlaybackController newQueueWithSong:selectedSong album:nil artist:nil playlist:_playlist genreCode:0 skipCurrentSong:YES];
    [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:self];
}

#pragma mark - Button actions
- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        [self.navBar setRightBarButtonItems:_originalRightBarButtonItems animated:YES];
        [self.navBar setLeftBarButtonItems:_originalLeftBarButtonItems animated:YES];
        self.navBar.titleView = nil;
        self.navBar.title = _playlist.playlistName;
        _originalLeftBarButtonItems = nil;
        _originalRightBarButtonItems = nil;
        
        [super setEditing:NO animated:YES];
        [self.navigationItem setHidesBackButton:NO animated:YES];
        _currentlyEditingPlaylistName = NO;
    }
    else
    {
        [super setEditing:YES animated:YES];
        _currentlyEditingPlaylistName = YES;
        
        //allows for renaming the playlist
        [self setUpUITextField];
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (IBAction)addButtonPressed:(id)sender
{
    //start listening for notifications (so we know when the modal song picker dissapears)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songPickerWasDismissed:) name:@"song picker dismissed" object:nil];
    
    PlaylistSongAdderTableViewController *vc = [[PlaylistSongAdderTableViewController alloc] initWithPlaylist:_playlist];
    [self.navigationController pushViewController:vc animated:YES];
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
    [[[[[_txtField.backgroundColor darkerColor] darkerColor]darkerColor] darkerColor] darkerColor];
    _txtField.textColor = [UIColor blackColor];
    [_txtField setDelegate:self];
    _txtField.textAlignment = NSTextAlignmentRight;
    
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self.navBar setRightBarButtonItems:@[editButton] animated:YES];
    [self.navBar setLeftBarButtonItems:nil animated:YES];
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
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        [self setTabBarVisible:NO animated:NO];
        self.tabBarController.tabBar.hidden = YES;
        return YES;
    }
    else{
        [self setTabBarVisible:NO animated:NO];
        self.tabBarController.tabBar.hidden = YES;
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
}

- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated
{
    // bail if the current state matches the desired state
    if ([self tabBarIsVisible] == visible) return;
    
    // get a frame calculation ready
    CGRect frame = self.tabBarController.tabBar.frame;
    CGFloat height = frame.size.height;
    CGFloat offsetY = (visible)? -height : height;
    
    // zero duration means no animation
    CGFloat duration = (animated)? 0.3 : 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        self.tabBarController.tabBar.frame = CGRectOffset(frame, 0, offsetY);
    }];
}

- (BOOL)tabBarIsVisible
{
    return self.tabBarController.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
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

#pragma mark - fetching and sorting
- (void)setFetchedResultsControllerAndSortStyle
{
    self.fetchedResultsController = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY playlistIAmIn.playlist_id == %@", _playlist.playlist_id];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"playlistIAmIn"
                                                                     ascending:YES];
    
    request.sortDescriptors = @[sortDescriptor];
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[CoreDataManager context]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
