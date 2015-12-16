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
#import "SDCAlertController.h"
#import "PreferredFontSizeUtility.h"
#import "YouTubeSongAdderViewController.h"
#import "CustomYoutubeTableViewCell.h"

//NOTE loadingMoreResultsSpinner is not currently used. To use again, call "reload" on tableview
//right before loading more results.
@interface YoutubeResultsTableViewController ()
{
    UIActivityIndicatorView *loadingMoreResultsSpinner;
    UIActivityIndicatorView *loadingResultsIndicator;
}
@property (nonatomic, strong) MySearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *searchSuggestions;
@property (nonatomic, assign) BOOL displaySearchResults;
@property (nonatomic, assign) BOOL searchInitiatedAlready;
@property (nonatomic, strong) NSString *lastSuccessfullSearchString;
@property (nonatomic, strong) NSMutableArray *lastSuccessfullSuggestions;
@property (nonatomic, assign) float heightOfScreenRotationIndependant;
//view isn't actually on top of tableView, but it looks like it. It is really the tableview header
@property (nonatomic, strong) UIView *viewOnTopOfTable;

@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *scrollToTopButton;
@property (nonatomic, assign) BOOL scrollToTopButtonVisible;
@property (nonatomic, assign) BOOL networkErrorLoadingMoreResults;
@property (nonatomic, assign) BOOL noMoreResultsToDisplay;
@property (nonatomic, assign) BOOL waitingOnNextPageResults;
@property (nonatomic, assign) BOOL waitingOnYoutubeResults;
@end

@implementation YoutubeResultsTableViewController
static BOOL PRODUCTION_MODE;
static const float MINIMUM_DURATION_OF_LOADING_POPUP = 0.3f;
static NSString *Network_Error_Loading_More_Results_Msg = @"Network error";
static NSString *No_More_Results_To_Display_Msg = @"No more results";

//custom setters
- (void)setDisplaySearchResults:(BOOL)displaySearchResults
{
    _displaySearchResults = displaySearchResults;
}

#pragma mark - Miscellaneous
- (void)dealloc
{
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

- (void)myPreDealloc
{
    _searchBar.delegate = nil;
    loadingMoreResultsSpinner = nil;
    _searchBar = nil;
    _searchResults = nil;
    self.searchSuggestions = nil;
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
    [self dismissViewControllerAnimated:YES completion:^{
        [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
    }];
}

- (void)scrollToTopTapped
{
    if([self.tableView numberOfRowsInSection:0] > 0){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
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
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    //if(self.displaySearchResults)
        //_navBar.title = @"Search Results";
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:UIDeviceOrientationDidChangeNotification
                                                 object:nil];
    //makes sure that if the VC is being popped, the keyboard doesnt dismiss with a huge delay.
    [self.view endEditing:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *poweredByYtLogo = [UIImage imageNamed:@"poweredByYtLight"];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  poweredByYtLogo.size.width,
                                                                  poweredByYtLogo.size.height)];
    UIImageView * imgView = [[UIImageView alloc] initWithImage:poweredByYtLogo];
    [footerView addSubview:imgView];
    self.navigationItem.titleView = footerView;
    
    self.searchSuggestions = [NSMutableArray array];
    _searchResults = [NSMutableArray array];
    _lastSuccessfullSuggestions = [NSMutableArray array];
    
    self.navigationController.toolbarHidden = NO;
    //_navBar.title = @"Adding Music";
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
        youTubeVideoObjects = nil;
        return;
    }
    
    [_searchResults removeAllObjects];
    [_searchResults addObjectsFromArray:youTubeVideoObjects];
    youTubeVideoObjects = nil;
    
    if(_searchResults.count == 0){  //special case
        //display alert saying no results found
        
        [self launchAlertViewWithDialogTitle:@"No Search Results Found" andMessage:nil];
        [_searchBar setText:@""];
    }else
        [self showLoadingIndicatorInCenterOfTable:NO];
    [_searchBar setText:_lastSuccessfullSearchString];
    
    self.searchInitiatedAlready = YES;
    self.waitingOnYoutubeResults = NO;
    
    [self.tableView beginUpdates];
    //I deleted section 0 when search was tapped
    if([self.tableView numberOfSections] == 0){
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationMiddle];
    }
    [self.tableView endUpdates];
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
        
        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationMiddle];
        
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
    //since we're not using an NSOperationQueue or something sophisticated like that,
    //its possible that this response could come in AFTER the user already pressed the search
    //button and displayed search results in his table. if thats the case, we simply ignore this.
    if(self.displaySearchResults){
        return;
    }
    
    //only going to use 5 of the 10 results returned. 10 is too much (searchSuggestions array is already empty-emptied in search bar text did change)
    int searchSuggestionsCountBefore = (int)self.searchSuggestions.count;
    [self.searchSuggestions removeAllObjects];
    [_lastSuccessfullSuggestions removeAllObjects];
    
    int upperBound = -1;
    if(arrayOfNSStrings.count >= 5)
        upperBound = 5;
    else
        upperBound = (int)arrayOfNSStrings.count;
    
    for(int i = 0; i < upperBound; i++){
        [self.searchSuggestions addObject:[arrayOfNSStrings[i] copy]];
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
        [self.tableView insertRowsAtIndexPaths:newPaths withRowAnimation:UITableViewRowAnimationMiddle];
        [self.tableView endUpdates];
    }
    else{
        //number of rows is the same, dont use any animation (so text doesnt flash like crazy).
        NSMutableArray *allPaths = [NSMutableArray array];
        for(int i = 0; i < upperBound; i++){
            [allPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:allPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
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

    [self showLoadingIndicatorInCenterOfTable:NO];
    
    [self launchAlertViewWithDialogTitle:@"Network Problem" andMessage:@"Cannot establish connection with YouTube."];
    
    self.searchInitiatedAlready = NO;
    self.waitingOnYoutubeResults = NO;
    
}

- (void)networkErrorHasOccuredFetchingMorePages
{
    self.waitingOnNextPageResults = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
    //change "Load More" button
    loadMoreCell.textLabel.text = Network_Error_Loading_More_Results_Msg;
    loadMoreCell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:19];
    loadMoreCell.textLabel.textColor = [UIColor redColor];
    [loadingMoreResultsSpinner stopAnimating];
    _networkErrorLoadingMoreResults = YES;
    [self.tableView reloadData];
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialogTitle:(NSString *)title andMessage:(NSString *)message
{
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                         style:SDCAlertActionStyleRecommended
                                                       handler:nil];
    [alert addAction:okAction];
    [self slightlyDelayPresentationOfAlertController:alert];
    
    [self showLoadingIndicatorInCenterOfTable:NO];
    self.displaySearchResults = NO;
    [self.tableView reloadData];
}

- (void)slightlyDelayPresentationOfAlertController:(SDCAlertController *)alert
{
    [alert performSelector:@selector(presentWithCompletion:)
                withObject:nil
                afterDelay:0.2];
}

#pragma mark - UISearchBar
- (void)setUpSearchBar
{
    //create search bar, add to viewController
    _searchBar = [[MySearchBar alloc] initWithPlaceholderText:@"Search"];
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
    //_navBar.title = @"Adding Music";
    [_searchBar setShowsCancelButton:YES animated:YES];

    if(self.searchInitiatedAlready){
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationMiddle];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationMiddle];
        [self.tableView endUpdates];
    }
    else
        [self.tableView reloadData];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.displaySearchResults = YES;
    self.waitingOnYoutubeResults = YES;
    self.tableView.scrollEnabled = YES;
    _lastSuccessfullSearchString = searchBar.text;
    //setting it both ways, do to nav bar title bug
    self.navigationController.navigationBar.topItem.title = @"Search Results";
    //_navBar.title = @"Search Results";
    [_searchBar resignFirstResponder];
    
    [self showLoadingIndicatorInCenterOfTable:YES];
    
    [self.tableView beginUpdates];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationMiddle];
    [self.tableView endUpdates];
    
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
        [self dismissViewControllerAnimated:YES completion:^{
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
         }];
    }else{
        //setting it both ways, due to nav bar title bug
        self.navigationController.navigationBar.topItem.title = @"Search Results";
        //_navBar.title = @"Search Results";
        
        //restore state of search bar and table before uncommited search bar edit began
        [_searchBar setText:_lastSuccessfullSearchString];
        if(userClearedTextField)
            [self.searchSuggestions addObjectsFromArray:_lastSuccessfullSuggestions];
        userClearedTextField = NO;
        
        if(self.displaySearchResults == NO && _searchResults.count > 0){  //bring user back to previous results
            //restore state of search bar before uncommited search bar edit began
            [_searchBar setText:_lastSuccessfullSearchString];
            
            //[self.searchSuggestions removeAllObjects];
            
            [_searchBar resignFirstResponder];
            self.displaySearchResults = YES;
            self.tableView.scrollEnabled = YES;
            
            //dismiss search bar and hide cancel button
            [_searchBar setShowsCancelButton:NO animated:YES];
            [_searchBar resignFirstResponder];
            
            [self.tableView beginUpdates];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
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
        
        int numSearchSuggestions = (int)self.searchSuggestions.count;
        
        if([searchBar isFirstResponder])  //keyboard on screen
            [self.searchSuggestions removeAllObjects];
        else{
            [searchBar becomeFirstResponder];  //bring up keyboard
            [self.searchSuggestions removeAllObjects];
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
    if(self.waitingOnYoutubeResults)
        return 0;
    else
        return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(! self.displaySearchResults){  //showing autocomplete.
        //want to hide the header in landscape
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if(orientation != UIInterfaceOrientationPortrait)
            return 0.0f;
        else
            return 38.0f;
    }
    else{
        if(section == 0)  //dont want a gap betweent table and search bar
            return 1.0f;
        else
            return 0.0f;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(! self.displaySearchResults){
        return @"Top Hits";
    }
    return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    float defaultFooterHeight = 90.0f;
    int numResultsInEachResultsPage = 15;
    if(_displaySearchResults){
        if(_networkErrorLoadingMoreResults || _noMoreResultsToDisplay || self.searchResults.count < numResultsInEachResultsPage){
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, defaultFooterHeight)];
            if(_networkErrorLoadingMoreResults){
                label.text = Network_Error_Loading_More_Results_Msg;
                label.textColor = [UIColor redColor];
            }
            else if(_noMoreResultsToDisplay || self.searchResults.count < numResultsInEachResultsPage){
                label.text = No_More_Results_To_Display_Msg;
                label.textColor = [UIColor blackColor];
            }
            
            int middle = ([AppEnvironmentConstants maximumSongCellHeight] + [AppEnvironmentConstants minimumSongCellHeight])/ 2.0;
            
            if([AppEnvironmentConstants preferredSongCellHeight] >= middle)
                label.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                             size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            else
                label.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                              size:[PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:middle]];
            CGSize maximumLabelSize = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
            CGSize requiredSize = [label sizeThatFits:maximumLabelSize];
            CGRect labelFrame = label.frame;
            labelFrame.size.height = requiredSize.height;
            label.frame = labelFrame;
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, label.frame.size.width, label.frame.size.height)];
            [label setTextAlignment:NSTextAlignmentCenter];
            [view addSubview:label];
            return view;
        } else if(self.waitingOnNextPageResults){
            [loadingMoreResultsSpinner removeFromSuperview];
            loadingMoreResultsSpinner = nil;
            loadingMoreResultsSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, defaultFooterHeight)];
            [view addSubview:loadingMoreResultsSpinner];
            int spinnerWidth = loadingMoreResultsSpinner.frame.size.width;
            loadingMoreResultsSpinner.frame = CGRectMake(view.frame.size.width/2 - (spinnerWidth/2),
                                                         0,
                                                         spinnerWidth,
                                                         spinnerWidth);
            [loadingMoreResultsSpinner setColor:[UIColor defaultAppColorScheme]];
            [loadingMoreResultsSpinner startAnimating];
            return view;
        } else{
            //just show that more results are below if user scrolls
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, defaultFooterHeight)];
            label.text = @"···";
            label.textColor = [UIColor defaultAppColorScheme];
            label.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                            size:[PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:[AppEnvironmentConstants maximumSongCellHeight] -15]];
            
            CGSize maximumLabelSize = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
            CGSize requiredSize = [label sizeThatFits:maximumLabelSize];
            CGRect labelFrame = label.frame;
            labelFrame.size.height = requiredSize.height;
            label.frame = labelFrame;
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, label.frame.size.width, label.frame.size.height)];
            [label setTextAlignment:NSTextAlignmentCenter];
            [view addSubview:label];
            return view;
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.displaySearchResults){
        if(section == 0)
            return _searchResults.count;  //number of videos in results
        else
            return -1;
    }else{
        //user has not pressed "search" yet, only showing autosuggestions
        return self.searchSuggestions.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    // Configure the cell...
    YouTubeVideo *ytVideo;
    
    if(self.displaySearchResults){  //video search results will populate the table
        if(indexPath.section == 0){
            if(_searchResults.count-1 < indexPath.row){
                NSLog(@"Woah!");
            }
            ytVideo = [_searchResults objectAtIndex:indexPath.row];
            
            CustomYoutubeTableViewCell *customCell;
            customCell = [tableView dequeueReusableCellWithIdentifier:@"youtubeResultCell" forIndexPath:indexPath];
            customCell.videoChannel.enabled = YES;
            customCell.videoTitle.enabled = YES;
            customCell.textLabel.enabled = YES;
            customCell.detailTextLabel.enabled = YES;
            customCell.videoTitle.text = ytVideo.videoName;
            customCell.videoChannel.textColor = [UIColor grayColor];
            customCell.videoChannel.text = ytVideo.channelTitle;
            customCell.videoTitle.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                        size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            customCell.videoChannel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                        size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            
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
            
        }
    }else{  //auto suggestions will populate the table
        cell = [tableView dequeueReusableCellWithIdentifier:@"youtubeSuggsestCell" forIndexPath:indexPath];
        cell.textLabel.text = [self.searchSuggestions objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                              size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        cell.imageView.image = nil;
    }
    ytVideo = nil;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(! self.displaySearchResults){
        //make this dynamic
        float maxCellHeight = [UIScreen mainScreen].bounds.size.height * 0.10;
        int height = [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
        if(height > maxCellHeight)
            height = maxCellHeight;
        
        return height;
    }
    else{
        if(indexPath.section == 0){
            float widthOfScreenRoationIndependant;
            float  a = [[UIScreen mainScreen] bounds].size.height;
            float b = [[UIScreen mainScreen] bounds].size.width;
            if(a < b)
                widthOfScreenRoationIndependant = a;
            else
                widthOfScreenRoationIndependant = b;
            
            int oneThirdDisplayWidth = widthOfScreenRoationIndependant * 0.45;
            int height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:oneThirdDisplayWidth];
            return height + 8;
        }
        else
            return 45;  //just returning something since i have to
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
            [self.navigationController pushViewController:[[YouTubeSongAdderViewController alloc] initWithYouTubeVideo:ytVideo thumbnail:img]
                                                 animated:YES];
        }
    }
    else{  //auto suggestions in table
        int index = (int)indexPath.row;
        NSString *chosenSuggestion = self.searchSuggestions[index];
        
        if(chosenSuggestion.length != 0){
            self.waitingOnYoutubeResults = YES;

            [_searchBar setText:chosenSuggestion];
            [self searchBarSearchButtonClicked:_searchBar];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    int headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
}

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [UIImage imageWithData:data];
                                   completionBlock(YES, image);
                               } else{
                                   completionBlock(NO, nil);
                               }
                           }];
}


#pragma mark - TableView custom view toggler/creator
- (void)showLoadingIndicatorInCenterOfTable:(BOOL)yes
{
    if(yes){
        self.tableView.scrollEnabled = NO;
        [self.searchBar removeFromSuperview];
        _viewOnTopOfTable = [[UIView alloc] initWithFrame:self.view.frame];
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        loadingResultsIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        int indicatorSize = loadingResultsIndicator.frame.size.width;
        loadingResultsIndicator.frame = CGRectMake(screenFrame.size.width/2 - indicatorSize/2,
                                                   screenFrame.size.height/2 - indicatorSize/2 - [AppEnvironmentConstants navBarHeight],
                                                   indicatorSize,
                                                   indicatorSize);
        loadingResultsIndicator.color = [UIColor defaultAppColorScheme];
        [loadingResultsIndicator startAnimating];
        
        [_viewOnTopOfTable addSubview:loadingResultsIndicator];
        self.tableView.tableHeaderView = _viewOnTopOfTable;
    } else{
        self.tableView.scrollEnabled = YES;
        [self.searchBar removeFromSuperview];
        [loadingResultsIndicator stopAnimating];
        loadingResultsIndicator = nil;
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
        if (offset.y <= (_heightOfScreenRotationIndependant * 2)){
            if(_scrollToTopButtonVisible)
                [self showScrollToTopButton:NO];
        }
        else{
            if(!_scrollToTopButtonVisible)
                [self showScrollToTopButton:YES];
        }
        
        
        //now check if the user scrolled to the bottom to load more
        CGFloat scrollViewHeight = scrollView.bounds.size.height;
        CGFloat scrollContentSizeHeight = scrollView.contentSize.height;
        CGFloat bottomInset = scrollView.contentInset.bottom;
        CGFloat scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight;
        
        if (scrollView.contentOffset.y >= scrollViewBottomOffset && self.displaySearchResults){
            [self userDidScrollToBottomOfTable];
            if(self.waitingOnNextPageResults)
                return;
        }
    }
}

- (void)userDidScrollToBottomOfTable
{
    if(self.waitingOnNextPageResults || !self.displaySearchResults)
        return;
    //covers an edge case where the user scrolls down to the bottom while the
    //search results are showing...and a crash occurs due to the fact that there are
    //no valid sections yet. and the "next page" delegate assumes it can just insert new rows lol.
    if(self.displaySearchResults && [self.tableView numberOfSections] == 0)
        return;

    self.waitingOnNextPageResults = YES;
    //try to load more results
    [[YouTubeVideoSearchService sharedInstance] fetchNextYouTubePageUsingLastQueryString];
}

#pragma mark - ToolBar methods
- (void)showScrollToTopButton:(BOOL)yes
{
    NSArray *toolbarItems;
    if(yes){
        _scrollToTopButton = [[UIBarButtonItem alloc] initWithTitle:@"Scroll to Top"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(scrollToTopTapped)];
        //provides spacing so each button is on its respective side of the toolbar.
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        toolbarItems = [NSArray arrayWithObjects:_cancelButton,flexibleSpace, _scrollToTopButton, nil];
        _scrollToTopButtonVisible = YES;
        [self.navigationController.toolbar setItems:toolbarItems animated:YES];
    }
    else{  //hiding scroll to top button
        _scrollToTopButton = nil;
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

#pragma mark - Rotation methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    
    _viewOnTopOfTable.frame = self.view.frame;
    
    if(! _displaySearchResults)  //want to reload the section headers during orientation so it fits ("top hits")
        [self.tableView reloadData];
}

#pragma mark - rotation methods
//i use these two methods to make sure the toolbar is always 'up to date' after rotation
- (void)orientationChanged:(NSNotification *)notification
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(updateToolbarAfterRotation)
                                   userInfo:nil
                                    repeats:NO];
    if(_waitingOnYoutubeResults){
        [self showLoadingIndicatorInCenterOfTable:YES];
    }
}

- (void)updateToolbarAfterRotation
{
    
    if(_scrollToTopButtonVisible)
        [self showScrollToTopButton:YES];
    else
        [self showScrollToTopButton:NO];
}

- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else{
        return NO;
    }
}

@end
