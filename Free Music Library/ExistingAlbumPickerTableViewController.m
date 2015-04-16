//
//  ExistingAlbumPickerTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ExistingAlbumPickerTableViewController.h"

#import "StackController.h"
#import "CoreDataManager.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "Album.h"
#import "AlbumTableViewFormatter.h"
#import "UIImage+colorImages.h"
#import "MySearchBar.h"
#import "MGSwipeTableCell.h"
#import "MZTableViewCell.h"
#import <FXImageView/UIImage+FX.h>

@interface ExistingAlbumPickerTableViewController ()
@property (nonatomic, strong) MySearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Album *usersCurrentAlbum;
@end

@implementation ExistingAlbumPickerTableViewController

//using custom init here
- (id)initWithCurrentAlbum:(Album *)anAlbum
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ExistingAlbumPickerTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"browseExistingAlbumsVC"];
    self = vc;
    if (self) {
        //custom variables init here
        _usersCurrentAlbum = anAlbum;
    }
    return self;
}

#pragma mark - View Controller life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.emptyTableUserMessage = @"No Albums";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationController.navigationController.title = @"All Albums";
    
    [self setTableForCoreDataView:self.tableView];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.cellReuseId = @"existingAlbumCell";
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
    stackController = [[StackController alloc] init];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUpSearchBar];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //albums tab is never the first one on screen. no need to animate it
    if([self numberOfAlbumsInCoreDataModel] > 0){
        //create search bar, add to viewController
        _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0) placeholderText:@"Search My Music"];
        _searchBar.delegate = self;
        self.tableView.tableHeaderView = _searchBar;
    }
    [super setSearchBar:self.searchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchFetchedResultsController = nil;
    [self setFetchedResultsControllerAndSortStyle];
}

//User tapped the search box
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchFetchedResultsController = nil;
    self.fetchedResultsController = nil;
    
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
    [self setFetchedResultsControllerAndSortStyle];
    
    //dismiss search bar and hide cancel button
    [_searchBar setShowsCancelButton:NO animated:YES];
    [_searchBar resignFirstResponder];
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
#warning implementation incomplete
    if(searchText.length == 0)
    {
        self.displaySearchResults = NO;
    }
    else
    {
        self.displaySearchResults = YES;
        //now search through each song to find the query we need
        /**
         for (Song* someSong in _allSongsInLibrary)  //iterate through all songs
         {
         NSRange nameRange = [someSong.songName rangeOfString:searchText options:NSCaseInsensitiveSearch];
         if(nameRange.location != NSNotFound)
         {
         [_searchResults addObject:someSong];
         }
         //would maybe like to filter by BEST result? This only captures results...
         }
         */
    }
}


#pragma mark - Table view data source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Album *album;
    if(self.displaySearchResults)
        album = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        album = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
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
    
    
    cell.textLabel.attributedText = [AlbumTableViewFormatter formatAlbumLabelUsingAlbum:album];
    if(! [AlbumTableViewFormatter albumNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[AlbumTableViewFormatter nonBoldAlbumLabelFontSize]];
    [AlbumTableViewFormatter formatAlbumDetailLabelUsingAlbum:album andCell:&cell];
    
    BOOL isCurrentlySelectedAlbum = [_usersCurrentAlbum.album_id isEqualToString:album.album_id];
    
    if(isCurrentlySelectedAlbum){
        UIColor *appThemeSuperLight = [[[[[UIColor defaultAppColorScheme] lighterColor] lighterColor] lighterColor] lighterColor];
        cell.backgroundColor = appThemeSuperLight;
        [cell setUserInteractionEnabled:NO];
    } else{
        cell.backgroundColor = [UIColor clearColor];
        [cell setUserInteractionEnabled:YES];
    }
    
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
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:[AlbumArtUtilities albumArtFileNameToNSURL:album.albumArtFileName]]];
        
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
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AlbumTableViewFormatter preferredAlbumCellHeight];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Album *chosenAlbum;
    if(self.displaySearchResults)
        chosenAlbum = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    else
        chosenAlbum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //notifies MasterEditingSongTableViewController.m about the chosen album.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"existing album chosen" object:chosenAlbum];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setNeedsStatusBarAppearanceUpdate];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Counting Albums in core data
- (int)numberOfAlbumsInCoreDataModel
{
    //count how many instances there are of the Artist entity in core data
    NSManagedObjectContext *context = [CoreDataManager context];
    int count = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:context];
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
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    request.predicate = nil;  //means i want all of the albums
    
    NSSortDescriptor *sortDescriptor;
    if([AppEnvironmentConstants smartAlphabeticalSort])
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    else
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"albumName"
                                                       ascending:YES
                                                        selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];

    //fetchedResultsController is from custom super class
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

@end
