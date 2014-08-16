//
//  MasterSongsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterSongsTableViewController.h"

@interface MasterSongsTableViewController ()
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *allSongsInLibrary;
@property (nonatomic, assign) int indexOfEditingSong;
@property (nonatomic, assign) int selectedRowIndexValue;
@property (nonatomic, strong) UISearchBar* searchBar;
@property (nonatomic, assign) BOOL displaySearchResults;
@end

@implementation MasterSongsTableViewController
static BOOL PRODUCTION_MODE;

#pragma mark - Miscellaneous
- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)setUpNavBarItems
{
    //right side of nav bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
                                                                               action:@selector(addButtonPressed)];
    
    UIImage *image = [UIImage imageNamed:@"Now Playing"];
    UIBarButtonItem *nowPlaying = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(nowPlayingTapped)];
    nowPlaying.target = self;
    nowPlaying.action = @selector(nowPlayingTapped);
    
#warning check to see if item is actually playing when adding the now playing button!
    UIBarButtonItem *negSpaceAdjust = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [negSpaceAdjust setWidth:-10];
    
    NSArray *rightBarButtonItems = @[negSpaceAdjust, nowPlaying, addButton];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    //left side of nav bar
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    image = [UIImage imageNamed:@"Settings-Line"];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self
                                                                action:@selector(settingsButtonTapped)];
    UIBarButtonItem *posSpaceAdjust = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [posSpaceAdjust setWidth:28];
    
    self.navigationItem.leftBarButtonItems = @[settings, posSpaceAdjust, editButton];
}

- (void)nowPlayingTapped
{
    
}
                                   
- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        //leaving editing mode now
        [super setEditing:NO animated:YES];
        for(UIBarButtonItem *abutton in self.navigationItem.rightBarButtonItems){
            [self makeBarButtonItemNormal:abutton];
        }
    }
    else
    {
        //entering editing mode now
        [super setEditing:YES animated:YES];
        for(UIBarButtonItem *abutton in self.navigationItem.rightBarButtonItems){
            [self makeBarButtonItemGrey: abutton];
        }
    }
}

- (UIBarButtonItem *)makeBarButtonItemGrey:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = false;
    return barButton;
}

- (UIBarButtonItem *)makeBarButtonItemNormal:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStyleBordered;
    barButton.enabled = true;
    return barButton;
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    if(_allSongsInLibrary.count > 0){
        //create search bar, add to viewController
        _searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        _searchBar.placeholder = @"Search Songs";
        _searchBar.keyboardType = UIKeyboardTypeASCIICapable;
        _searchBar.delegate = self;
        [self.searchBar sizeToFit];
        self.tableView.tableHeaderView = _searchBar;
    }
}

//User tapped the search box
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //show the cancel button
    [_searchBar setShowsCancelButton:YES animated:YES];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //search results already appear as the user types. Just hide the keyboard...
    [_searchBar resignFirstResponder];
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //dismiss search bar and hide cancel button
    [_searchBar setShowsCancelButton:NO animated:YES];
    [_searchBar resignFirstResponder];
    
    _searchResults = [NSMutableArray array];
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if(searchText.length == 0)
    {
        _displaySearchResults = NO;
    }
    else
    {
        _searchResults = [NSMutableArray array];
        _displaySearchResults = YES;
        for (Song* someSong in _allSongsInLibrary)  //iterate through all songs
        {
            NSRange nameRange = [someSong.songName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound)
            {
                [_searchResults addObject:someSong];
            }
            //would maybe like to filter by BEST result? This only captures results...
        }
    }
    [self.tableView reloadData];
}


#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //init tableView model
    _allSongsInLibrary = nil;
    _allSongsInLibrary = [NSMutableArray arrayWithArray:[Song loadAll]];
    
    [self setUpSearchBar];  //must be called in viewWillAppear, and after allSongsLibrary is refreshed
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft ||
       orientation == UIInterfaceOrientationLandscapeRight||
       orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
    
    [self.tableView reloadData];  //reset or update any now playing items
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.topItem.title = @"Songs";
    
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    stackController = [[StackController alloc] init];
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UITableView implementation
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_displaySearchResults)
        return _searchResults.count;  //user is searching and we need to show search results in table
    else
        return _allSongsInLibrary.count;  //user browsing library
}

static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];
    
    /**
    Song *song;
    // Configure the cell...
    if(_displaySearchResults)
        song = [_searchResults objectAtIndex:indexPath.row];
    else
        song = [_allSongsInLibrary objectAtIndex: indexPath.row];
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    if([[PlaybackModelSingleton createSingleton].nowPlayingSong isEqual:song])
        cell.textLabel.textColor = [UIColor defaultSystemTintColor];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    CGSize size = CGSizeMake(cell.frame.size.height,cell.frame.size.height);
    [cell.imageView sd_setImageWithURL:[AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]
                      placeholderImage:[UIImage imageWithColor:[UIColor clearColor] width:size.width height:size.height]
                               options:SDWebImageCacheMemoryOnly
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                 cell.imageView.image = image;
                             }];
    
     */
    //---------------------------------------
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SongItemCell"];
    else
    {
        // If an existing cell is being reused, reset the image to the default until it is populated.
        // Without this code, previous images are displayed against the new people during rapid scrolling.
        cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor] width:cell.frame.size.height height:cell.frame.size.height];
    }
    
    // Set up other aspects of the cell content.
    Song *song;
    if(_displaySearchResults)
        song = [_searchResults objectAtIndex:indexPath.row];
    else
        song = [_allSongsInLibrary objectAtIndex: indexPath.row];
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    if([[PlaybackModelSingleton createSingleton].nowPlayingSong isEqual:song])
        cell.textLabel.textColor = [UIColor defaultSystemTintColor];
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
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:[AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]]];
        albumArt = [AlbumArtUtilities imageWithImage:albumArt scaledToSize:CGSizeMake(cell.frame.size.height, cell.frame.size.height)];
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                cell.imageView.image = albumArt;
            }
        });
    }];
    //--------------------------------------------------------------
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
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
        //obtain object for the deleted song
        Song *song = [self.allSongsInLibrary objectAtIndex:indexPath.row];
        
        if([song isEqual:[PlaybackModelSingleton createSingleton].nowPlayingSong]){
            YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
            [[singleton AVPlayer] pause];
            [singleton setAVPlayerInstance:nil];
            [singleton setAVPlayerLayerInstance:nil];
        }
        
        //delete the object from our data model (which is saved to disk).
        [song deleteSong];
        
        //delete song from the tableview data source
        [[self allSongsInLibrary] removeObjectAtIndex:indexPath.row];
        
        if(_allSongsInLibrary.count == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedRowIndexValue = (int)indexPath.row;
    UIBarButtonItem *editButton = self.navigationItem.leftBarButtonItems[2];
    
    if([editButton.title isEqualToString:@"Edit"]){  //tapping song plays the song
        
        Song *selectedSong = [self.allSongsInLibrary objectAtIndex:indexPath.row];
        if([[PlaybackModelSingleton createSingleton].nowPlayingSong isEqual:selectedSong]){
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if([cell.textLabel.textColor isEqualToColor:[UIColor defaultSystemTintColor]])  //now playing song
                [YouTubeMoviePlayerSingleton setNeedsToDisplayNewVideo:NO];
            else
                [YouTubeMoviePlayerSingleton setNeedsToDisplayNewVideo:YES];
        }
        else{
            YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
            [[singleton AVPlayer] pause];
            [singleton setAVPlayerInstance:nil];
            [singleton setAVPlayerLayerInstance:nil];
            
            [YouTubeMoviePlayerSingleton setNeedsToDisplayNewVideo:YES];  //for loading the actual video player, not the other stuff...
        }

        [[PlaybackModelSingleton createSingleton] changeNowPlayingWithSong:selectedSong
                                                              fromAllSongs:self.allSongsInLibrary
                                                           indexOfNextSong:self.selectedRowIndexValue];
        [self performSegueWithIdentifier:@"songItemSegue" sender:nil];
        
    } else if([editButton.title isEqualToString:@"Done"]){  //tapping song triggers edit segue
        
        //now segue to modal view where user can edit the tapped song
        [self performSegueWithIdentifier:@"editingSongMasterSegue" sender:self];
    }
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"editingSongMasterSegue"]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingModeCompleted:) name:@"SongEditDone" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songWasSavedDuringEditing:) name:@"SongSavedDuringEdit" object:nil];
        
        //set the songIAmEditing property in the modal view controller
        MasterEditingSongTableViewController* controller = (MasterEditingSongTableViewController*)[[segue destinationViewController] topViewController];
        [controller setSongIAmEditing:[self.allSongsInLibrary objectAtIndex:self.selectedRowIndexValue]];
        self.indexOfEditingSong = self.selectedRowIndexValue;
    }
}

#pragma mark - song editing
- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"SongEditDone"]){
        //leave editing mode
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongEditDone" object:nil];
    }
}

- (void)songWasSavedDuringEditing:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"SongSavedDuringEdit"]){
        [self commitNewSongChanges:(Song *)notification.object];
    }
}

- (void)commitNewSongChanges:(Song *)changedSong
{
    if(changedSong){
        [changedSong updateExistingSong];
        
        self.allSongsInLibrary = [NSMutableArray arrayWithArray:[Song loadAll]];
        self.indexOfEditingSong = -1;
        if(_allSongsInLibrary.count == 0){ //dont need search bar anymore
            _searchBar = nil;
            self.tableView.tableHeaderView = nil;
        }
        
        [self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongSavedDuringEdit" object:nil];
    }
}

#pragma mark - Adding music to library
//called when + sign is tapped - selector defined in setUpNavBarItems method!
- (void)addButtonPressed
{
    [self performSegueWithIdentifier:@"addMusicToLibSegue" sender:nil];
}

#pragma mark - Go To Settings
- (void)settingsButtonTapped
{
    [self performSegueWithIdentifier:@"settingsSegue" sender:self];
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }else {
        // iOS 6 code only here...checking if we are now going into landscape mode
        if((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight))
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        else
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        [self setTabBarVisible:NO animated:NO];
        return YES;
    }
    else{
        [self setTabBarVisible:YES animated:NO];
        //fixes a bug when using another viewController with all these "hiding" nav bar features...and returning to this viewController
        self.tabBarController.tabBar.hidden = NO;
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
}

#pragma mark - Rotation tab bar methods
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

@end
