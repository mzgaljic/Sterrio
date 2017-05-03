//
//  StreamQualityPickerTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/29/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "StreamQualityPickerTableViewController.h"
#import "PreferredFontSizeUtility.h"

@interface StreamQualityPickerTableViewController ()
{
    short currentStreamQualitySelection;
}
@end
@implementation StreamQualityPickerTableViewController

int const STREAM_QUALITY_OPTIONS_SECTION_NUM = 0;
int const RESET_DEFUALT_SECTION_NUM = 1;

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    if(self.streamType == VIDEO_QUALITY_STREAM_TYPE_Cellular){
        self.title = @"Cellular Playback Quality";
        currentStreamQualitySelection = [AppEnvironmentConstants preferredCellularStreamSetting];
    }
    else if(self.streamType == VIDEO_QUALITY_STREAM_TYPE_Wifi){
        self.title = @"Wifi Playback Quality";
        currentStreamQualitySelection = [AppEnvironmentConstants preferredWifiStreamSetting];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(self.streamType == VIDEO_QUALITY_STREAM_TYPE_Cellular){
        [AppEnvironmentConstants setPreferredCellularStreamSetting:currentStreamQualitySelection];
    }
    else if(self.streamType == VIDEO_QUALITY_STREAM_TYPE_Wifi){
        [AppEnvironmentConstants setPreferredWifiStreamSetting:currentStreamQualitySelection];
    }
}

#pragma mark - UITableView Data source delegate stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(currentStreamQualitySelection != self.defaultStreamSetting)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == STREAM_QUALITY_OPTIONS_SECTION_NUM)
        return self.streamQualityOptions.count;
    else if(section == RESET_DEFUALT_SECTION_NUM
            && currentStreamQualitySelection != self.defaultStreamSetting)
        return 1;
    else
        return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"stream quality item cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId
                                                            forIndexPath:indexPath];
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    
    if(indexPath.section == STREAM_QUALITY_OPTIONS_SECTION_NUM)
    {
        NSNumber *obj = self.streamQualityOptions[indexPath.row];
        short qualityForRow = [obj shortValue];
        cell.textLabel.text = [NSString stringWithFormat:@"%ip", qualityForRow];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.detailTextLabel.text = nil;
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        if(qualityForRow == currentStreamQualitySelection)
            cell.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
        else
            cell.tintColor = [UIColor clearColor];

        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                              size:fontSize];
    }
    else if(indexPath.section == RESET_DEFUALT_SECTION_NUM)
    {
        cell.textLabel.text = @"Restore Default";
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                              size:fontSize];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber *oldQuality = [NSNumber numberWithShort:currentStreamQualitySelection];
    int oldRow = (int)[self.streamQualityOptions indexOfObject:oldQuality];
    
    if(indexPath.section == STREAM_QUALITY_OPTIONS_SECTION_NUM)
    {
        short streamQualityBeforeCellTap = currentStreamQualitySelection;
        NSNumber *obj = self.streamQualityOptions[indexPath.row];
        currentStreamQualitySelection = [obj shortValue];
        BOOL displayRestoreDefaults = (currentStreamQualitySelection != self.defaultStreamSetting
                                       && [self.tableView numberOfSections] != 2);
        
        BOOL deleteRestoreDefaults = (currentStreamQualitySelection == self.defaultStreamSetting
                                      && streamQualityBeforeCellTap != currentStreamQualitySelection);
        
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
                                              inSection:STREAM_QUALITY_OPTIONS_SECTION_NUM],
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
        currentStreamQualitySelection = self.defaultStreamSetting;
        NSNumber *obj = [NSNumber numberWithInt:self.defaultStreamSetting];
        int newRow = (int)[self.streamQualityOptions indexOfObject:obj];
        
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:RESET_DEFUALT_SECTION_NUM]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        [self.tableView beginUpdates];
        NSArray *paths = @[
                           [NSIndexPath indexPathForRow:oldRow
                                              inSection:STREAM_QUALITY_OPTIONS_SECTION_NUM],
                           [NSIndexPath indexPathForRow:newRow
                                              inSection:STREAM_QUALITY_OPTIONS_SECTION_NUM]
                           ];
        
        [self.tableView reloadRowsAtIndexPaths:paths
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

@end
