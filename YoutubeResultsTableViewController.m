//
//  YoutubeResultsTableViewController.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YoutubeResultsTableViewController.h"

#import "YouTubeVideoSearchService.h"
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import "MRProgress.h"
#import "AlbumArtUtilities.h"
#import "SDCAlertView.h"
#import "PreferredFontSizeUtility.h"
#import "YouTubeSongAdderViewController.h"
#import "CustomYoutubeTableViewCell.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@interface YoutubeResultsTableViewController ()
{
    UIActivityIndicatorView *loadingMoreResultsSpinner;
}
@property (nonatomic, strong) MySearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *searchSuggestions;
@property (nonatomic, assign) BOOL displaySearchResults;
@property (nonatomic, assign) BOOL searchInitiatedAlready;
@property (nonatomic, assign) BOOL activityIndicatorOnScreen;
@property (nonatomic, strong) NSString *lastSuccessfullSearchString;
@property (nonatomic, strong) NSMutableArray *lastSuccessfullSuggestions;
@property (nonatomic, assign) float heightOfScreenRotationIndependant;
//view isn't actually on top of tableView, but it looks like it. Call "turnTableViewIntoUIView" prior to setting this value!
@property (nonatomic, strong) UIView *viewOnTopOfTable;
@property (nonatomic, strong) UIView *progressViewHere;

@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *scrollToTopButton;
@property (nonatomic, assign) BOOL scrollToTopButtonVisible;
@property (nonatomic, assign) BOOL networkErrorLoadingMoreResults;
@property (nonatomic, assign) BOOL noMoreResultsToDisplay;
@property (nonatomic, assign) BOOL waitingOnNextPageResults;
@end

@implementation YoutubeResultsTableViewController
static BOOL PRODUCTION_MODE;
static const float MINIMUM_DURATION_OF_LOADING_POPUP = 1.0;
static NSString *Network_Error_Loading_More_Results_Msg = @"Network error, tap to try again";
static NSString *No_More_Results_To_Display_Msg = @"No more results";

//custom setters
- (void)setDisplaySearchResults:(BOOL)displaySearchResults
{
    _displaySearchResults = displaySearchResults;
}

#pragma mark - Miscellaneous
- (void)dealloc
{
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([YoutubeResultsTableViewController class]));
}

- (void)myPreDealloc
{
    _searchBar.delegate = nil;
    loadingMoreResultsSpinner = nil;
    _searchBar = nil;
    _searchResults = nil;
    _searchSuggestions = nil;
    _lastSuccessfullSuggestions = nil;
    _cancelButton = nil;
    _scrollToTopButton = nil;
    _viewOnTopOfTable = nil;
    _lastSuccessfullSearchString = nil;
    _viewOnTopOfTable = nil;
    start = nil;
    finish = nil;
    [[YouTubeVideoSearchService sharedInstance] removeVideoQueryDelegate];
    
    [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerCanIgnoreToolbar];
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)makeBarButtonGrey:(UIBarButtonItem *)barButton yes:(BOOL)show
{
    if (show) {
        barButton.style = UIBarButtonItemStylePlain;
        barButton.enabled = true;
    } else {
        barButton.style = UIBarButtonItemStylePlain;
        barButton.enabled = false;
        barButton.title = nil;
    }
}

#pragma mark - Toolbar button handling code
- (void)cancelTapped
{
    [self myPreDealloc];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollToTopTapped
{
    [self.tableView setContentOffset:(self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top)) animated:YES];
}

#pragma mark - View Controller life cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[YouTubeVideoSearchService sharedInstance] setVideoQueryDelegate:self];
    self.navigationController.toolbarHidden = NO;
    if (self.isMovingToParentViewController == NO)
    {
        // we're already on the navigation stack, another controller must have been popped off.
        self.displaySearchResults = YES;
        self.tableView.scrollEnabled = YES;
        //restore scroll to top button if it was there before segue
        if(_scrollToTopButtonVisible)
            [self showScrollToTopButton:YES];
        if([MusicPlaybackController nowPlayingSong])
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    
    if(self.displaySearchResults)
        _navBar.title = @"Search Results";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _searchSuggestions = [NSMutableArray array];
    _searchResults = [NSMutableArray array];
    _lastSuccessfullSuggestions = [NSMutableArray array];
    
    self.navigationController.toolbarHidden = NO;
    _navBar.title = @"Adding Music";
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self
                                                                  action:@selector(cancelTapped)];
    [self setToolbarItems:@[_cancelButton]];
    [self setProductionModeValue];
    
    [self setUpSearchBar];
    
    //for scrolling method
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a > b)
        _heightOfScreenRotationIndependant = a;
    else
        _heightOfScreenRotationIndependant = b;
    [_searchBar becomeFirstResponder];
    
    [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerShouldRespectToolbar];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(!self.displaySearchResults)
        self.tableView.scrollEnabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - rotation methods
//i use these two methods to make sure the toolbar is always 'up to date' after rotation
- (void)orientationChanged:(NSNotification *)notification
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(updateToolbarAFterRotation)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)updateToolbarAFterRotation
{
    
    if(_scrollToTopButtonVisible)
        [self showScrollToTopButton:YES];
    else
        [self showScrollToTopButton:NO];
}

#pragma mark - YouTubeVideoSearchDelegate implementation
//searching for keyword on youtube finished and we have the results
- (void)ytVideoSearchDidCompleteWithResults:(NSArray *)youTubeVideoObjects
{
    self.searchInitiatedAlready = YES;
    
    // dismiss loading popup if enough time has passed
    NSTimeInterval executionTime = [self timeOnExecutionTimer];
    NSTimeInterval additionalDelay;
    if(executionTime < MINIMUM_DURATION_OF_LOADING_POPUP && executionTime != 0){
        additionalDelay = (MINIMUM_DURATION_OF_LOADING_POPUP - executionTime);
        [self performSelector:@selector(ytVideoSearchDidCompleteWithResults:) withObject:youTubeVideoObjects afterDelay:additionalDelay];
        youTubeVideoObjects = nil;
        return;
    }
    
    [_searchResults removeAllObjects];
    [_searchResults addObjectsFromArray:youTubeVideoObjects];
    youTubeVideoObjects = nil;
    
    [MRProgressOverlayView dismissOverlayForView:_viewOnTopOfTable animated:YES];
    if(_searchResults.count == 0){  //special case
        //display alert saying no results found
        
        [MRProgressOverlayView dismissOverlayForView:_viewOnTopOfTable animated:YES];
        [self launchAlertViewWithDialogTitle:@"No Search Results Found" andMessage:nil];
        [_searchBar setText:@""];
    }else
        [self turnTableViewIntoUIView:NO];
    [_searchBar setText:_lastSuccessfullSearchString];
    [self.tableView reloadData];
}

//"loading more" results for the current search has completed, and we got the additional results
- (void)ytVideoNextPageResultsDidCompleteWithResults:(NSArray *)moreYouTubeVideoObjects
{
    self.searchInitiatedAlready = YES;
    self.waitingOnNextPageResults = NO;
    NSUInteger count = _searchResults.count;
    NSUInteger moreResultsCount = moreYouTubeVideoObjects.count;
    
    if (moreResultsCount){
        [_searchResults addObjectsFromArray:moreYouTubeVideoObjects];
        
        NSMutableArray *insertIndexPaths = [NSMutableArray array];
        for (NSUInteger item = count; item < count + moreResultsCount; item++)
            [insertIndexPaths addObject:[NSIndexPath indexPathForRow:item inSection:0]];
        
        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
        
        // construct index path of original last cell in first section (before new results insertion)
        NSIndexPath *pathToOriginalLastRow = [NSIndexPath indexPathForRow:count -1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:pathToOriginalLastRow atScrollPosition:UITableViewScrollPositionNone animated:YES];
        
        NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
        if (selected)
            [self.tableView deselectRowAtIndexPath:selected animated:YES];
    }
    moreYouTubeVideoObjects = nil;
    
    _networkErrorLoadingMoreResults = NO;
    [loadingMoreResultsSpinner stopAnimating];
}

- (void)ytvideoResultsNoMorePagesToView
{
    self.searchInitiatedAlready = YES;
    self.waitingOnNextPageResults = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
    //change "Load More" button
    loadMoreCell.textLabel.text = No_More_Results_To_Display_Msg;
    [loadingMoreResultsSpinner stopAnimating];
    _noMoreResultsToDisplay = YES;
}

- (void)ytVideoAutoCompleteResultsDidDownload:(NSArray *)arrayOfNSStrings
{
    //only going to use 5 of the 10 results returned. 10 is too much (searchSuggestions array is already empty-emptied in search bar text did change)
    int searchSuggestionsCountBefore = _searchSuggestions.count;
    [_searchSuggestions removeAllObjects];
    [_lastSuccessfullSuggestions removeAllObjects];
    
    int upperBound = -1;
    if(arrayOfNSStrings.count >= 5)
        upperBound = 5;
    else
        upperBound = (int)arrayOfNSStrings.count;
    
    for(int i = 0; i < upperBound; i++){
        [_searchSuggestions addObject:[arrayOfNSStrings[i] copy]];
        [_lastSuccessfullSuggestions addObject:[arrayOfNSStrings[i] copy]];
    }
    arrayOfNSStrings = nil;
    
    if(upperBound != searchSuggestionsCountBefore){
        //animate the change in number of rows
        
        NSMutableArray *oldPaths = [NSMutableArray array];
        for(int i = 0; i < searchSuggestionsCountBefore; i++){
            [oldPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        NSMutableArray *newPaths = [NSMutableArray array];
        for(int i = 0; i < upperBound; i++){
            [newPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:oldPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView insertRowsAtIndexPaths:newPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
        [self.tableView reloadData];
}

- (void)networkErrorHasOccuredSearchingYoutube
{
    // dismiss loading popup if enough time has passed
    NSTimeInterval executionTime = [self timeOnExecutionTimer];
    NSTimeInterval additionalDelay;
    if(executionTime < MINIMUM_DURATION_OF_LOADING_POPUP && executionTime != 0){
        additionalDelay = ((MINIMUM_DURATION_OF_LOADING_POPUP - 0.6) - executionTime);
        [self performSelector:@selector(networkErrorHasOccuredSearchingYoutube) withObject:nil afterDelay:additionalDelay];
        return;
    }

    [MRProgressOverlayView dismissOverlayForView:_viewOnTopOfTable animated:YES];
    [self launchAlertViewWithDialogTitle:@"Network Problem" andMessage:@"Cannot establish connection with YouTube."];
    self.searchInitiatedAlready = NO;
}

- (void)networkErrorHasOccuredFetchingMorePages
{
    self.waitingOnNextPageResults = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
    //change "Load More" button
    loadMoreCell.textLabel.text = Network_Error_Loading_More_Results_Msg;
    loadMoreCell.textLabel.font = [UIFont systemFontOfSize:19];
    loadMoreCell.textLabel.textColor = [UIColor redColor];
    [loadingMoreResultsSpinner stopAnimating];
    _networkErrorLoadingMoreResults = YES;
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialogTitle:(NSString *)title andMessage:(NSString *)message
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

- (void)alertView:(SDCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0){  //hide loading popup behind the uialertView
        [self turnTableViewIntoUIView:NO];
        self.displaySearchResults = NO;
    
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //create search bar, add to viewController
    _searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)
                                    placeholderText:@"Search YouTube"];
    _searchBar.delegate = self;
    self.tableView.tableHeaderView = _searchBar;
}

//User tapped the search box textField
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if(searchBar.text.length == 0)
        self.tableView.scrollEnabled = NO;
    
    //show the cancel button
    self.displaySearchResults = NO;
    _navBar.title = @"Adding Music";
    [_searchBar setShowsCancelButton:YES animated:YES];

    if(self.searchInitiatedAlready){
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:YES];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
        [self.tableView endUpdates];
    }
    else
        [self.tableView reloadData];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.displaySearchResults = YES;
    self.tableView.scrollEnabled = YES;
    _lastSuccessfullSearchString = searchBar.text;
    //setting it both ways, do to nav bar title bug
    self.navigationController.navigationBar.topItem.title = @"Search Results";
    _navBar.title = @"Search Results";
    [_searchBar resignFirstResponder];
    
    //show loading popup above tableview before content loads
    [self turnTableViewIntoUIView:YES];
    [MRProgressOverlayView showOverlayAddedTo:_progressViewHere animated:YES];
    [self startTimingExecution];
    
    [[YouTubeVideoSearchService sharedInstance] searchYouTubeForVideosUsingString: searchBar.text];
    _noMoreResultsToDisplay = NO;
    _networkErrorLoadingMoreResults = NO;
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if(! self.searchInitiatedAlready){
        [self myPreDealloc];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        //setting it both ways, due to nav bar title bug
        self.navigationController.navigationBar.topItem.title = @"Search Results";
        _navBar.title = @"Search Results";
        
        //restore state of search bar and table before uncommited search bar edit began
        [_searchBar setText:_lastSuccessfullSearchString];
        if(userClearedTextField)
            [_searchSuggestions addObjectsFromArray:_lastSuccessfullSuggestions];
        userClearedTextField = NO;
        
        if(self.displaySearchResults == NO && _searchResults.count > 0){  //bring user back to previous results
            //restore state of search bar before uncommited search bar edit began
            [_searchBar setText:_lastSuccessfullSearchString];
            
            //[_searchSuggestions removeAllObjects];
            
            [_searchBar resignFirstResponder];
            self.displaySearchResults = YES;
            self.tableView.scrollEnabled = YES;
            
            //dismiss search bar and hide cancel button
            [_searchBar setShowsCancelButton:NO animated:YES];
            [_searchBar resignFirstResponder];
            
            [self.tableView beginUpdates];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:YES];
            [self.tableView endUpdates];
            return;
        }
        
        //dismiss search bar and hide cancel button
        [_searchBar setShowsCancelButton:NO animated:YES];
        [_searchBar resignFirstResponder];
        
        userClearedTextField = NO;
    }
}

static BOOL userClearedTextField = NO;
//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if(searchText.length != 0){
        if(! self.displaySearchResults)
            self.tableView.scrollEnabled = YES;
        
        //fetch auto suggestions
        [[YouTubeVideoSearchService sharedInstance] fetchYouTubeAutoCompleteResultsForString:searchText];
        self.displaySearchResults = NO;
    }
    
    else{  //user cleared the textField
        userClearedTextField = YES;
        if(! self.displaySearchResults)
            self.tableView.scrollEnabled = NO;
        
        int numSearchSuggestions = (int)_searchSuggestions.count;
        
        if([searchBar isFirstResponder])  //keyboard on screen
            [_searchSuggestions removeAllObjects];
        else{
            [searchBar becomeFirstResponder];  //bring up keyboard
            [_searchSuggestions removeAllObjects];
        }
        self.displaySearchResults = NO;
        
        NSMutableArray *paths = [NSMutableArray array];
        for(int i = 0; i < numSearchSuggestions; i++)
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

#pragma mark - TableView deleagte
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.displaySearchResults)
        return 2;  //this one has a "load more" button
    else
        return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(! self.displaySearchResults){  //showing autocomplete.
        //want to hide the header in landscape
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if(orientation != UIInterfaceOrientationPortrait)
            return 0;
        else
            return 38.0f;
    }
    else{
        if(section == 0)  //dont want a gap betweent table and search bar
            return 1.0f;
        else
            return 14.0f;  //"Load More" cell is in section 1
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(! self.displaySearchResults){
        if(section == 0 && _searchSuggestions.count > 0){
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            if(orientation != UIInterfaceOrientationPortrait)
                return @"";
            else
                return @"Top Hits";
        }
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(self.displaySearchResults){
        if(section == 0){
            return [NSString stringWithFormat:@"Displaying %i results", (int)_searchResults.count];
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.displaySearchResults){
        if(section == 0)
            return _searchResults.count;  //number of videos in results
        else if(section == 1)  //"Load more" cell
            return 1;
        else
            return -1;
    }else{
        //user has not pressed "search" yet, only showing autosuggestions
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if(orientation != UIInterfaceOrientationPortrait)
            return _searchSuggestions.count - 1;
        else
            return _searchSuggestions.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    // Configure the cell...
    YouTubeVideo *ytVideo;
    
    if(self.displaySearchResults){  //video search results will populate the table
        if(indexPath.section == 0){
            ytVideo = [_searchResults objectAtIndex:indexPath.row];
            
            CustomYoutubeTableViewCell *customCell;
            customCell = [tableView dequeueReusableCellWithIdentifier:@"youtubeResultCell" forIndexPath:indexPath];
            customCell.videoTitle.text = ytVideo.videoName;
            customCell.videoChannel.font = [UIFont systemFontOfSize:14];
            customCell.videoChannel.textColor = [UIColor grayColor];
            customCell.videoChannel.text = ytVideo.channelTitle;
            
            // If an existing cell is being reused, reset the image to the default until it is populated.
            // Without this code, previous images are displayed against the new cells during rapid scrolling.
            customCell.videoThumbnail.image = nil;
            customCell.videoThumbnail.image = [UIImage imageWithColor:[UIColor clearColor]
                                                           width:customCell.videoThumbnail.frame.size.width
                                                          height:customCell.videoThumbnail.frame.size.height];
            
            // now download the true thumbnail image asynchronously
            __weak NSString *weakVideoURL = ytVideo.videoThumbnailUrl;
            [self downloadImageWithURL:[NSURL URLWithString:weakVideoURL] completionBlock:^(BOOL succeeded, UIImage *image)
            {
                if (succeeded) {
                    // change the image in the cell
                    customCell.videoThumbnail.image = nil;
                    [UIView transitionWithView:customCell.videoThumbnail
                                      duration:MZCellImageViewFadeDuration
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        customCell.videoThumbnail.image = image;
                                    } completion:nil];
                }
            }];
            ytVideo = nil;
            customCell.accessoryType = UITableViewCellAccessoryNone;
            return customCell;
            
        } else if(indexPath.section == 1){  //the "load more" button is in this section
            if(indexPath.row == 0){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"loadMoreButtonCell"];
                cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                if(_networkErrorLoadingMoreResults){
                    cell.textLabel.text = Network_Error_Loading_More_Results_Msg;
                    cell.textLabel.textColor = [UIColor redColor];
                }
                else if(_noMoreResultsToDisplay){
                    cell.textLabel.text = No_More_Results_To_Display_Msg;
                    cell.textLabel.textColor = [UIColor blackColor];
                } else if(self.waitingOnNextPageResults){
                    
                    loadingMoreResultsSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    UIView *contentView = cell.contentView;
                    loadingMoreResultsSpinner.center = cell.center;
                    
                    [contentView addSubview:loadingMoreResultsSpinner];
                    [loadingMoreResultsSpinner startAnimating];
                }
            }
        }
    }else{  //auto suggestions will populate the table
        cell = [tableView dequeueReusableCellWithIdentifier:@"youtubeSuggsestCell" forIndexPath:indexPath];
        cell.textLabel.text = [_searchSuggestions objectAtIndex:indexPath.row];
        cell.imageView.image = nil;
    }
    ytVideo = nil;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(! self.displaySearchResults)
        return 45;
    else{
        if(indexPath.section == 0){
            //show portrait player
            float widthOfScreenRoationIndependant;
            float heightOfScreenRotationIndependant;
            float  a = [[UIScreen mainScreen] bounds].size.height;
            float b = [[UIScreen mainScreen] bounds].size.width;
            if(a < b)
            {
                heightOfScreenRotationIndependant = b;
                widthOfScreenRoationIndependant = a;
            }
            else
            {
                widthOfScreenRoationIndependant = b;
                heightOfScreenRotationIndependant = a;
            }
            
            int oneThirdDisplayWidth = widthOfScreenRoationIndependant * 0.45;
            int height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:oneThirdDisplayWidth];
            return height + 8;
        }
        else
            return 70.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(self.displaySearchResults){  //video search results in table
        if(indexPath.section == 0){
            YouTubeVideo *ytVideo = [_searchResults objectAtIndex:indexPath.row];
            CustomYoutubeTableViewCell *cell;
            cell = (CustomYoutubeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            UIImage *img = [UIImage imageWithCGImage:cell.videoThumbnail.image.CGImage];
            [self.navigationController pushViewController:[[YouTubeSongAdderViewController alloc] initWithYouTubeVideo:ytVideo thumbnail:img] animated:YES];
            
        }
    }
    else{  //auto suggestions in table
        int index = (int)indexPath.row;
        NSString *chosenSuggestion = _searchSuggestions[index];
        
        if(chosenSuggestion.length != 0){
            [_searchBar setText:chosenSuggestion];
            [self searchBarSearchButtonClicked:_searchBar];
        }
    }
}

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}


#pragma mark - TableView custom view toggler/creator
- (void)turnTableViewIntoUIView:(BOOL)yes
{
    if(yes){
        self.tableView.scrollEnabled = NO;
        self.tableView.tableHeaderView = nil;
        int navBarHeight = self.navigationController.navigationBar.frame.size.height;
        short statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        int offset = navBarHeight + statusBarHeight;
        _viewOnTopOfTable = [[UIView alloc] initWithFrame:self.tableView.frame];
        _progressViewHere = [[UIView alloc] initWithFrame:
                                    CGRectMake(0, -offset, _viewOnTopOfTable.frame.size.width, _viewOnTopOfTable.frame.size.height)];
        [_viewOnTopOfTable addSubview:_progressViewHere];
        self.tableView.tableHeaderView = _viewOnTopOfTable;
    } else{
        self.tableView.scrollEnabled = YES;
        self.tableView.tableHeaderView = nil;
        _progressViewHere = nil;
        _viewOnTopOfTable = nil;
        [self setUpSearchBar];
    }
}

#pragma mark - Scrolling methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isViewLoaded && self.view.window){
        //viewController is visible on screen (dont want pushed viewcontrollers to be affected by scrolling!
        CGPoint offset = [scrollView contentOffset];
        
        // Are we less than 2 screen-size worths from the top of the contentView? (measured in pixels)...that was a mouthful lol
        if (offset.y <= (_heightOfScreenRotationIndependant * 2))
            [self showScrollToTopButton:NO];
        else
            [self showScrollToTopButton:YES];
        
        //now check if the user scrolled to the bottom to load more
        
        CGFloat scrollViewHeight = scrollView.bounds.size.height;
        CGFloat scrollContentSizeHeight = scrollView.contentSize.height;
        CGFloat bottomInset = scrollView.contentInset.bottom;
        CGFloat scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight;
        
        if (scrollView.contentOffset.y >= scrollViewBottomOffset && self.displaySearchResults){
            if(self.waitingOnNextPageResults)
                return;
            self.waitingOnNextPageResults = YES;
            //try to load more results
            [[YouTubeVideoSearchService sharedInstance] fetchNextYouTubePageUsingLastQueryString];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - ToolBar methods
- (void)showScrollToTopButton:(BOOL)yes
{
    NSArray *toolbarItems;
    if(yes){
        UIBarButtonItem *scrollToTopButton = [[UIBarButtonItem alloc] initWithTitle:@"Scroll to Top"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(scrollToTopTapped)];
        //provides spacing so each button is on its respective side of the toolbar.
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        toolbarItems = [NSArray arrayWithObjects:_cancelButton,flexibleSpace, scrollToTopButton, nil];
        _scrollToTopButtonVisible = YES;
        [self.navigationController.toolbar setItems:toolbarItems animated:YES];
    }
    else{  //hiding scroll to top button
        toolbarItems = [NSArray arrayWithObjects:_cancelButton, nil];
        _scrollToTopButtonVisible = NO;
        [self.navigationController.toolbar setItems:toolbarItems animated:YES];
    }
}

#pragma mark - Stop-watch method to time code execution
static NSDate *start;
static NSDate *finish;
- (void)startTimingExecution
{
    start = [NSDate date];
}

- (NSTimeInterval)timeOnExecutionTimer
{
    if(start == nil)
        return 0;
    finish = [NSDate date];
    NSTimeInterval executionTime = [finish timeIntervalSinceDate:start];
    start = nil;
    finish = nil;

    return executionTime;
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    if(!_displaySearchResults)  //want to reload the section headers during orientation so it fits ("top hits")
        [self.tableView reloadData];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
