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
    //edit button
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    //+ sign...also wire it up to the ibAction "addButtonPressed"
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  target:self action:@selector(addButtonPressed)];
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;  //place both buttons on the nav bar
}

- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        //leaving editing mode now
        [super setEditing:NO animated:YES];
        [self makeBarButtonItemNormal:[self.navigationItem.rightBarButtonItems objectAtIndex:1]];
    }
    else
    {
        //entering editing mode now
        [super setEditing:YES animated:YES];
        [self makeBarButtonItemGrey:[self.navigationItem.rightBarButtonItems objectAtIndex:1]];
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
    //create search bar, add to viewController
    _searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
    _searchBar.placeholder = @"Search Songs";
    _searchBar.keyboardType = UIKeyboardTypeASCIICapable;
    _searchBar.delegate = self;
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = _searchBar;
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
    //assuming we only show song results instead of whole library?
    
    //sample code
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
          //NSRange descriptionRange = [food.description rangeOfString:text options:NSCaseInsensitiveSearch];
        //if(nameRange.location != NSNotFound || descriptionRange.location != NSNotFound)
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
    
    //hide search bar
    [self.tableView setContentOffset:CGPointMake(0, -16)];
    
    //init tableView model
    _allSongsInLibrary = [NSMutableArray arrayWithArray:[Song loadAll]];
    [self.tableView reloadData];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft ||
       orientation == UIInterfaceOrientationLandscapeRight||
       orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
    
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
    self.tableView.allowsSelectionDuringEditing = YES;
    
    [self setUpSearchBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];
    
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
    
    
    //if the songs tab loading of images is laggy, just go back to the 'standard way', which is the code in the albums tab.
    UIImage *image;
    if(PRODUCTION_MODE){
        CGSize size = [SongTableViewFormatter preferredSongAlbumArtSize];
        [cell.imageView sd_setImageWithURL:[AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]
                                placeholderImage:[UIImage imageWithColor:[UIColor clearColor] width:size.width height:size.height]
                                         options:SDWebImageCacheMemoryOnly
                                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                     image = [AlbumArtUtilities imageWithImage:image scaledToSize:size];
                                           cell.imageView.image = image;
                                 }];
    }
    else{
        image = [UIImage imageNamed:song.album.albumName];
        image = [AlbumArtUtilities imageWithImage:image scaledToSize:[SongTableViewFormatter preferredSongAlbumArtSize]];
        cell.imageView.image = image;

    }
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
        
        //delete the object from our data model (which is saved to disk).
        [song deleteSong];
        
        //delete song from the tableview data source
        [[self allSongsInLibrary] removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //get song for the tapped row
    self.selectedRowIndexValue = (int)indexPath.row;
    UIBarButtonItem *editButton = self.navigationItem.rightBarButtonItem;
    
    if([editButton.title isEqualToString:@"Edit"]){  //tapping song plays the song
       [self performSegueWithIdentifier:@"songItemSegue" sender:self];
        
    } else if([editButton.title isEqualToString:@"Done"]){  //tapping song triggers edit segue
        
        //now segue to modal view where user can edit the tapped song
        [self performSegueWithIdentifier:@"editingSongMasterSegue" sender:self];
    }
}

#pragma mark - segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //song was tapped
    if([[segue identifier] isEqualToString: @"songItemSegue"]){
        //retrieve the song objects
        Song *selectedSong = [self.allSongsInLibrary objectAtIndex:self.selectedRowIndexValue];
        Album *selectedAlbum = selectedSong.album;
        Artist *selectedArtist = selectedSong.artist;
        Playlist *selectedPlaylist;
        
        //setup properties in SongItemViewController.h
        [[segue destinationViewController] setANewSong:selectedSong];
        [[segue destinationViewController] setANewAlbum:selectedAlbum];
        [[segue destinationViewController] setANewArtist:selectedArtist];
        [[segue destinationViewController] setANewPlaylist:selectedPlaylist];
        
        int songNumber = self.selectedRowIndexValue + 1;  //remember, for loop started at 0!
        if(songNumber < 0 || songNumber == 0)  //object not found in song model
            songNumber = -1;
        [[segue destinationViewController] setSongNumberInSongCollection:songNumber];
        [[segue destinationViewController] setTotalSongsInCollection:(int)self.allSongsInLibrary.count];
    } else if([[segue identifier] isEqualToString:@"editingSongMasterSegue"]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingModeCompleted:) name:@"SongEditDone" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songWasSavedDuringEditing:) name:@"SongSavedDuringEdit" object:nil];
        
        //set the songIAmEditing property in the modal view controller
        MasterEditingSongTableViewController* controller = (MasterEditingSongTableViewController*)[[segue destinationViewController] topViewController];
        [controller setSongIAmEditing:[self.allSongsInLibrary objectAtIndex:self.selectedRowIndexValue]];
        self.indexOfEditingSong = self.selectedRowIndexValue;
    }
    else if([[segue identifier] isEqualToString: @"settingsSegue"]){  //settings button tapped from side bar
        //do i need this?
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
        [self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongSavedDuringEdit" object:nil];
    }
}

#pragma mark - Side menu
- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index
{
   if (1){
        [sidebar dismissAnimated:YES];
       if(index == 3)  //settings button
           [self performSegueWithIdentifier:@"settingsSegue" sender:self];
   }
}

- (IBAction)expandableMenuSelected:(id)sender
{
    [FrostedSideBarHelper setupAndShowSlideOutMenuUsingdelegate:self];
}

#pragma mark - Adding msuic to library
//called when + sign is tapped - selector defined in setUpNavBarItems method!
- (void)addButtonPressed
{
    [self performSegueWithIdentifier:@"addMusicToLibSegue" sender:nil];
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
