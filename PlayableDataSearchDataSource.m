
//
//  PlayableDataSearchDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableDataSearchDataSource.h"
#import "NSString+WhiteSpace_Utility.h"
#import "PreferredFontSizeUtility.h"
#import "CoreDataManager.h"
#import "MySearchBar.h"
#import "PlayableBaseDataSource.h"
#import "playableDataSearchDataSourceDelegate.h"

@interface PlayableDataSearchDataSource ()
{
    UILabel *tableViewEmptyMsgLabel;
    BOOL keyboardIsVisible;
    int emptyTableMsgKeyboardPadding;
}
@property (nonatomic, strong) UITableView *tableView;
//naming of these two delegate protocols could be significantly improved. very confusing at the moment.
@property (nonatomic, assign) id <PlayableDataSearchDataSourceDelegate> playableDataSearchDataSourceDelegate;
@property (nonatomic, assign) id <SearchBarDataSourceDelegate> modelDataSourceSearchBarDelegate;
@end
@implementation PlayableDataSearchDataSource

#pragma mark - LifeCycle
- (void)dealloc
{
    self.tableView = nil;
    self.playableDataSearchDataSourceDelegate = nil;
    self.modelDataSourceSearchBarDelegate = nil;
    
    NSLog(@"%@ dealloced!", NSStringFromClass([self class]));
}

- (instancetype)initWithTableView:(UITableView *)tableView playableDataSearchDataSourceDelegate:(id<PlayableDataSearchDataSourceDelegate>)delegate1
      searchBarDataSourceDelegate:(id <SearchBarDataSourceDelegate>)delegate2
{
    if(self = [super init]){
        self.playableDataSearchDataSourceDelegate = delegate1;
        self.modelDataSourceSearchBarDelegate = delegate2;
        self.tableView = tableView;
        [self.playableDataSearchDataSourceDelegate searchResultsShouldBeDisplayed:NO];
        [self.playableDataSearchDataSourceDelegate searchResultsFromUsersQuery:[NSArray array]];
        
        keyboardIsVisible = NO;
        emptyTableMsgKeyboardPadding = [UIScreen mainScreen].bounds.size.height * 0.11;
    }
    return self;
}

#pragma mark - UISearchBarDelegate implementation
- (MySearchBar *)setUpSearchBar
{
    MySearchBar *searchBar;
    if([self.playableDataSearchDataSourceDelegate playableDataSourceEntireModelCount] > 0){
        //create search bar, add to viewController
        NSString *text = [self.modelDataSourceSearchBarDelegate placeholderTextForSearchBar];
        searchBar = [[MySearchBar alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 0)
                                       placeholderText:text];
        searchBar.delegate = self;
        self.tableView.tableHeaderView = searchBar;
    }
    return searchBar;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    keyboardIsVisible = NO;
    [self animateTableEmtpyLabelUp:NO];
}

//user tapped search box
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    keyboardIsVisible = YES;
    
    if(searchBar.text.length == 0)
        [self.playableDataSearchDataSourceDelegate searchResultsFromUsersQuery:[NSArray array]];
    
    //show the cancel button
    [searchBar setShowsCancelButton:YES animated:YES];
    [self.modelDataSourceSearchBarDelegate searchBarIsBecomingActive];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:[NSNumber numberWithBool:YES]];
    
    PlayableBaseDataSource *playableBaseDataSource = (PlayableBaseDataSource *)self.playableDataSearchDataSourceDelegate;
    BOOL oldDisplayResultsVal = playableBaseDataSource.displaySearchResults;
    [self.playableDataSearchDataSourceDelegate searchResultsShouldBeDisplayed:YES];
    
    if(! oldDisplayResultsVal){
        //user is now transitioning into the "search" mode
        [self.tableView reloadData];
    }
    
    [self animateTableEmtpyLabelUp:YES];
}

//user tapped "Search"
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //search results already appear as the user types. Just hide the keyboard...
    [searchBar resignFirstResponder];
    keyboardIsVisible = NO;
    [self.playableDataSearchDataSourceDelegate searchResultsShouldBeDisplayed:YES];
}

//User tapped "Cancel"
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.playableDataSearchDataSourceDelegate searchResultsShouldBeDisplayed:NO];
    keyboardIsVisible = NO;
    
    //dismiss search bar and hide cancel button
    [searchBar setShowsCancelButton:NO animated:YES];
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [self.modelDataSourceSearchBarDelegate searchBarIsBecomingInactive];
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:[NSNumber numberWithBool:NO]];
    
    [self removeEmptyTableUserMessage];
    [self.tableView reloadData];
}

//User typing as we speak, fetch latest results to populate results as they type
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.playableDataSearchDataSourceDelegate searchResultsFromUsersQuery:[NSArray array]];
    [self.playableDataSearchDataSourceDelegate searchResultsShouldBeDisplayed:YES];
    if(searchText.length == 0){
        [self.tableView reloadData];
        [self animateTableEmtpyLabelUp:YES];
        return;
    } else{
        [self removeEmptyTableUserMessage];
    }
    searchText = [searchText removeIrrelevantWhitespace];
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [self.playableDataSearchDataSourceDelegate fetchRequestForSearchBarQuery:searchText];
    
    if ([AppEnvironmentConstants isUserOniOS8OrAbove])
    {
        __weak PlayableDataSearchDataSource *weakself = self;
        NSAsynchronousFetchRequest *asynchronousFetchRequest =
        [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:request
                                                 completionBlock:^(NSAsynchronousFetchResult *result) {
                                                     
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         if (! result.operationError)
                                                         {
                                                             [weakself.playableDataSearchDataSourceDelegate searchResultsFromUsersQuery:result.finalResult];
                                                         }
                                                         [weakself.tableView reloadData];
                                                     });
                                                 }];
        [context executeRequest:asynchronousFetchRequest error:NULL];
    }
    else
    {
        NSArray *objs = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:nil]];
        [self.playableDataSearchDataSourceDelegate searchResultsFromUsersQuery:objs];
        [self.tableView reloadData];
    }
}

#pragma mark - Empty Table User Message stuff
- (void)displayEmptyTableUserMessageWithText:(NSString *)text
{
    UILabel *aLabel = (UILabel *)[self friendlyTableUserMessageWithText:text];
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    CGPoint newLabelCenter;
    if(((PlayableBaseDataSource *)self.playableDataSearchDataSourceDelegate).displaySearchResults == NO){
        newLabelCenter = self.tableView.backgroundView.center;
        newLabelCenter = CGPointMake(newLabelCenter.x, newLabelCenter.y);
    } else
        newLabelCenter = CGPointMake(self.tableView.backgroundView.center.x,
                                     self.tableView.backgroundView.center.y - emptyTableMsgKeyboardPadding);
    
    aLabel.center = newLabelCenter;
    aLabel.alpha = 0.3;
    [self.tableView.backgroundView addSubview:aLabel];
    [UIView animateWithDuration:0.4 animations:^{
        aLabel.alpha = 1;
    }];
    
}

- (UIView *)friendlyTableUserMessageWithText:(NSString *)text
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if(tableViewEmptyMsgLabel){
        [tableViewEmptyMsgLabel removeFromSuperview];
        tableViewEmptyMsgLabel = nil;
    }
    tableViewEmptyMsgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       self.tableView.bounds.size.width,
                                                                       self.tableView.bounds.size.height)];
    if(text == nil)
        text = @"";
    tableViewEmptyMsgLabel.text = text;
    tableViewEmptyMsgLabel.textColor = [UIColor darkGrayColor];
    //multi lines strings ARE possible, this is just a weird api detail
    tableViewEmptyMsgLabel.numberOfLines = 0;
    tableViewEmptyMsgLabel.textAlignment = NSTextAlignmentCenter;
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    tableViewEmptyMsgLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                  size:fontSize];
    [tableViewEmptyMsgLabel sizeToFit];
    return tableViewEmptyMsgLabel;
}

- (void)removeEmptyTableUserMessage
{
    [tableViewEmptyMsgLabel removeFromSuperview];
    self.tableView.backgroundView = nil;
    tableViewEmptyMsgLabel = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

#pragma mark - Changing interface based on keyboard
- (void)animateTableEmtpyLabelUp:(BOOL)animateUp
{
    if(tableViewEmptyMsgLabel)
    {
        UIView *backgroundView = self.tableView.backgroundView;
        float duration = 1;
        float delay = 0.3;
        float springDamping = 0.80;
        float initialVelocity = 0.5;
        
        //see if the center values are roughly the same...
        if(fabs(tableViewEmptyMsgLabel.center.y -  backgroundView.center.y) <= 20)
        {
            if(! animateUp)
                return;
            CGRect newLabelFrame = CGRectMake(tableViewEmptyMsgLabel.frame.origin.x,
                                              tableViewEmptyMsgLabel.frame.origin.y - emptyTableMsgKeyboardPadding,
                                              tableViewEmptyMsgLabel.frame.size.width,
                                              tableViewEmptyMsgLabel.frame.size.height);
            [UIView animateWithDuration:duration
                                  delay:delay
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:initialVelocity
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [tableViewEmptyMsgLabel setFrame:newLabelFrame];
                             }
                             completion:nil];
        }
        else
        {
            if(animateUp)
                return;
            [UIView animateWithDuration:duration
                                  delay:delay
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:initialVelocity
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 tableViewEmptyMsgLabel.center = backgroundView.center;
                             }
                             completion:nil];
        }
    }
}


@end
