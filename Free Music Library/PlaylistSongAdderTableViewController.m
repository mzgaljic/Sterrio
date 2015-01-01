//
//  PlaylistSongItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistSongAdderTableViewController.h"
#define Done_String @"Done"
#define AddLater_String @"Add later"
#define Cancel_String @"Cancel"

@interface PlaylistSongAdderTableViewController()
@end

@implementation PlaylistSongAdderTableViewController
@synthesize songsSelected = _songsSelected, receiverPlaylist = _receiverPlaylist;
static BOOL PRODUCTION_MODE;

//playlist status codes
static const short IN_CREATION = 0;
static const short CREATED_BUT_EMPTY = 1;
static const short NORMAL_PLAYLIST = -1;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (id)initWithPlaylist:(Playlist *)aPlaylist
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PlaylistSongAdderTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"playlistSongAdderView"];
    self = vc;
    if (self) {
        //custom variables init here
        [self setReceiverPlaylistWithFetchUsingPlaylistID:aPlaylist.playlist_id];;
    }
    return self;
}

static BOOL lastSortOrder;
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(lastSortOrder != [AppEnvironmentConstants smartAlphabeticalSort])
    {
        [self setFetchedResultsControllerAndSortStyle];
        lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    }

    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight
       || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
    
    _songsSelected = [NSMutableArray array];
    
    //init tableView model
    if([_receiverPlaylist.status shortValue] == IN_CREATION){  //creating new playlist
        self.rightBarButton.title = AddLater_String;
    } else if([_receiverPlaylist.status shortValue] == NORMAL_PLAYLIST){  //adding songs to existing playlist
        //i disable songs in the existing playlist in cellForRowAtIndexpath
        self.rightBarButton.title = @"";
    } else if([_receiverPlaylist.status shortValue] == CREATED_BUT_EMPTY){  //possibly adding songs to existing playlist
        self.rightBarButton.title = @"";
        //i disable songs in the existing playlist in cellForRowAtIndexpath
    }
    [self.tableView reloadData];
    
    //needed to make UITableViewCellAccessoryCheckmark the nav bar color!
    self.tableView.tintColor = [UIColor defaultAppColorScheme];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
     lastSortOrder = [AppEnvironmentConstants smartAlphabeticalSort];
    
    [self setFetchedResultsControllerAndSortStyle];
    stackController = [[StackController alloc] init];
    
    [self setProductionModeValue];
    self.tableView.allowsMultipleSelection = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistSongItemPickerCell" forIndexPath:indexPath];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"playlistSongItemPickerCell"];
    else
    {
        // If an existing cell is being reused, reset the image to the default until it is populated.
        // Without this code, previous images are displayed against the new people during rapid scrolling.
        cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor] width:cell.frame.size.height height:cell.frame.size.height];
    }

    [cell setAccessoryType:UITableViewCellAccessoryNone];
    for(int i = 0; i < _songsSelected.count; i++){
        NSUInteger num = [[_songsSelected objectAtIndex:i] intValue];
        if(num == indexPath.row){
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            break;  //found the match
        }
    }
    
    // Set up other aspects of the cell content.
    Song *song;
    if(self.displaySearchResults)
        song = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.enabled = YES;
    cell.detailTextLabel.enabled = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    //check if we should disable this cell
    for(int i = 0; i < _receiverPlaylist.playlistSongs.count; i++)
    {
        if([song.song_id isEqualToString:[[_receiverPlaylist.playlistSongs objectAtIndex:i] song_id]])
        {
            cell.textLabel.enabled = NO;
            cell.detailTextLabel.enabled = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
    }
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
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

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    //prohibit checking cells that have been disabled on purpose (songs already in playlist)
    if(selectedCell.textLabel.enabled == NO)
        return;
    
    if([selectedCell accessoryType] == UITableViewCellAccessoryNone){  //selected row
        if(_songsSelected.count == 0){
             self.rightBarButton.title = Done_String;
            [self.rightBarButton setStyle:UIBarButtonItemStyleDone];
        }
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [_songsSelected addObject:[NSNumber numberWithInt:(int)indexPath.row]];
        
    } else{  //deselected row
        if(_songsSelected.count == 1 && [_receiverPlaylist.status shortValue] == IN_CREATION)
            self.rightBarButton.title = AddLater_String;  //only happens when playlist created from scratch
        
        else if(_songsSelected.count == 1 && [_receiverPlaylist.status shortValue] == CREATED_BUT_EMPTY)
            self.rightBarButton.title = @"";
        
        else if(_songsSelected.count == 1 && [_receiverPlaylist.status shortValue] == NORMAL_PLAYLIST)
            self.rightBarButton.title = @"";
        
        [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
        [_songsSelected removeObject:[NSNumber numberWithInt:(int)indexPath.row]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SongTableViewFormatter preferredSongCellHeight];
}

- (IBAction)rightBarButtonTapped:(id)sender
{
    [self setReceiverPlaylistWithFetchUsingPlaylistID:_receiverPlaylist.playlist_id];
    
    NSString *title = self.rightBarButton.title;
    Playlist *replacementPlaylist;
    if([title isEqualToString:Done_String]){
        
        NSMutableArray *newSongsArray = [NSMutableArray array];
        Song *song;
        int tappedSongRowNum;
        for(int i = 0; i < _songsSelected.count; i++)
        {
            //the selectedSongs array contains row numbers for all the chosen songs! I use that to get the needed songs.
            tappedSongRowNum = [[_songsSelected objectAtIndex:i] intValue];
            song = [self.fetchedResultsController objectAtIndexPath: [NSIndexPath indexPathForRow:tappedSongRowNum inSection:0]];
            [newSongsArray addObject:song];
        }
        NSArray *oldSongsArray = [_receiverPlaylist.playlistSongs array];
        NSMutableArray *finalArray = [NSMutableArray array];
        [finalArray addObjectsFromArray:oldSongsArray];
        [finalArray addObjectsFromArray:newSongsArray];

        replacementPlaylist = [Playlist createNewPlaylistWithName:_receiverPlaylist.playlistName
                                                                 usingSongs:finalArray inManagedContext:[CoreDataManager context]];
        replacementPlaylist.status = [NSNumber numberWithShort:NORMAL_PLAYLIST];
        [[CoreDataManager context] deleteObject:_receiverPlaylist];

    } else if([title isEqualToString:AddLater_String]){
        //leave playlist empty and "pop" this modal view off the screen
        _receiverPlaylist.status = [NSNumber numberWithShort:CREATED_BUT_EMPTY];
    }
    [[CoreDataManager sharedInstance] saveContext];  //save in core data
    [self.navigationController popViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"song picker dismissed" object:replacementPlaylist];
}

             
- (IBAction)leftBarButtonTapped:(id)sender
{
    NSString *title = self.leftBarButton.title;
    if([title isEqualToString:Cancel_String] && [_receiverPlaylist.status shortValue] == IN_CREATION){
        //cancel the creation of the playlist and "pop" this modal view off the screen.
        [[CoreDataManager context] deleteObject:_receiverPlaylist];
        [[CoreDataManager sharedInstance] saveContext];  //save in core data
    }
    //else we dont need to do anything
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"song picker dismissed" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - fetching and sorting
- (void)setFetchedResultsControllerAndSortStyle
{
    self.fetchedResultsController = nil;
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    request.predicate = nil;  //means i want all of the songs
    
    NSSortDescriptor *sortDescriptor;
    if([AppEnvironmentConstants smartAlphabeticalSort])
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    else
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

- (void)setReceiverPlaylistWithFetchUsingPlaylistID:(NSString *)playlistID
{
    //fetch for playlist (avoids some stupid context problem)
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
    request.predicate = [NSPredicate predicateWithFormat:@"playlist_id = %@",
                         playlistID];
    NSError *error;
    NSArray *matches = [[CoreDataManager context] executeFetchRequest:request error:&error];
    if(matches){
        if([matches count] == 1){
            _receiverPlaylist = [matches firstObject];
        } else if([matches count] > 1){
            //dismiss right away and try to avoid a crash.
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
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

@end
