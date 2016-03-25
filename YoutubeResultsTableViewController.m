//
//  YoutubeResultsTableViewController.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YoutubeResultsTableViewController.h"

#import "YouTubeService.h"
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import "MRProgress.h"
#import "AlbumArtUtilities.h"
#import "SDCAlertController.h"
#import "PreferredFontSizeUtility.h"
#import "YouTubeSongAdderViewController.h"
#import "CustomYoutubeTableViewCell.h"
#import "AppRatingUtils.h"
#import "AppRatingTableViewCell.h"

//NOTE loadingMoreResultsSpinner is not currently used. To use again, call "reload" on tableview
//right before loading more results.
@interface YoutubeResultsTableViewController ()
{
    UIActivityIndicatorView *loadingNextPageSpinner;
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

@property (nonatomic, assign) BOOL canShowAppRatingCell;

//non-nil if it was specified when VC was created. For opening VC modally and forcing a query.
@property (nonatomic, strong) NSString *forcedSearchQuery;
//pass the id of the object for which you are doing a 'forced search query'.
@property (nonatomic, strong) NSManagedObjectID *replacementObjId;
@end

@implementation YoutubeResultsTableViewController
static const float MINIMUM_DURATION_OF_LOADING_POPUP = 0.3f;
static NSString *Network_Error_Loading_More_Results_Msg = @"Network error";
static NSString *No_More_Results_To_Display_Msg = @"No more results";
static const int APP_RATING_CELL_ROW_NUM = 2;

+ (instancetype)initWithSearchQuery:(NSString *)query replacementObjId:(NSManagedObjectID *)objId
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    YoutubeResultsTableViewController *ytSearchResultsVc;
    ytSearchResultsVc = [sb instantiateViewControllerWithIdentifier:@"ytSearchAndResultDisplayVc"];
    ytSearchResultsVc.forcedSearchQuery = query;
    ytSearchResultsVc.replacementObjId = objId;
    return ytSearchResultsVc;
}

//custom setters
- (void)setDisplaySearchResults:(BOOL)displaySearchResults
{
    _displaySearchResults = displaySearchResults;
}

static NSDate *timeSinceLastPageLoaded;
- (void)setWaitingOnNextPageResults:(BOOL)waitingOnNextPageResults
{
    if(_waitingOnNextPageResults == NO) {
        //mark when next page finished loading. Used to avoid loading too many pages
        //if the user scrolls aggressively.
        timeSinceLastPageLoaded = [NSDate date];
    }
    _waitingOnNextPageResults = waitingOnNextPageResults;
}

#pragma mark - Miscellaneous
- (void)dealloc
{
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

- (void)myPreDealloc
{
    cachedPlaceHolderImage = nil;
    thumbnailStackController = nil;
    _searchBar.delegate = nil;
    _searchBar = nil;
    _forcedSearchQuery = nil;
    _searchResults = nil;
    _replacementObjId = nil;
    self.searchSuggestions = nil;
    _lastSuccessfullSuggestions = nil;
    _cancelButton = nil;
    _scrollToTopButton = nil;
    _viewOnTopOfTable = nil;
    _lastSuccessfullSearchString = nil;
    _viewOnTopOfTable = nil;
    start = nil;
    finish = nil;
    [[YouTubeService sharedInstance] removeVideoQueryDelegate];
    
    [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerCanIgnoreToolbar];
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
    [[YouTubeService sharedInstance] setVideoQueryDelegate:self];
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
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    //if(self.displaySearchResults)
        //_navBar.title = @"Search Results";
    [self setNeedsStatusBarAppearanceUpdate];
    
    //if this VC was initialized with a forcedSearchQuery, fire off to the delegate.
    if(_forcedSearchQuery != nil && _forcedSearchQuery.length > 0) {
        self.searchBar.text = _forcedSearchQuery;
        [self searchBarSearchButtonClicked:self.searchBar];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:UIApplicationDidChangeStatusBarOrientationNotification
                                                 object:nil];
    //makes sure that if the VC is being popped, the keyboard doesnt dismiss with a huge delay.
    [self.view endEditing:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    thumbnailStackController = [[StackController alloc] init];
    
    UIImage *poweredByYtLogo = [UIImage imageNamed:@"poweredByYtLight"];
    UIView *navBarView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  poweredByYtLogo.size.width,
                                                                  poweredByYtLogo.size.height)];
    UIImageView * imgView = [[UIImageView alloc] initWithImage:poweredByYtLogo];
    [navBarView addSubview:imgView];
    self.navigationItem.titleView = navBarView;
    
    self.searchSuggestions = [NSMutableArray array];
    _searchResults = [NSMutableArray array];
    _lastSuccessfullSuggestions = [NSMutableArray array];
    
    self.navigationController.toolbarHidden = NO;
    //_navBar.title = @"Adding Music";
    _cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(cancelTapped)];
    [self setToolbarItems:@[_cancelButton]];
    
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
    
    self.canShowAppRatingCell = [AppRatingUtils shouldAskUserIfTheyLikeApp];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideAppRatingCell)
                                                 name:MZHideAppRatingCell
                                               object:nil];
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"youtubeQuerySuggestCell"];
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
    _networkErrorLoadingMoreResults = NO;
    
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
    [loadingNextPageSpinner stopAnimating];
    [loadingNextPageSpinner removeFromSuperview];
}

- (void)ytvideoResultsNoMorePagesToView
{
    self.searchInitiatedAlready = YES;
    self.waitingOnNextPageResults = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    UITableViewCell *loadMoreCell = [self.tableView cellForRowAtIndexPath:indexPath];
    //change "Load More" button
    loadMoreCell.textLabel.text = No_More_Results_To_Display_Msg;
    _noMoreResultsToDisplay = YES;
    [loadingNextPageSpinner stopAnimating];
    [loadingNextPageSpinner removeFromSuperview];
}

- (void)ytVideoAutoCompleteResultsDidDownload:(NSArray *)arrayOfNSStrings
{
    //maybe its possible that this response could come in AFTER the user already pressed the search
    //button and displayed search results in his table? if thats the case, we simply ignore this.
    if(self.displaySearchResults){
        return;
    }
    
    if(arrayOfNSStrings.count > 0) {
        NSString *query = arrayOfNSStrings[0];
        if(! [_searchBar.text isEqualToString:query]) {
            //these are old results, don't run the code below to update the tableview - that just
            //slows down the main thread a lot when the user types fast!!
            return;
        }
    }
    
    NSMutableArray *suggestions = [NSMutableArray arrayWithArray:arrayOfNSStrings];
    [suggestions removeObjectAtIndex:0];  //remove the query text.
    
    //only going to use 5 of the 10 results returned. 10 is too much (searchSuggestions array is already empty-emptied in search bar text did change)
    int searchSuggestionsCountBefore = (int)self.searchSuggestions.count;
    [self.searchSuggestions removeAllObjects];
    [_lastSuccessfullSuggestions removeAllObjects];
    
    int upperBound = -1;
    if(suggestions.count >= 5)
        upperBound = 5;
    else
        upperBound = (int)suggestions.count;
    
    for(int i = 0; i < upperBound; i++){
        [self.searchSuggestions addObject:[suggestions[i] copy]];
        [_lastSuccessfullSuggestions addObject:[suggestions[i] copy]];
    }
    arrayOfNSStrings = nil;
    suggestions = nil;
    
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
    
    [loadingNextPageSpinner removeFromSuperview];
    [self.tableView setTableFooterView:nil];
    loadingNextPageSpinner = nil;
    
    if(_networkErrorLoadingMoreResults){
        //reloading the table here wouldn't do anything for us + the table would flicker a lot
        //as this delegate is called multiple times during scrolling.
        return;
    } else {
        _networkErrorLoadingMoreResults = YES;
        [self.tableView reloadData];
    }
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
    if([searchBar.text isEqualToString: _forcedSearchQuery]) {
        _forcedSearchQuery = nil;
    }
    self.displaySearchResults = YES;
    self.waitingOnYoutubeResults = YES;
    self.tableView.scrollEnabled = YES;
    _lastSuccessfullSearchString = searchBar.text;
    self.navigationController.navigationBar.topItem.title = @"Search Results";
    [_searchBar resignFirstResponder];
    
    [self showLoadingIndicatorInCenterOfTable:YES];
    
    [self.tableView beginUpdates];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationMiddle];
    [self.tableView endUpdates];
    
    [self startTimingExecution];
    
    [[YouTubeService sharedInstance] searchYouTubeForVideosUsingString: searchBar.text];
    _noMoreResultsToDisplay = NO;
    _networkErrorLoadingMoreResults = NO;
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if(! self.searchInitiatedAlready){
        [[YouTubeService sharedInstance] cancelAllYtAutoCompletePendingRequests];
        [self myPreDealloc];
        [self dismissViewControllerAnimated:YES completion:^{
            [MusicPlaybackController updateLockScreenInfoAndArtForSong:[MusicPlaybackController nowPlayingSong]];
         }];
    }else{
        self.navigationController.navigationBar.topItem.title = @"Search Results";
        
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
    [[YouTubeService sharedInstance] cancelAllYtAutoCompletePendingRequests];
    
    if(searchText.length != 0){
        if(! self.displaySearchResults)
            self.tableView.scrollEnabled = YES;
        
        [[YouTubeService sharedInstance] fetchYouTubeAutoCompleteResultsForString:searchText];
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
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.displaySearchResults){
        NSAssert(section == 0, @"YoutubeResultsTableViewController numberOfRowsInSection -> section != 0 when self.displaySearchResults == YES.");
        NSInteger numRows = _searchResults.count;  //number of videos in results
        if(self.canShowAppRatingCell) {
            numRows++;
        }
        return numRows;
    }else{
        //user has not pressed "search" yet, only showing autosuggestions
        return self.searchSuggestions.count;
    }
}

//works because youtube images are almost always the same size. the placeholder is fine.
static UIImage *cachedPlaceHolderImage = nil;
static char ytCellIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YouTubeVideo *ytVideo;
    
    //video search results will populate the table
    if(self.displaySearchResults){
        NSAssert(indexPath.section == 0, @"YoutubeResultsTableViewController calling cellForRowAtIndexPath for section > 0 when displaying search results.");
        
        int numAppRatingCells = (_canShowAppRatingCell) ? 1 : 0;
        NSString *assertDesc = [NSString stringWithFormat:@"Cell indexpath.row is %li but there are only %lu search results (+ %i app rating cells). last index is %lu.", (long)indexPath.row, (unsigned long)_searchResults.count, numAppRatingCells, _searchResults.count-1];
        NSAssert(_searchResults.count-1 + numAppRatingCells >= indexPath.row, assertDesc);
        
        if(_canShowAppRatingCell && indexPath.row == APP_RATING_CELL_ROW_NUM) {
            AppRatingTableViewCell *appRatingCell;
            appRatingCell = [tableView dequeueReusableCellWithIdentifier:@"appRatingCell"
                                                            forIndexPath:indexPath];
            appRatingCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return appRatingCell;
        }
        
        NSInteger ytVideoResultsIndex = -1;
        if(_canShowAppRatingCell) {
            ytVideoResultsIndex = (indexPath.row >= APP_RATING_CELL_ROW_NUM) ?
                                        indexPath.row -1 : indexPath.row;
        } else {
            ytVideoResultsIndex = indexPath.row;
        }
        NSInteger arrayIndex = [self rowNumFromIndexPathTakingAppRatingCellIntoAccount:indexPath];
        ytVideo = [_searchResults objectAtIndex:arrayIndex];
        
        CustomYoutubeTableViewCell *customCell;
        customCell = [tableView dequeueReusableCellWithIdentifier:@"youtubeResultCell"
                                                     forIndexPath:indexPath];
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
        if(cachedPlaceHolderImage == nil) {
            cachedPlaceHolderImage = [UIImage imageWithColor:[UIColor clearColor]
                                                       width:customCell.videoThumbnail.frame.size.width
                                                      height:customCell.videoThumbnail.frame.size.height];
        }
        customCell.videoThumbnail.image = cachedPlaceHolderImage;
        
        // Store a reference to the current cell that will enable the image to be associated with
        //the correct cell, when the image is subsequently loaded asynchronously.
        objc_setAssociatedObject(customCell,
                                 &ytCellIndexPathAssociationKey,
                                 indexPath,
                                 OBJC_ASSOCIATION_RETAIN);
        
        __weak NSString *weakVideoURL = ytVideo.videoThumbnailUrl;
        __weak CustomYoutubeTableViewCell *weakCell = customCell;
        
        // Queue a block that obtains/creates the image and then loads it into the cell.
        // The code block will be run asynchronously in a last-in-first-out queue, so that when
        // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
        [thumbnailStackController addBlock:^{
            NSURL *url = [NSURL URLWithString:weakVideoURL];
            NSData *data = [NSData dataWithContentsOfURL:url];
            __block UIImage *thumbnail = [UIImage imageWithData:data];
            
            // The block will be processed on a background Grand Central Dispatch queue.
            // Therefore, ensure that this code that updates the UI will run on the main queue.
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(customCell, &ytCellIndexPathAssociationKey);
                if ([indexPath isEqual:cellIndexPath]) {
                    // Only set cell image if the cell currently being displayed is the one that actually required this image.
                    // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                    [UIView transitionWithView:weakCell.videoThumbnail
                                      duration:MZCellImageViewFadeDuration
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        weakCell.videoThumbnail.image = thumbnail;
                                    } completion:nil];
                }
            });
        }];
        
        ytVideo = nil;
        customCell.accessoryType = UITableViewCellAccessoryNone;
        return customCell;
        
    } else {
        //auto suggestions will populate the table
        UITableViewCell *cell;
        cell = [tableView dequeueReusableCellWithIdentifier:@"youtubeQuerySuggestCell"
                                               forIndexPath:indexPath];
        cell.textLabel.text = [self.searchSuggestions objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                              size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        cell.imageView.image = nil;
        return cell;
    }
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
        NSAssert(indexPath.section == 0, @"YoutubeResultsTableViewController asking for height of cell w/ section > 0 when displaying search results!");
        float widthOfScreenRoationIndependant;
        float  a = [[UIScreen mainScreen] bounds].size.height;
        float b = [[UIScreen mainScreen] bounds].size.width;
        if(a < b)
            widthOfScreenRoationIndependant = a;
        else
            widthOfScreenRoationIndependant = b;
        
        //hardcoded in the CustomYoutubeTabeViewCell obj too. Was originally a % of the
        //screen.
        int imageWidth = 140;
        int height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:imageWidth];
        return height + 16;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_displaySearchResults && _canShowAppRatingCell && indexPath.row == APP_RATING_CELL_ROW_NUM) {
        return;  //don't want a selection style for that cell.
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(self.displaySearchResults){  //video search results in table
        if(indexPath.section == 0){
            NSInteger arrayIndex = [self rowNumFromIndexPathTakingAppRatingCellIntoAccount:indexPath];
            YouTubeVideo *ytVideo = [_searchResults objectAtIndex:arrayIndex];
            CustomYoutubeTableViewCell *cell;
            cell = (CustomYoutubeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            UIImage *img = [UIImage imageWithCGImage:cell.videoThumbnail.image.CGImage];
            
            UIViewController *vc;
            if(_replacementObjId
               && [_replacementObjId.entity.managedObjectClassName isEqualToString:@"Song"]) {
                
                //user wants to edit and possibly save with an existing core data object.
                Song *existingSong = (Song *)[self coreDataObjectFromManagedObjId:_replacementObjId];
                vc = [[YouTubeSongAdderViewController alloc] initWithYouTubeVideo:ytVideo
                                                                        thumbnail:img
                                                               existingSongToEdit:existingSong];
                [self.navigationController pushViewController:vc
                                                     animated:YES];
            } else {
                vc = [[YouTubeSongAdderViewController alloc] initWithYouTubeVideo:ytVideo
                                                                        thumbnail:img];
                [self.navigationController pushViewController:vc
                                                     animated:YES];
            }
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


#pragma mark - TableView custom view toggler/creator
- (void)showLoadingIndicatorInCenterOfTable:(BOOL)yes
{
    if(yes && loadingResultsIndicator == nil){
        self.tableView.scrollEnabled = NO;
        [self.searchBar removeFromSuperview];
        _viewOnTopOfTable = [[UIView alloc] initWithFrame:self.view.frame];
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        loadingResultsIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        float scale = MZLargeSpinnerDownScaleAmount;
        loadingResultsIndicator.transform = CGAffineTransformMakeScale(scale, scale);  //make smaller
        int indicatorSize = loadingResultsIndicator.frame.size.width;
        loadingResultsIndicator.frame = CGRectMake(screenFrame.size.width/2 - indicatorSize/2,
                                                   screenFrame.size.height/2 - indicatorSize/2 - [AppEnvironmentConstants navBarHeight],
                                                   indicatorSize,
                                                   indicatorSize);
        loadingResultsIndicator.color = [AppEnvironmentConstants appTheme].mainGuiTint;
        [loadingResultsIndicator startAnimating];
        
        [_viewOnTopOfTable addSubview:loadingResultsIndicator];
        self.tableView.tableHeaderView = _viewOnTopOfTable;
    } else if(!yes && loadingResultsIndicator != nil){
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
            if(self.waitingOnNextPageResults)
                return;
            
            NSTimeInterval secondsSinceLastPageLoaded = -1;
            BOOL newPagesNeverLoaded = (timeSinceLastPageLoaded) ? NO : YES;
            if(timeSinceLastPageLoaded != nil) {
                NSDate *now = [NSDate date];
                secondsSinceLastPageLoaded = [now timeIntervalSinceDate:timeSinceLastPageLoaded];
                now = nil;
            }
            if(secondsSinceLastPageLoaded > 1.5 || newPagesNeverLoaded) {
                [self userDidScrollToBottomOfTable];
            }
        }
    }
}

- (void)userDidScrollToBottomOfTable
{
    if(self.waitingOnNextPageResults || !self.displaySearchResults){
        return;
    }
    //covers an edge case where the user scrolls down to the bottom while the
    //search results are showing...and a crash occurs due to the fact that there are
    //no valid sections yet. and the "next page" delegate assumes it can just insert new rows lol.
    if(self.displaySearchResults && [self.tableView numberOfSections] == 0)
        return;

    self.waitingOnNextPageResults = YES;
    
    loadingNextPageSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    int footerHeight = 50;
    float indicatorSize = loadingNextPageSpinner.frame.size.width;
    loadingNextPageSpinner.frame = CGRectMake(self.view.frame.size.width/2 - indicatorSize/2,
                                               (footerHeight / 2.0) - (indicatorSize/2),
                                               indicatorSize,
                                               indicatorSize);
    loadingNextPageSpinner.color = [AppEnvironmentConstants appTheme].mainGuiTint;
    [loadingNextPageSpinner startAnimating];
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                             0,
                                                             self.view.frame.size.width,
                                                             footerHeight)];
    [footer addSubview:loadingNextPageSpinner];
    [self.tableView setTableFooterView:footer];

    //try to load more results
    [[YouTubeService sharedInstance] fetchNextYouTubePageUsingLastQueryString];
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

#pragma mark - Utils
- (NSInteger)rowNumFromIndexPathTakingAppRatingCellIntoAccount:(NSIndexPath *)indexPath
{
    NSInteger ytVideoResultsIndex = -1;
    if(_canShowAppRatingCell) {
        ytVideoResultsIndex = (indexPath.row >= APP_RATING_CELL_ROW_NUM) ?
        indexPath.row -1 : indexPath.row;
    } else {
        ytVideoResultsIndex = indexPath.row;
    }
    return ytVideoResultsIndex;
}

- (void)hideAppRatingCell
{
    NSAssert(_canShowAppRatingCell, @"Was asked to hide app rating cell but it's not showing!");
    [self performSelector:@selector(hideAppRatingCellDelayed) withObject:nil afterDelay:0.22];
}
- (void)hideAppRatingCellDelayed
{
    [self.tableView beginUpdates];
    NSArray *paths = @[[NSIndexPath indexPathForRow:APP_RATING_CELL_ROW_NUM inSection:0]];
    [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    _canShowAppRatingCell = NO;
    [self.tableView endUpdates];
}

#pragma mark - Replacement Object fetching
- (NSManagedObject *)coreDataObjectFromManagedObjId:(NSManagedObjectID *)objId
{
    __block NSManagedObject *coreDataObj;
    
    __unsafe_unretained NSManagedObjectID *weakObjId = objId;
    NSManagedObjectContext *context = [CoreDataManager context];
    [context performBlockAndWait:^{
        coreDataObj = [context existingObjectWithID:weakObjId error:nil];
    }];
    return coreDataObj;
}

@end
