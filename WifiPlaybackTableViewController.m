//
//  WifiPlaybackTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/29/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "WifiPlaybackTableViewController.h"
#import "PreferredFontSizeUtility.h"

@interface WifiPlaybackTableViewController ()
{
    NSArray *wifiQualityOptions;
    short currentWifiQualitySelection;
}
@end
@implementation WifiPlaybackTableViewController

short const defaultWifiQuality = 720;
int const WIFI_QUALITY_OPTIONS_SECTION_NUM = 0;
int const RESET_DEFUALT_SECTION_NUM = 1;

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Wifi Playback Quality";
    wifiQualityOptions = @[@240, @360, @720];
    currentWifiQualitySelection = [AppEnvironmentConstants preferredWifiStreamSetting];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [AppEnvironmentConstants setPreferredWifiStreamSetting:currentWifiQualitySelection];
}

#pragma mark - UITableView Data source delegate stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(currentWifiQualitySelection != defaultWifiQuality)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == WIFI_QUALITY_OPTIONS_SECTION_NUM)
        return wifiQualityOptions.count;
    else if(section == RESET_DEFUALT_SECTION_NUM && currentWifiQualitySelection != defaultWifiQuality)
        return 1;
    else
        return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int minHeight = [AppEnvironmentConstants minimumSongCellHeight];
    int height = [AppEnvironmentConstants preferredSongCellHeight] * 0.75;
    if(height < minHeight)
        height = minHeight;
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == WIFI_QUALITY_OPTIONS_SECTION_NUM)
        return [UIScreen mainScreen].bounds.size.height * 0.06;
    else
        return [UIScreen mainScreen].bounds.size.height * 0.13;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"wifi quality item cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId
                                                            forIndexPath:indexPath];
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    
    if(indexPath.section == WIFI_QUALITY_OPTIONS_SECTION_NUM)
    {
        NSNumber *obj = wifiQualityOptions[indexPath.row];
        short qualityForRow = [obj shortValue];
        cell.textLabel.text = [NSString stringWithFormat:@"%ip", qualityForRow];
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
        
        if(qualityForRow == currentWifiQualitySelection)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                              size:fontSize];
    }
    else if(indexPath.section == RESET_DEFUALT_SECTION_NUM)
    {
        cell.textLabel.text = @"Restore Default";
        cell.textLabel.textColor = [UIColor defaultAppColorScheme];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                              size:fontSize];
    }
    
    cell.tintColor = [UIColor defaultAppColorScheme];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber *oldQuality = [NSNumber numberWithShort:currentWifiQualitySelection];
    int oldRow = (int)[wifiQualityOptions indexOfObject:oldQuality];
    
    if(indexPath.section == WIFI_QUALITY_OPTIONS_SECTION_NUM)
    {
        short wifiQualityBeforeCellTap = currentWifiQualitySelection;
        NSNumber *obj = wifiQualityOptions[indexPath.row];
        currentWifiQualitySelection = [obj shortValue];
        BOOL displayRestoreDefaults = (currentWifiQualitySelection != defaultWifiQuality
                                       && [self.tableView numberOfSections] != 2);
        
        BOOL deleteRestoreDefaults = (currentWifiQualitySelection == defaultWifiQuality
                                      && wifiQualityBeforeCellTap != currentWifiQualitySelection);
        
        [self.tableView beginUpdates];
        if(displayRestoreDefaults){
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALT_SECTION_NUM]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        if(deleteRestoreDefaults){
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALT_SECTION_NUM]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView endUpdates];
        
        [self.tableView beginUpdates];
        NSArray *paths = @[
                           [NSIndexPath indexPathForRow:oldRow
                                              inSection:WIFI_QUALITY_OPTIONS_SECTION_NUM],
                           indexPath
                           ];
        //doing this to preserve the nice slide-in animation for the second section.
        if(displayRestoreDefaults)
            [self.tableView reloadRowsAtIndexPaths:paths
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        else
            [self.tableView reloadRowsAtIndexPaths:paths
                                  withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
    else if(indexPath.section == RESET_DEFUALT_SECTION_NUM)
    {
        currentWifiQualitySelection = defaultWifiQuality;
        NSNumber *obj = [NSNumber numberWithShort:defaultWifiQuality];
        int newRow = (int)[wifiQualityOptions indexOfObject:obj];
        
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALT_SECTION_NUM]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        [self.tableView beginUpdates];
        NSArray *paths = @[
                           [NSIndexPath indexPathForRow:oldRow
                                              inSection:WIFI_QUALITY_OPTIONS_SECTION_NUM],
                           [NSIndexPath indexPathForRow:newRow
                                              inSection:WIFI_QUALITY_OPTIONS_SECTION_NUM]
                           ];
        
        [self.tableView reloadRowsAtIndexPaths:paths
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

@end
