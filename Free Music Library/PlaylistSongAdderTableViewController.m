//
//  PlaylistSongItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistSongAdderTableViewController.h"

#import "Song.h"
#import "Playlist+Utilities.h"
#import "AppEnvironmentConstants.h"
#import "MasterSongsTableViewController.h"
#import "SDWebImageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AllSongsDataSource.h"

@interface PlaylistSongAdderTableViewController()
{
    CGRect originalTableViewFrame;
}
@property (nonatomic, strong) MySearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property AllSongsDataSource *tableViewDataSourceAndDelegate;
@end

@implementation PlaylistSongAdderTableViewController


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

#pragma mark - SearchBarDataSourceDelegate implementation
- (NSString *)placeholderTextForSearchBar
{
    return @"Search My Songs";
}

- (void)searchBarIsBecomingActive
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if(CGRectIsNull(originalTableViewFrame))
        originalTableViewFrame = self.tableView.frame;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.tableView.frame = CGRectMake(0,
                                                           0,
                                                           self.view.frame.size.width,
                                                           self.view.frame.size.height);
                     }
                     completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZMainScreenVCStatusBarAlwaysInvisible
                                                        object:[NSNumber numberWithBool:YES]];
}

- (void)searchBarIsBecomingInactive
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         CGRect viewFrame = self.view.frame;
                         self.tableView.frame = CGRectMake(originalTableViewFrame.origin.x,
                                                           originalTableViewFrame.origin.y,
                                                           viewFrame.size.width,
                                                           viewFrame.size.height);
                     }
                     completion:^(BOOL finished) {
                         originalTableViewFrame = CGRectNull;
                     }];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZMainScreenVCStatusBarAlwaysInvisible
                                                        object:[NSNumber numberWithBool:NO]];
}


#pragma mark - Miscellaneous
- (void)establishTableViewDataSource
{
    self.tableViewDataSourceAndDelegate = [[AllSongsDataSource alloc] initWithSongDataSourceType:SONG_DATA_SRC_TYPE_Playlist_MultiSelect
                                                                     searchBarDataSourceDelegate:self];
    self.tableViewDataSourceAndDelegate.fetchedResultsController = self.fetchedResultsController;
    self.tableViewDataSourceAndDelegate.tableView = self.tableView;
    self.tableViewDataSourceAndDelegate.cellReuseId = @"playlistSongItemPickerCell";
    self.tableViewDataSourceAndDelegate.playlistSongAdderDelegate = self;
    self.tableViewDataSourceAndDelegate.emptyTableUserMessage = @"No Songs";
    self.tableView.dataSource = self.tableViewDataSourceAndDelegate;
    self.tableView.delegate = self.tableViewDataSourceAndDelegate;
}

#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    //order of calls matters here...
    self.searchBar = [self.tableViewDataSourceAndDelegate setUpSearchBar];
    [super setSearchBar:self.searchBar];
    [super viewWillAppear:animated];
    
    switch ([_receiverPlaylist.status shortValue])
    {
        case PLAYLIST_STATUS_In_Creation:  //creating new playlist
        {
            self.rightBarButton.title = AddLater_String;
            break;
        }
        case PLAYLIST_STATUS_Normal_Playlist:  //adding songs to existing playlist
        case PLAYLIST_STATUS_Created_But_Empty:  //possibly adding songs to existing playlist
            self.rightBarButton.title = @"";
            break;
            
        default:
            break;
    }
    
    //needed to make UITableViewCellAccessoryCheckmark the nav bar color!
    self.tableView.tintColor = [UIColor defaultAppColorScheme];
    [self.rightBarButton setStyle:UIBarButtonItemStyleDone];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    originalTableViewFrame = CGRectNull;
    [self setTableForCoreDataView:self.tableView];
    [self initFetchResultsController];
    [self establishTableViewDataSource];
    
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //need to check because when user presses back button, tab bar isnt always hidden
    [self prefersStatusBarHidden];
}

- (void)dealloc
{
    [super prepareFetchedResultsControllerForDealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - PlaylistSongAdderDataSourceDelegate protocol implementation
- (void)setSuccessNavBarButtonStringValue:(NSString *)newValue
{
    self.rightBarButton.title = newValue;
}

- (PLAYLIST_STATUS)currentPlaylistStatus
{
    return [_receiverPlaylist.status shortValue];
}

- (NSOrderedSet *)existingPlaylistSongs
{
    return _receiverPlaylist.playlistSongs;
}

#pragma mark - User button actions
- (IBAction)rightBarButtonTapped:(id)sender
{
    [self setReceiverPlaylistWithFetchUsingPlaylistID:_receiverPlaylist.playlist_id];
    
    NSString *title = self.rightBarButton.title;
    Playlist *replacementPlaylist;
    if([title isEqualToString:Done_String]){
        
        NSArray *newSongsArray = [self.tableViewDataSourceAndDelegate minimallyFaultedArrayOfSelectedPlaylistSongs];
        NSArray *oldSongsArray = [_receiverPlaylist.playlistSongs array];
        NSMutableArray *finalArray = [NSMutableArray arrayWithCapacity:newSongsArray.count + oldSongsArray.count];
        [finalArray addObjectsFromArray:oldSongsArray];
        [finalArray addObjectsFromArray:newSongsArray];
        NSString *originalPlaylistId = _receiverPlaylist.playlist_id;
        
        //not all songs are saved as a set. hence i dont need to worry about duplicated (nor is it possible to save duplicates)
        replacementPlaylist = [Playlist createNewPlaylistWithName:_receiverPlaylist.playlistName
                                                                 usingSongs:finalArray inManagedContext:[CoreDataManager context]];
        replacementPlaylist.status = [NSNumber numberWithShort:PLAYLIST_STATUS_Normal_Playlist];
        [[CoreDataManager context] deleteObject:_receiverPlaylist];
        [[CoreDataManager sharedInstance] saveContext];
        replacementPlaylist.playlist_id = originalPlaylistId;

    } else if([title isEqualToString:AddLater_String]){
        //leave playlist empty and "pop" this modal view off the screen
        _receiverPlaylist.status = [NSNumber numberWithShort:PLAYLIST_STATUS_Created_But_Empty];
    }
    [[CoreDataManager sharedInstance] saveContext];  //save in core data
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"song picker dismissed" object:replacementPlaylist];
}

             
- (IBAction)leftBarButtonTapped:(id)sender
{
    NSString *title = self.leftBarButton.title;
    if([title isEqualToString:Cancel_String] && [_receiverPlaylist.status shortValue] == PLAYLIST_STATUS_In_Creation){
        //cancel the creation of the playlist and "pop" this modal view off the screen.
        [[CoreDataManager context] deleteObject:_receiverPlaylist];
        [[CoreDataManager sharedInstance] saveContext];  //save in core data
    }
    //else we dont need to do anything
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"song picker dismissed" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setNeedsStatusBarAppearanceUpdate];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    if(_tableViewDataSourceAndDelegate.displaySearchResults)
        return YES;
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        return YES;
    else
        return NO;
}

#pragma mark - fetching and sorting
- (void)initFetchResultsController
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
    //no playback context set here since its impossible to select songs for playback in this VC.
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

@end
