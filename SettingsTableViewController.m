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
static short const TOP_INSET_OF_TABLE = -20;

static const int FONT_SIZE_PICKER_TAG = 105;
static const int WIFI_STREAM_PICKER_TAG = 106;
static const int CELL_STREAM_PICKER_TAG = 107;


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
        self.tableView.contentInset = UIEdgeInsetsMake(TOP_INSET_OF_TABLE, 0, 0, 0);
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
    return 4;  //4 sections used for actual content
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return @"";
        case 1:     return @"Media Quality";
        case 2:     return @"Presentation";
        case 3:     return @"Sorting";
        default:    return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return @"Sync settings to your remaining Apple devices.";
        case 1:     return @"The preferred playback quality for each connection type.";
        case 2:     return @"'Bold Names' changes song, album, artist, playlist, and genre names wherever possible. (enabled by default)";
        case 3:     return @"Enabling \"Smart\" Alphabetical Sort changes the way library content is sorted. The words (a/an/the) are ignored.";
        default:    return nil;
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
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%hup",[AppEnvironmentConstants preferredWifiStreamSetting]];
                break;
            case 1:
                cell.textLabel.text = @"Cellular Stream Quality";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%hup",[AppEnvironmentConstants preferredCellularStreamSetting]];
                break;
        }
    } else if(indexPath.section == 2){
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Font Size";
                cell.detailTextLabel.text = [self convertFontSizeToString];
                break;
            case 1:
                cell.textLabel.text = @"Bold Names";
                //setup toggle switch
                _boldSongSwitch = [[UISwitch alloc] init];
                [_boldSongSwitch setOn:[AppEnvironmentConstants boldNames] animated:NO];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1){
        switch (indexPath.row)
        {
            case 0:
                _lastTappedPickerCell = WIFI_STREAM_PICKER_TAG;
                [self launchAlertViewWithPicker];
                break;
            case 1:
                _lastTappedPickerCell = CELL_STREAM_PICKER_TAG;
                [self launchAlertViewWithPicker];
                break;
        }
    } else if(indexPath.section == 2){
        if(indexPath.row == 0){
            _lastTappedPickerCell = FONT_SIZE_PICKER_TAG;
            [self launchAlertViewWithPicker];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - AlertView with embedded pickerView
- (void)launchAlertViewWithPicker
{
    // Here we need to pass a full frame
    CustomIOS7AlertView *alertView = [[CustomIOS7AlertView alloc] init];
    [alertView setContainerView:[self createPickerView]];
    // Modify the parameters
    [alertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Done", nil]];
    [alertView setDelegate:self];
    [alertView setUseMotionEffects:true];
    [alertView show];  //launch dialog
}

NSArray *fontOptions;
NSArray *WifiStreamOptions;
NSArray *CellStreamOptions;

- (UIView *)createPickerView
{
    UIPickerView *picker=[UIPickerView alloc];
    
    int row = -1;
    switch (_lastTappedPickerCell)
    {
        case FONT_SIZE_PICKER_TAG:
            picker = [picker initWithFrame:CGRectMake(0, 0, 200, 250)];
            fontOptions = @[@"1",@"2",@"3 (default)",@"4",@"5",@"6"];
            row = ([AppEnvironmentConstants preferredSizeSetting] -1);
            break;
        case WIFI_STREAM_PICKER_TAG:
        {
            picker = [picker initWithFrame:CGRectMake(0, 0, 230, 300)];
            WifiStreamOptions = @[@"240p",@"360p", @"480p",@"720p (default)",@"1080p"];
            short wifiSetting = [AppEnvironmentConstants preferredWifiStreamSetting];
            NSString *findMeInArray;
            if(wifiSetting == 720)
                findMeInArray = [NSString stringWithFormat:@"%hup (default)",wifiSetting];
            else
                findMeInArray = [NSString stringWithFormat:@"%hup",wifiSetting];
            row = (int)[WifiStreamOptions indexOfObject:findMeInArray];
            break;
        }
        case CELL_STREAM_PICKER_TAG:
            picker = [picker initWithFrame:CGRectMake(0, 0, 230, 300)];
            CellStreamOptions = @[@"240p",@"360p (default)", @"480p",@"720p"];
            short cellSetting = [AppEnvironmentConstants preferredCellularStreamSetting];
            NSString *findMeInArray;
            if(cellSetting == 360)
                findMeInArray = [NSString stringWithFormat:@"%hup (default)",cellSetting];
            else
                findMeInArray = [NSString stringWithFormat:@"%hup",cellSetting];
            row = (int)[CellStreamOptions indexOfObject:findMeInArray];
            break;
    }
    picker.dataSource = self;
    picker.delegate = self;
    [picker selectRow:row inComponent:0 animated:NO];
    return picker;
}

- (void)customIOS7dialogButtonTouchUpInside:(CustomIOS7AlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    if(buttonIndex == 0){
        switch (_lastTappedPickerCell)
        {
            case FONT_SIZE_PICKER_TAG:
                [AppEnvironmentConstants setPreferredSizeSetting:_lastSelectedFontSize];
                break;
            case WIFI_STREAM_PICKER_TAG:
                if(_lastSelectedWifiQuality != 0)  //if 0, then no value was actually picked.
                    [AppEnvironmentConstants setPreferredWifiStreamSetting:_lastSelectedWifiQuality];
                break;
            case CELL_STREAM_PICKER_TAG:
                if(_lastSelectedCellQuality != 0)
                    [AppEnvironmentConstants setPreferredCellularStreamSetting:_lastSelectedCellQuality];
                break;
            default:
                break;
        }
    }
    [alertView close];
    [self.tableView reloadData];
}


#pragma mark - Actual UiPickerView methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (_lastTappedPickerCell)
    {
        case FONT_SIZE_PICKER_TAG:      return [fontOptions count];
        case WIFI_STREAM_PICKER_TAG:    return [WifiStreamOptions count];
        case CELL_STREAM_PICKER_TAG:    return [CellStreamOptions count];
        default:    return -1;
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (_lastTappedPickerCell)
    {
        case FONT_SIZE_PICKER_TAG:
            _lastSelectedFontSize = (short)[[fontOptions objectAtIndex:row] intValue];
            break;
        case WIFI_STREAM_PICKER_TAG:
        {
            NSString *resolution = [WifiStreamOptions objectAtIndex:row];
            if([resolution isEqualToString:@"720p (default)"])
                _lastSelectedWifiQuality = 720;
            else                                   //this one liner removes the last char (the 'p' after the resolution value)
                _lastSelectedWifiQuality = (short)[[resolution substringToIndex:resolution.length-(resolution.length>0)] intValue];
            break;
        }
        case CELL_STREAM_PICKER_TAG:
        {
            NSString *resolution = [CellStreamOptions objectAtIndex:row];
            if([resolution isEqualToString:@"360p (default)"])
                _lastSelectedCellQuality = 360;
            else
                _lastSelectedCellQuality = (short)[[resolution substringToIndex:resolution.length-(resolution.length>0)] intValue];
            break;
        }
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel* textView = (UILabel*)view;
    if (!textView){
        textView = [[UILabel alloc] init];
        [textView setTextAlignment:NSTextAlignmentCenter];
        textView.font = [UIFont systemFontOfSize:26];
        textView.adjustsFontSizeToFitWidth = YES;
    }
    switch (_lastTappedPickerCell)
    {
        case FONT_SIZE_PICKER_TAG:
            textView.text = [fontOptions objectAtIndex:row];
            break;
        case WIFI_STREAM_PICKER_TAG:
            textView.text = [WifiStreamOptions objectAtIndex:row];
            break;
        case CELL_STREAM_PICKER_TAG:
            textView.text = [CellStreamOptions objectAtIndex:row];
            break;
        default: textView.text = @"An error has occured. :(";
    }
    return textView;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}


#pragma mark - Toggle switch ibActions
- (IBAction)icloudSyncSwitchToggled:(id)sender
{
    //update settings
    [AppEnvironmentConstants set_iCloudSettingsSync:_syncSettingViaIcloudSwitch.on];
}

- (IBAction)boldSongsSwitchToggled:(id)sender
{
    //update settings
    [AppEnvironmentConstants setBoldNames:_boldSongSwitch.on];
}

- (IBAction)smartSortSwitchToggled:(id)sender
{
    //update settings
    [AppEnvironmentConstants setSmartAlphabeticalSort:_smartSortSwitch.on];
    [Song reSortModel];
}

@end
