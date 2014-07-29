//
//  SettingsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SettingsTableViewController.h"

@interface SettingsTableViewController ()
@property (nonatomic, strong) SDCAlertView *alertView;
@property (nonatomic, strong) UIImage *attachmentImage;
@property (nonatomic, strong) NSMutableArray *attachmentUIImages;
@property (nonatomic, assign) BOOL showEmailAlertView;
//@property (nonatomic, strong) UIImagePickerController *photoPicker;
@property (nonatomic, strong) ZCImagePickerController *photoPicker;
@end

@implementation SettingsTableViewController
@synthesize boldSongSwitch = _boldSongSwitch, smartSortSwitch = _smartSortSwitch, syncSettingViaIcloudSwitch = _syncSettingViaIcloudSwitch, attachmentImage = _attachmentImage, showEmailAlertView = _showEmailAlertView, photoPicker = _photoPicker, attachmentUIImages = _attachmentUIImages;

static BOOL PRODUCTION_MODE;
static short const TOP_INSET_OF_TABLE = -20;

static const int FONT_SIZE_PICKER_TAG = 105;
static const int WIFI_STREAM_PICKER_TAG = 106;
static const int CELL_STREAM_PICKER_TAG = 107;

//could go in AppEnvironmentConstants...
static NSString *BUG_REPORT_EMAIL;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)viewDidLoad
{
    [self setProductionModeValue];
    [super viewDidLoad];
    
    if(PRODUCTION_MODE)
        BUG_REPORT_EMAIL = @"example@example.com";
    else
        BUG_REPORT_EMAIL = @"mzgaljic@me.com";
    
    _attachmentUIImages = [NSMutableArray array];
    
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
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return @"";
        case 1:     return @"Media Quality";
        case 2:     return @"Appearance";
        case 3:     return @"Sorting";
        case 4:     return @"Help";
        default:    return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:     return @"Sync settings to your remaining Apple devices.";
        case 1:     return @"The preferred music video playback quality for each connection type.";
        case 2:     return @"'Bold Names' changes song, album, artist, playlist, and genre names to bold wherever possible. (enabled by default)";
        case 3:     return @"Enabled, \"Smart\" Alphabetical Sort changes the way library content is sorted; the words (a/an/the) are ignored. Disabled, library content is sorted in true alphabetical order.";
        case 4:     return @"A Software 'Bug' is unexpected app behavior.";
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
        case 4:     return 1;
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
    } else if(indexPath.section == 4){
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Report a Bug";
                cell.detailTextLabel.text = @"🐞";
                cell.accessoryView = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
                [self launchAlertViewWithPicker:WIFI_STREAM_PICKER_TAG];
                break;
            case 1:
                _lastTappedPickerCell = CELL_STREAM_PICKER_TAG;
                [self launchAlertViewWithPicker:CELL_STREAM_PICKER_TAG];
                break;
        }
    } else if(indexPath.section == 2){
        if(indexPath.row == 0){
            _lastTappedPickerCell = FONT_SIZE_PICKER_TAG;
            [self launchAlertViewWithPicker:FONT_SIZE_PICKER_TAG];
        }
    } else if(indexPath.section == 4){
        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Compose Email" delegate:self cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil otherButtonTitles:@"Attach a Screenshot",
                                @"Regular Email", nil];
        popup.tag = 1;
        [popup showInView:[UIApplication sharedApplication].keyWindow];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - AlertView with embedded pickerView
- (void)launchAlertViewWithPicker:(short)tag
{
    if(tag == FONT_SIZE_PICKER_TAG){
        _alertView = [[SDCAlertView alloc] initWithTitle:@"Font Size"
                                                 message:nil
                                                delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:@"Done", nil];
        [_alertView.contentView addSubview:[self createPickerView]];
        _alertView.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        _alertView.suggestedButtonFont = [UIFont boldSystemFontOfSize:16];
    } else{
        
        _alertView = [[SDCAlertView alloc] init];
        if(tag == CELL_STREAM_PICKER_TAG)
            _alertView.title = @"Cellular Stream Quality";
        else if(tag == WIFI_STREAM_PICKER_TAG)
            _alertView.title = @"Wifi Stream Quality";
        
        _alertView.delegate = self;
        [_alertView addButtonWithTitle:@"Done"];
        [_alertView.contentView addSubview:[self createPickerView]];
        _alertView.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        _alertView.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    }
    [_alertView show];
}

NSArray *fontOptions;
NSArray *WifiStreamOptions;
NSArray *CellStreamOptions;

- (UIView *)createPickerView
{
    UIPickerView *picker = [UIPickerView alloc];
    
    int row = -1;
    NSString *findMeInArray;
    
    //presetting the "lastSelected____" properties in case they don't change (user doesnt move uipickerview at all and just taps done)
    switch (_lastTappedPickerCell)
    {
        case FONT_SIZE_PICKER_TAG:
            picker = [picker initWithFrame:CGRectMake(0, 0, 260, 400)];
            fontOptions = @[@"1",@"2",@"3 (default)",@"4",@"5",@"6"];
            row = ([AppEnvironmentConstants preferredSizeSetting] -1);
            
            _lastSelectedFontSize = row + 1;
            break;
        case WIFI_STREAM_PICKER_TAG:
        {
            picker = [picker initWithFrame:CGRectMake(0, 0, 260, 400)];
            WifiStreamOptions = @[@"240p",@"360p", @"480p",@"720p (default)",@"1080p"];
            short wifiSetting = [AppEnvironmentConstants preferredWifiStreamSetting];
            if(wifiSetting == 720)
                findMeInArray = [NSString stringWithFormat:@"%hup (default)",wifiSetting];
            else
                findMeInArray = [NSString stringWithFormat:@"%hup",wifiSetting];
            row = (int)[WifiStreamOptions indexOfObject:findMeInArray];
            
            NSString *resolution = [WifiStreamOptions objectAtIndex:row];
            if([resolution isEqualToString:@"720p (default)"])
                _lastSelectedWifiQuality = 720;
            else                                   //this one liner removes the last char (the 'p' after the resolution value)
                _lastSelectedWifiQuality = (short)[[resolution substringToIndex:resolution.length-(resolution.length>0)] intValue];
            break;
        }
        case CELL_STREAM_PICKER_TAG:
            picker = [picker initWithFrame:CGRectMake(0, 0, 260, 400)];
            CellStreamOptions = @[@"240p",@"360p (default)", @"480p",@"720p"];
            short cellSetting = [AppEnvironmentConstants preferredCellularStreamSetting];
            if(cellSetting == 360)
                findMeInArray = [NSString stringWithFormat:@"%hup (default)",cellSetting];
            else
                findMeInArray = [NSString stringWithFormat:@"%hup",cellSetting];
            row = (int)[CellStreamOptions indexOfObject:findMeInArray];
            
            NSString *resolution = [CellStreamOptions objectAtIndex:row];
            if([resolution isEqualToString:@"360p (default)"])
                _lastSelectedCellQuality = 360;
            else
                _lastSelectedCellQuality = (short)[[resolution substringToIndex:resolution.length-(resolution.length>0)] intValue];
            break;
    }
    picker.dataSource = self;
    picker.delegate = self;
    [picker selectRow:row inComponent:0 animated:NO];
    return picker;
}

- (void)alertView:(SDCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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
    //[alertView close];
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
        {
            _lastSelectedFontSize = (short)[[fontOptions objectAtIndex:row] intValue];
            _alertView.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility
                                                                      hypotheticalLabelFontSizeForPreferredSize:_lastSelectedFontSize]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"settingFontPickerScrolled" object:nil];
            break;
        }
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
        //textView.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        textView.adjustsFontSizeToFitWidth = YES;
    }
    switch (_lastTappedPickerCell)
    {
        case FONT_SIZE_PICKER_TAG:
            if([AppEnvironmentConstants boldNames])
                textView.attributedText = [self boldAttributedStringWithString:[fontOptions objectAtIndex:row]
                                                                withFontSize:[PreferredFontSizeUtility
                                   hypotheticalLabelFontSizeForPreferredSize:(int)row+1] + 1.0];
            else{
                textView.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:(int)row + 1] + 1.0];
                textView.text = [fontOptions objectAtIndex:row];
            }
            break;
        case WIFI_STREAM_PICKER_TAG:
            textView.text = [WifiStreamOptions objectAtIndex:row];
            textView.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            break;
        case CELL_STREAM_PICKER_TAG:
            textView.text = [CellStreamOptions objectAtIndex:row];
            if([AppEnvironmentConstants preferredSizeSetting] >= 4)
                textView.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            else
                textView.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:4]];
            break;
        default: textView.text = @"An error has occured. :(";
    }
    return textView;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}

- (NSAttributedString *)boldAttributedStringWithString:(NSString *)aString withFontSize:(float)fontSize
{
    if(! aString)
        return nil;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:aString];
    [attributedText addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:NSMakeRange(0, [aString length])];
    return attributedText;
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
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else{
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
}

#pragma mark - BUG REPORT/EMAIL logic
- (void)launchEmailPicker
{
    _showEmailAlertView = NO;
    [self callMailComposer];
}

- (void)callMailComposer
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil){
        // We must always check whether the current device is configured for sending emails
        if ([mailClass canSendMail])
            [self displayComposerModalView];
        else
            [self launchMailAppOnDevice];
    }
    else
        [self launchMailAppOnDevice];
}

// Displays an email composition interface inside the application. Populates all the Mail fields.
-(void)displayComposerModalView
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    NSString *emailSubject = @"Bug Report [F M L]";
    [picker setSubject:emailSubject];

    // Set up recipients
    [picker setToRecipients:@[BUG_REPORT_EMAIL]];
    [picker setMessageBody:[self buildEmailBodyString] isHTML:NO];
    if(_attachmentUIImages.count > 0){
        int count = 1;
        for(UIImage *attachmentImage in _attachmentUIImages){
            [picker addAttachmentData:UIImagePNGRepresentation(attachmentImage) mimeType:@"image/png" fileName:[NSString stringWithFormat:@"image %i", count]];
            count++;
        }
        
        //completion block dismisses the photo picker only AFTER mail popup is dismissed
        //if dismissed before, it looks jump/laggy if a large pic was selected by user.
        //remember, _photoPicker presents mail since it is now on top of the stack
        [_photoPicker presentViewController:picker animated:YES completion: nil];
    }
    else
        //in this case, SettingsTableViewController is on top of stack. So it presents mail popup.
        [self presentViewController:picker animated:YES completion: nil];
    
    if(picker)
        picker = nil;
    
    _photoPicker = nil;
}

- (NSString *)buildEmailBodyString
{
    //\u2022 is Unicode for a bullet
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *body;
    if(_attachmentUIImages.count > 0)
        body = @"Try to provide as much information as possible.\n\nName the bug:\n\nLocation of issue:\n\nSeverity: (High/Medium/Low)\n\nReported By:\n\n=============\nDescription\n\u2022\n\nSteps To Reproduce Bug\n\u2022\n\nExpected result\n\u2022\n=============\ntime&date\n\nVersion: version#\n[End of bug report]\nScreenshot:";
    else
        body = @"Try to provide as much information as possible. Attaching screenshots is optional (but encouraged).\n\nName the bug:\n\nLocation of issue:\n\nSeverity: (High/Medium/Low)\n\nReported By:\n\n=============\nDescription\n\u2022\n\nSteps To Reproduce Bug\n\u2022\n\nExpected result\n\u2022\n=============\ntime&date\n\nVersion: version#\n[End of bug report]";
    body = [body stringByReplacingOccurrencesOfString:@"version#" withString:version];
    body = [body stringByReplacingOccurrencesOfString:@"time&date" withString:[self buildCurrentEstTimeString]];
    return body;
}

- (NSString *)buildCurrentEstTimeString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd/yy, hh:mmaa";
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *date = [dateFormatter dateFromString:dateString];  //right now date is in GMT +0:00
    
    // converts date to proper time zone, returns a string
    NSMutableString *returnMe = [NSMutableString stringWithString: [dateFormatter stringFromDate:date]];
    [returnMe appendString:@" EST"];
    return returnMe;
}

// Dismisses email composition gui when users tap Cancel or Send. Then it updates the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    NSString* alertMessage;
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            alertMessage = @"Your email is now being sent.\nThank You 😀";
            _showEmailAlertView = YES;
            break;
        case MFMailComposeResultFailed:
            alertMessage = @"Failed to send email.";
            _showEmailAlertView = YES;
            break;
        default:
            alertMessage = @"Could not send your email, please try again.";
            _showEmailAlertView = YES;
            break;
    }
    _attachmentUIImages = [NSMutableArray array];
    
    _alertView = [[SDCAlertView alloc] initWithTitle:@"Bug Report"
                                             message:alertMessage
                                            delegate:self
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles: nil];
    _alertView.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    _alertView.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    _alertView.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    
    //dismissed both modal view controllers (photo picker and mail)
    [self dismissViewControllerAnimated:YES completion:^void ()
                                                {
                                                    if(_showEmailAlertView)
                                                        [_alertView show];
                                                }];
}

// Launches the Mail application on the device (when does this occur?)
-(void)launchMailAppOnDevice
{
    NSMutableString *recipients = [NSMutableString stringWithString: @"mailto:"];
    [recipients appendString:BUG_REPORT_EMAIL];
    [recipients appendString:@"?cc=&subject="];
    NSString *body = @"&body=";
    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

#pragma mark - UIActionSheet methods (and image picker stuff)
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(popup.tag == 1){
        _photoPicker = nil;
        
        switch (buttonIndex)
        {
            case 0:
            {
                //start with fresh array
                _attachmentUIImages = [NSMutableArray array];
                
                _photoPicker = [[ZCImagePickerController alloc] init];
                _photoPicker.imagePickerDelegate = self;
                _photoPicker.maximumAllowsSelectionCount = 5;
                _photoPicker.mediaType = ZCMediaAllPhotos;
                
                // code for iPhone and iPod Touch (different code needed for iPad)
                [self presentViewController:_photoPicker animated:YES completion:nil];
                break;
            }
            case 1:
                [self launchEmailPicker];
                break;
            default:
                break;
        }
    }
}

- (void)zcImagePickerController:(ZCImagePickerController *)imagePickerController didFinishPickingMediaWithInfo:(NSArray *)info
{
    //populate our array with the users images
    for (NSDictionary *imageDictionary in info)
        [_attachmentUIImages addObject:[imageDictionary objectForKey:UIImagePickerControllerOriginalImage]];
    
    [self launchEmailPicker];
    //photo picker is dismissed after mail popup is dismissed (both modal views are dismiseed at same time)
}

- (void)zcImagePickerControllerDidCancel:(ZCImagePickerController *)imagePickerController
{
    //dismissed both modal view controllers (photo picker and mail)
    [self dismissViewControllerAnimated:YES completion:nil];
    _attachmentUIImages = [NSMutableArray array];
    _photoPicker = nil;
    return;
}

@end
