//
//  SettingsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SettingsTableViewController.h"

@interface SettingsTableViewController ()
@end

@implementation SettingsTableViewController
@synthesize boldSongSwitch = _boldSongSwitch, smartSortSwitch = _smartSortSwitch, syncSettingViaIcloudSwitch = _syncSettingViaIcloudSwitch;
static BOOL PRODUCTION_MODE;
static short const TOP_INSET_OF_TABLE = -22;
static short const BOTTOM_INSET_OF_TABLE = -45;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)viewDidLoad
{
    [self setProductionModeValue];
    [super viewDidLoad];
    
    //remove extra padding placed between first cell and navigation bar
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
        self.tableView.contentInset = UIEdgeInsetsMake(TOP_INSET_OF_TABLE, 0, BOTTOM_INSET_OF_TABLE, 0);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)convertFontSizeToString
{
    short x = [AppEnvironmentConstants preferredSizeSetting];
    switch (x)
    {
        case 1:     return @"1";
        case 2:     return @"2";
        case 3:     return @"3";
        case 4:     return @"4";
        case 5:     return @"5";
        case 6:     return @"6";
        default:    return @"Error has occured";
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 4 + 3;  //4 sections used for actual content, 3 are for padding
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return @"iCloud";
        case 1:     return @"Media Quality";
        case 2:     return @"Presentability";
        case 3:     return @"Sorting";
        default:    return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return nil;
        case 1:     return @"Set the preferred playback quality for each connection type.";
        case 2:     return @"Changing Relative Font Size will decrease or increase the font used in the library.";
        case 3:     return @"Enabling \"Smart\" Alphabetical Sort changes the way your library content is sorted. The words (a/an/the) are ignored.";
        default:    return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return 1;
        case 1:     return 2;
        case 2:     return 2;
        case 3:     return 1;
        default:    return -1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailCell" forIndexPath:indexPath];
    // Configure the cell...
    if(indexPath.section == 0){
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Sync Settings Via iCloud";
                //setup toggle switch
                _syncSettingViaIcloudSwitch = [[UISwitch alloc] init];
                
                [_syncSettingViaIcloudSwitch setOn:[AppEnvironmentConstants icloudSettingsSync] animated:NO];
                cell.accessoryView = [[UIView alloc] initWithFrame:_syncSettingViaIcloudSwitch.frame];
                [cell.accessoryView addSubview:_syncSettingViaIcloudSwitch];
                
                cell.detailTextLabel.text = @"";
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                
                [_syncSettingViaIcloudSwitch addTarget:self action:@selector(icloudSyncSwitchToggled:)forControlEvents:UIControlEventValueChanged];
                break;
        }
    } else if(indexPath.section == 1){
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Wifi Stream Quality";
                cell.detailTextLabel.text = @"value here";
                break;
            case 1:
                cell.textLabel.text = @"Cellular Stream Quality";
                cell.detailTextLabel.text = @"value here";
                break;
        }
    } else if(indexPath.section == 2){
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Relative Font Size";
                cell.detailTextLabel.text = [self convertFontSizeToString];
                break;
            case 1:
                cell.textLabel.text = @"Bold Song Names";
                //setup toggle switch
                _boldSongSwitch = [[UISwitch alloc] init];
                [_boldSongSwitch setOn:[AppEnvironmentConstants boldSongNames] animated:NO];
                cell.accessoryView = [[UIView alloc] initWithFrame:_boldSongSwitch.frame];
                [cell.accessoryView addSubview:_boldSongSwitch];
                cell.detailTextLabel.text = @"";
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                
                [_boldSongSwitch addTarget:self action:@selector(boldSongsSwitchToggled:)forControlEvents:UIControlEventValueChanged];
                break;
        }
    } else if(indexPath.section == 3){
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"\"Smart\" Alphabetical Sort";
                //setup toggle switch
                _smartSortSwitch = [[UISwitch alloc] init];
                [_smartSortSwitch setOn:[AppEnvironmentConstants smartAlphabeticalSort] animated:NO];
                cell.accessoryView = [[UIView alloc] initWithFrame:_smartSortSwitch.frame];
                [cell.accessoryView addSubview:_smartSortSwitch];
                cell.detailTextLabel.text = @"";
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                
                [_smartSortSwitch addTarget:self action:@selector(smartSortSwitchToggled:)forControlEvents:UIControlEventValueChanged];
                break;
        }
    }
    return cell;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - toggle switch ibActions
- (IBAction)icloudSyncSwitchToggled:(id)sender
{
    //update settings
    [AppEnvironmentConstants set_iCloudSettingsSync:_syncSettingViaIcloudSwitch.on];
}

- (IBAction)boldSongsSwitchToggled:(id)sender
{
    //update settings
    [AppEnvironmentConstants setBoldSongNames:_boldSongSwitch.on];
}

- (IBAction)smartSortSwitchToggled:(id)sender
{
    //update settings
    [AppEnvironmentConstants setSmartAlphabeticalSort:_smartSortSwitch.on];
}

@end
