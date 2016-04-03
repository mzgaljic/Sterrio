//
//  AppThemeTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/29/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AppThemeTableViewController.h"
#import "PreferredFontSizeUtility.h"
#import "AppDelegateSetupHelper.h"

#define Rgb2UIColor(r, g, b, a)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]
#define STEP_DURATION 0.001

@interface AppThemeTableViewController ()
{
    NSArray *themes;
    int currentlySelectedIndex;
    int defaultIndex;
    int currentRowHeights;
}
@end
@implementation AppThemeTableViewController

int const APP_THEME_COLORS_SECTION_NUM = 0;
int const RESET_DEFUALTS_SECTION_NUM = 1;

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"App Theme";
    defaultIndex = 0;
    [self initColorArrays];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"app theme color has possibly changed"
                                                        object:nil];
}

#pragma mark - UITableView Data source delegate stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(currentlySelectedIndex != defaultIndex)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == APP_THEME_COLORS_SECTION_NUM)
        return themes.count;
    else if(section == RESET_DEFUALTS_SECTION_NUM && currentlySelectedIndex != defaultIndex)
        return 1;
    else
        return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int rowHeight = [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
    currentRowHeights = rowHeight;
    return rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"app theme color cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId
                                                            forIndexPath:indexPath];
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    
    if(indexPath.section == APP_THEME_COLORS_SECTION_NUM)
    {
        cell.textLabel.text = [self themeNameForCellIndex:(int)indexPath.row];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
        cell.imageView.image = [self coloredImageForCellIndex:(int) indexPath.row];
        
        if(indexPath.row == currentlySelectedIndex)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                              size:fontSize];
    }
    else if(indexPath.section == RESET_DEFUALTS_SECTION_NUM)
    {
        cell.textLabel.text = @"Restore Default";
        cell.textLabel.textColor = ((MZAppTheme *)themes[currentlySelectedIndex]).mainGuiTint;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                              size:fontSize];
        cell.imageView.image = nil;
    }
    
    cell.tintColor = ((MZAppTheme *)themes[currentlySelectedIndex]).mainGuiTint;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int oldRow = currentlySelectedIndex;
    currentlySelectedIndex = (int)indexPath.row;
    
    if(indexPath.section == APP_THEME_COLORS_SECTION_NUM)
    {
        BOOL displayRestoreDefaults = (currentlySelectedIndex != defaultIndex
                                       && [self.tableView numberOfSections] != 2);
        
        BOOL deleteRestoreDefaults = (currentlySelectedIndex == defaultIndex
                                      && oldRow != currentlySelectedIndex);
        
        NSArray *paths;
        
        [self.tableView beginUpdates];
        if(displayRestoreDefaults){
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALTS_SECTION_NUM]
                          withRowAnimation:UITableViewRowAnimationFade];
            
            paths = @[
                      [NSIndexPath indexPathForRow:oldRow inSection:APP_THEME_COLORS_SECTION_NUM],
                      indexPath,
                      [NSIndexPath indexPathForItem:0 inSection:RESET_DEFUALTS_SECTION_NUM]
                      ];
        }
        if(deleteRestoreDefaults){
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALTS_SECTION_NUM]
                          withRowAnimation:UITableViewRowAnimationFade];
            paths = @[
                      [NSIndexPath indexPathForRow:oldRow inSection:APP_THEME_COLORS_SECTION_NUM],
                      indexPath
                      ];
        }
        [self.tableView endUpdates];
        
        if(paths == nil){
            if([self.tableView numberOfSections] != 1){
                paths = @[
                          [NSIndexPath indexPathForRow:oldRow inSection:APP_THEME_COLORS_SECTION_NUM],
                          indexPath,
                          [NSIndexPath indexPathForItem:0 inSection:RESET_DEFUALTS_SECTION_NUM]
                          ];
            } else{
                paths = @[
                          [NSIndexPath indexPathForRow:oldRow inSection:APP_THEME_COLORS_SECTION_NUM],
                          indexPath
                          ];
            }
        }
        
        [self.tableView beginUpdates];
        //doing this to preserve the nice slide-in animation for the second section.
        if(displayRestoreDefaults)
            [self.tableView reloadRowsAtIndexPaths:paths
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        else
            [self.tableView reloadRowsAtIndexPaths:paths
                                  withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
    else if(indexPath.section == RESET_DEFUALTS_SECTION_NUM)
    {
        int newRow = (int)indexPath.row;
        
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALTS_SECTION_NUM]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        [self.tableView beginUpdates];
        NSArray *paths = @[
                           [NSIndexPath indexPathForRow:oldRow
                                              inSection:APP_THEME_COLORS_SECTION_NUM],
                           [NSIndexPath indexPathForRow:newRow
                                              inSection:APP_THEME_COLORS_SECTION_NUM]
                           ];
        
        [self.tableView reloadRowsAtIndexPaths:paths
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    
    //MZAppTheme *oldTheme = [AppEnvironmentConstants appTheme];
    MZAppTheme *newTheme = themes[indexPath.row];
    [AppEnvironmentConstants setAppTheme:newTheme saveInUserDefaults:NO];
    [AppDelegateSetupHelper setGlobalFontsAndColorsForAppGUIComponents];
    UIColor *newMainColor = newTheme.mainGuiTint;
    
    //update status bar color based on app theme settings
    if(newTheme.useWhiteStatusBar) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    } else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }

    CGRect navBarFrame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.bounds.size.height + [AppEnvironmentConstants statusBarHeight]);
    UIImage *navBarImage = [AppEnvironmentConstants navBarBackgroundImageFromFrame:navBarFrame];
    
    //animate the background image change.
    CATransition *transition = [CATransition animation];
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    transition.type = kCATransitionFade;
    transition.duration = 0.5;
    [self.navigationController.navigationBar.layer addAnimation:transition forKey:nil];

    //update nav bar gradient
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBackgroundImage:navBarImage
                                                  forBarMetrics:UIBarMetricsDefault];
    
    //also update nav bar text for this particular nav controller (the method above that sets
    //global font colors doesn't work on this vc for some reason.)
    //nav bar attributes
    self.navigationController.navigationBar.tintColor = newTheme.navBarToolbarTextTint;
    UIFont *navBarFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:20];
    NSDictionary *navBarTitleAttributes = @{
                                            NSForegroundColorAttributeName : newTheme.navBarToolbarTextTint,
                                            NSFontAttributeName : navBarFont
                                            };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleAttributes;
    
    //update tab bar item text color
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : newTheme.contrastingTextColor }
                                             forState:UIControlStateNormal];
    
    [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
}


#pragma mark - Helpers
- (void)initColorArrays
{
    themes = [MZAppTheme allAppThemes];
    
    MZAppTheme *currentTheme = [AppEnvironmentConstants appTheme];
    for(int i = 0; i < themes.count; i++)
    {
        if([currentTheme equalToAppTheme:themes[i]]){
            currentlySelectedIndex = i;
            break;
        }
    }
}

- (UIImage *)coloredImageForCellIndex:(int)anIndex
{
    UIColor *aColor = ((MZAppTheme *)themes[anIndex]).mainGuiTint;
    int edgePadding = 8;
    
    return [UIImage imageWithColor:aColor
                             width:currentRowHeights - edgePadding
                            height:currentRowHeights - edgePadding];
}

- (NSString *)themeNameForCellIndex:(int)index
{
    return ((MZAppTheme *)themes[index]).themeName;
}

@end
