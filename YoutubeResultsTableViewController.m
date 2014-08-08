//
//  YoutubeResultsTableViewController.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YoutubeResultsTableViewController.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@interface YoutubeResultsTableViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *searchSuggestions;
@property (nonatomic, assign) BOOL displaySearchResults;
@property (nonatomic, assign) BOOL searchInitiatedAlready;
@property (nonatomic, assign) BOOL activityIndicatorOnScreen;
@property (nonatomic, strong) YouTubeVideoSearchService *yt;
@property (nonatomic, strong) NSString *lastSuccessfullSearchString;
@property (nonatomic, assign) float heightOfScreenRotationIndependant;
//view isn't actually on top of tableView, but it looks like it. Call "turnTableViewIntoUIView" prior to setting this value!
@property (nonatomic, strong) UIView *viewOnTopOfTable;


@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *scrollToTopButton;
@property (nonatomic, assign) BOOL scrollToTopButtonVisible;
@end

@implementation YoutubeResultsTableViewController
static BOOL PRODUCTION_MODE;
static const float MINIMUM_DURATION_OF_LOADING_POPUP = 1.0;

#pragma mark - Miscellaneous
- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)makeBarButtonGrey:(UIBarButtonItem *)barButton yes:(BOOL)show
{
    if (show) {
        barButton.style = UIBarButtonItemStyleBordered;
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
    if (self.isMovingToParentViewController == NO)
    {
        // we're already on the navigation stack, another controller must have been popped off.
        _displaySearchResults = YES;
        self.tableView.scrollEnabled = YES;
        //restore scroll to top button if it was there before segue
        if(_scrollToTopButtonVisible)
            [self showScrollToTopButton:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _yt = [[YouTubeVideoSearchService alloc] init];
    [_yt setDelegate:self];
    
    _searchSuggestions = [NSMutableArray array];
    _searchResults = [NSMutableArray array];
    
    //self.navigationController.navigationBar.hidden = YES;
    self.navigationController.toolbarHidden = NO;
    _navBar.title = @"Add Music";
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self
                                                                  action:@selector(cancelTapped)];
    [self setToolbarItems:@[_cancelButton]];
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
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
    // dismiss loading popup if enough time has passed
    NSTimeInterval executionTime = [self timeOnExecutionTimer];
    NSTimeInterval additionalDelay;
    if(executionTime < MINIMUM_DURATION_OF_LOADING_POPUP && executionTime != 0){
        additionalDelay = (MINIMUM_DURATION_OF_LOADING_POPUP - executionTime);
        [self performSelector:@selector(ytVideoSearchDidCompleteWithResults:) withObject:youTubeVideoObjects afterDelay:additionalDelay];
        return;
    }
    
    [_searchResults removeAllObjects];
    [_searchResults addObjectsFromArray:youTubeVideoObjects];
    
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
    NSUInteger count = _searchResults.count;
    NSUInteger moreResultsCount = moreYouTubeVideoObjects.count;
    
    if (moreResultsCount) {
        [_searchResults addObjectsFromArray:moreYouTubeVideoObjects];
        moreYouTubeVideoObjects = nil;
        
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
}

- (void)ytvideoResultsNoMorePagesToView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
    //change "Load More" button
    loadMoreCell.textLabel.text = @"No more results";
    loadMoreCell.accessoryView = nil;
}

- (void)ytVideoAutoCompleteResultsDidDownload:(NSArray *)arrayOfNSStrings
{
    //only going to use 5 of the 10 results returned. 10 is too much
    [_searchSuggestions removeAllObjects];
    
    int upperBound = -1;
    if(arrayOfNSStrings.count >= 5)
        upperBound = 5;
    else
        upperBound = (int)arrayOfNSStrings.count;
    
    for(int i = 0; i < upperBound; i++)
        [_searchSuggestions addObject:arrayOfNSStrings[i]];
    
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
    [self launchAlertViewWithDialogTitle:@"Network Problem" andMessage:@"Cannot establish connection with YouTube"];
}

- (void)networkErrorHasOccuredFetchingMorePages
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
    //change "Load More" button
    loadMoreCell.textLabel.text = @"Network error, tap to try again";
    loadMoreCell.textLabel.font = [UIFont systemFontOfSize:19];
    loadMoreCell.accessoryView = nil;
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
        _displaySearchResults = NO;
        self.tableView.scrollEnabled = NO;
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //create search bar, add to viewController
    _searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
    _searchBar.placeholder = @"Find Music On YouTube";
    _searchBar.keyboardType = UIKeyboardTypeASCIICapable;
    _searchBar.delegate = self;
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = _searchBar;
}

//User tapped the search box textField
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //show the cancel button
    _displaySearchResults = NO;
    self.tableView.scrollEnabled = NO;
    _navBar.title = @"Add Music";
    [_searchBar setShowsCancelButton:YES animated:YES];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _searchInitiatedAlready = YES;
    _displaySearchResults = YES;
    self.tableView.scrollEnabled = YES;
    _lastSuccessfullSearchString = searchBar.text;
    _navBar.title = @"Search Results";
    [_searchBar resignFirstResponder];
    
    //show loading popup above tableview before content loads
    [self turnTableViewIntoUIView:YES];
    // Blocking a custom view
    [MRProgressOverlayView showOverlayAddedTo:_viewOnTopOfTable animated:YES];
    [self startTimingExecution];
    
    [_yt searchYouTubeForVideosUsingString: searchBar.text];
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if(! _searchInitiatedAlready){
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        if(_displaySearchResults == NO && _searchResults.count > 0){  //bring user back to previous results
            //restore state of search bar before uncommited search bar edit began
            [_searchBar setText:_lastSuccessfullSearchString];
            
            [_searchSuggestions removeAllObjects];
            [_searchBar resignFirstResponder];
            _displaySearchResults = YES;
            self.tableView.scrollEnabled = YES;
            [self.tableView reloadData];
            return;
        }
        //restore state of search bar before uncommited search bar edit began
        [_searchBar setText:_lastSuccessfullSearchString];
        
        //dismiss search bar and hide cancel button
        [_searchBar setShowsCancelButton:NO animated:YES];
        [_searchBar resignFirstResponder];
        
        [_searchResults removeAllObjects];
        [_searchSuggestions removeAllObjects];
    }
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if(searchText.length != 0){
        //fetch auto suggestions
        [_yt fetchYouTubeAutoCompleteResultsForString:searchText];
        _displaySearchResults = NO;
        self.tableView.scrollEnabled = NO;
        [self.tableView reloadData];
    }
    
    else{  //user cleared the textField
        if([searchBar isFirstResponder])  //keyboard on screen
            [_searchSuggestions removeAllObjects];
        else{
            [searchBar becomeFirstResponder];  //bring up keyboard
            [_searchSuggestions removeAllObjects];
        }
        _displaySearchResults = NO;
        self.tableView.scrollEnabled = NO;
        [self.tableView reloadData];
    }
}


#pragma mark - TableView deleagte
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(_displaySearchResults)
        return 2;  //this one has a "load more" button
    else
        return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(! _displaySearchResults)
        return 36.0f;
    else{
        if(section == 0)  //dont want a gap betweent table and search bar
            return 1.0f;
        else
            return 14.0f;  //"Load More" cell is in section 1
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(_displaySearchResults){
        if(section == 0){
            return [NSString stringWithFormat:@"Displaying %i results", (int)_searchResults.count];
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_displaySearchResults){
        if(section == 0)
            return _searchResults.count;  //number of videos in results
        else if(section == 1)  //"Load more" cell
            return 1;
        else
            return -1;
    }
    else
        return _searchSuggestions.count;  //user has not pressed "search" yet, only showing autosuggestions
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(! _displaySearchResults){
        if(section == 0 && _searchSuggestions.count > 0)
            return @"Top Hits";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    // Configure the cell...
    YouTubeVideo *ytVideo;
    if(_displaySearchResults){  //video search results will populate the table
        if(indexPath.section == 0){
            ytVideo = [_searchResults objectAtIndex:indexPath.row];
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"youtubeResultCell" forIndexPath:indexPath];
            cell.textLabel.text = ytVideo.videoName;
            cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
            cell.detailTextLabel.textColor = [[UIColor redColor] darkerColor];
            cell.detailTextLabel.text = ytVideo.channelTitle;
            cell.tag = indexPath.row;  //used to double check the cell in the block below.
            
            // Here we use the new provided setImageWithURL: method to load the web image
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:ytVideo.videoThumbnailUrl]
                              placeholderImage:[UIImage imageWithColor:[UIColor clearColor] width:120 height:90]
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                         if(cacheType == SDImageCacheTypeNone)  //if image had to be downloaded from the web for the first time
                                             if (cell.tag == indexPath.row && image){
                                                 [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:
                                                  UITableViewRowAnimationNone];
                                             }
                                     }];
        } else if(indexPath.section == 1){  //the "load more" button is in this section
            if(indexPath.row == 0){
                cell = [tableView dequeueReusableCellWithIdentifier:@"loadMoreButtonCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Load more";
                cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.textColor = [UIColor defaultSystemTintColor];
            }
        }
    }
    else{  //auto suggestions will populate the table
        cell = [tableView dequeueReusableCellWithIdentifier:@"youtubeSuggsestCell" forIndexPath:indexPath];
        cell.textLabel.text = [_searchSuggestions objectAtIndex:indexPath.row];
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(! _displaySearchResults)
        return 45;
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(_displaySearchResults){  //video search results in table
        if(indexPath.section == 0){
            YouTubeVideo *ytVideo = [_searchResults objectAtIndex:indexPath.row];
            [self.navigationController pushViewController:[[YouTubeVideoPlaybackTableViewController alloc] initWithYouTubeVideo:ytVideo] animated:YES];
            
        } else if(indexPath.section == 1){
            //Load More button tapped
            if(indexPath.row == 0){
                UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                                                         UIActivityIndicatorViewStyleGray];
                [activityView startAnimating];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
                UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
                [loadMoreCell setAccessoryView:activityView];
                
                //try to load more results
                [_yt fetchNextYouTubePageForLastQuery];
            }
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

#pragma mark - TableView custom view toggler
- (void)turnTableViewIntoUIView:(BOOL)yes
{
    if(yes){
        self.tableView.tableHeaderView = nil;
        _viewOnTopOfTable = [[UIView alloc] initWithFrame:self.tableView.frame];
        self.tableView.tableHeaderView = _viewOnTopOfTable;
        self.tableView.scrollEnabled = NO;
    } else{
        self.tableView.tableHeaderView = nil;
        _viewOnTopOfTable = nil;
        [self setUpSearchBar];
        self.tableView.scrollEnabled = YES;
    }
}

#pragma mark - Scrolling method implementation
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isViewLoaded && self.view.window){
        //viewController is visible on screen (dont want pushed viewcontrollers to be affected by scrolling!
        CGPoint offset = [scrollView contentOffset];
        
        // Are we less than 2 screen-size worths from the top of the contentView? (measurd in pixels)...that was a mouthful lol
        if (offset.y <= (_heightOfScreenRotationIndependant * 2))
            [self showScrollToTopButton:NO];
        else
            [self showScrollToTopButton:YES];
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
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        
        toolbarItems = [NSArray arrayWithObjects:_cancelButton,flexibleSpace, scrollToTopButton, nil];
        if(! _scrollToTopButtonVisible){  //not visible, need to animate
            _scrollToTopButtonVisible = YES;
            [self.navigationController.toolbar setItems:toolbarItems animated:YES];
        }
    }
    else{  //hiding scroll to top button
        toolbarItems = [NSArray arrayWithObjects:_cancelButton, nil];
        if(_scrollToTopButtonVisible){
            _scrollToTopButtonVisible = NO;
            [self.navigationController.toolbar setItems:toolbarItems animated:YES];
        }
        //otherwise already not on screen, no need to change toolbar.
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
    return YES;
}

@end
