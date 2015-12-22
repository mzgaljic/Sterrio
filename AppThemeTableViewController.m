//
//  AppThemeTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/29/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AppThemeTableViewController.h"
#import "PreferredFontSizeUtility.h"

#define Rgb2UIColor(r, g, b, a)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]
#define STEP_DURATION 0.001

@interface AppThemeTableViewController ()
{
    NSArray *tableColors;
    NSArray *tableColorNames;
    NSArray *actualColors;
    int currentlySelectedIndex;
    int defaultIndex;
    int currentRowHeights;
    
    NSOperationQueue *operationQueue;
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
        return tableColors.count;
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
    if(section == APP_THEME_COLORS_SECTION_NUM)
        return [UIScreen mainScreen].bounds.size.height * 0.06;
    else
        return [UIScreen mainScreen].bounds.size.height * 0.13;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"app theme color cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId
                                                            forIndexPath:indexPath];
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    
    if(indexPath.section == APP_THEME_COLORS_SECTION_NUM)
    {
        cell.textLabel.text = tableColorNames[indexPath.row];
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
        cell.textLabel.textColor = actualColors[currentlySelectedIndex];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                              size:fontSize];
        cell.imageView.image = nil;
    }
    
    cell.tintColor = actualColors[currentlySelectedIndex];
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
    
    UIColor *oldColor = [UIColor defaultAppColorScheme];
    UIColor *newColor = actualColors[indexPath.row];
    [AppEnvironmentConstants setAppTheme:newColor];
    
    if(operationQueue == nil)
        operationQueue = [[NSOperationQueue alloc] init];
    
    [operationQueue cancelAllOperations];
    __weak AppThemeTableViewController *weakself = self;
    NSOperation *newOperation = nil;
    newOperation = [NSBlockOperation blockOperationWithBlock:^{
        [weakself animateNavigationBarFromColor:oldColor
                                        toColor:newColor
                                       duration:0.5
                                      operation:newOperation];
    }];
    
    [operationQueue addOperation:newOperation];
}


#pragma mark - Helpers
- (void)initColorArrays
{
    tableColors = @[
                    //orange
                    Rgb2UIColor(227, 136, 91, 1),
                    
                    //green
                    Rgb2UIColor(97, 131, 111, 1),
                    
                    //pink
                    Rgb2UIColor(237, 138, 182, 1),
                    
                    //blue
                    Rgb2UIColor(89, 130, 196, 1),
                    
                    //purple
                    Rgb2UIColor(127, 121, 176, 1),
                    
                    //yellow
                    Rgb2UIColor(249, 205, 90, 1)
                    ];
    
    tableColorNames = @[
                        @"Vibrant Orange",
                        @"Forest Green",
                        @"Bubblegum Pink",
                        @"Mighty Blue",
                        @"Dashing Purple",
                        @"Dandelion Yellow"
                        ];
    
    actualColors = [AppEnvironmentConstants appThemeColors];
    
    UIColor *aColor = [UIColor defaultAppColorScheme];
    for(int i = 0; i < actualColors.count; i++)
    {
        if([self color:aColor isEqualToColor:actualColors[i] withTolerance:0.15]){
            currentlySelectedIndex = i;
            break;
        }
    }
}

- (UIImage *)coloredImageForCellIndex:(int)anIndex
{
    UIColor *aColor = tableColors[anIndex];
    int edgePadding = 8;
    
    return [UIImage imageWithColor:aColor
                             width:currentRowHeights - edgePadding
                            height:currentRowHeights - edgePadding];
}

- (void)animateNavigationBarFromColor:(UIColor *)fromColor
                              toColor:(UIColor *)toColor
                             duration:(NSTimeInterval)duration
                            operation:(NSOperation *)thisOperation
{
    if(thisOperation.isCancelled)
        return;
    
    NSUInteger steps = duration / STEP_DURATION;
    
    CGFloat fromRed;
    CGFloat fromGreen;
    CGFloat fromBlue;
    CGFloat fromAlpha;
    
    [fromColor getRed:&fromRed green:&fromGreen blue:&fromBlue alpha:&fromAlpha];
    
    if(thisOperation.isCancelled)
        return;
    
    CGFloat toRed;
    CGFloat toGreen;
    CGFloat toBlue;
    CGFloat toAlpha;
    
    [toColor getRed:&toRed green:&toGreen blue:&toBlue alpha:&toAlpha];
    
    CGFloat diffRed = toRed - fromRed;
    CGFloat diffGreen = toGreen - fromGreen;
    CGFloat diffBlue = toBlue - fromBlue;
    CGFloat diffAlpha = toAlpha - fromAlpha;
    
    if(thisOperation.isCancelled)
        return;
    
    NSMutableArray *colorArray = [NSMutableArray array];
    
    [colorArray addObject:fromColor];
    
    for (NSUInteger i = 0; i < steps - 1; ++i) {
        CGFloat red = fromRed + diffRed / steps * (i + 1);
        CGFloat green = fromGreen + diffGreen / steps * (i + 1);
        CGFloat blue = fromBlue + diffBlue / steps * (i + 1);
        CGFloat alpha = fromAlpha + diffAlpha / steps * (i + 1);
        
        UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [colorArray addObject:color];
    }
    
    if(thisOperation.isCancelled)
        return;
    
    [colorArray addObject:toColor];
    
    [self animateWithArray:colorArray operation:thisOperation];
}

- (void)animateWithArray:(NSMutableArray *)array operation:(NSOperation *)thisOperation
{
    NSUInteger counter = 0;
    
    if(thisOperation.isCancelled)
        return;
    
    for(int i = 0; i < array.count; i++){
        UIColor *aColor = array[i];
        
        if(i == array.count-1){
            //update again in case user tapped a different cell in the meantime.
            [UIColor defaultAppColorScheme:aColor];
        }
        
        if(thisOperation.isCancelled)
            return;
        
        double delayInSeconds = STEP_DURATION * counter++;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:STEP_DURATION animations:^{
                self.navigationController.navigationBar.barTintColor = aColor;
            }];
        });
    }
}

- (BOOL)color:(UIColor *)color1 isEqualToColor:(UIColor *)color2 withTolerance:(CGFloat)tolerance
{
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    return
    fabs(r1 - r2) <= tolerance &&
    fabs(g1 - g2) <= tolerance &&
    fabs(b1 - b2) <= tolerance &&
    fabs(a1 - a2) <= tolerance;
}

@end
