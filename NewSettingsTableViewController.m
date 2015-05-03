
//
//  NewSettingsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/28/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "NewSettingsTableViewController.h"
#import "MSCellAccessory.h"
#import "UIImage+colorImages.h"
#import "PreferredFontSizeUtility.h"
#import "IBActionSheet.h"
#import "SDCAlertController.h"
#import "EmailComposerManager.h"

@interface NewSettingsTableViewController ()
{
    UISwitch *icloudSwitch;
    IBActionSheet *feedbackBtnActionSheet;
    IBActionSheet *bugFoundActionSheet;
    EmailComposerManager *mailComposer;
}
@end
@implementation NewSettingsTableViewController
short const NUM_SECTIONS = 5;
short const ICLOUD_SYNC_SECTION_NUM = 0;
short const MUSIC_QUALITY_SECTION_NUM = 1;
short const APPEARANCE_SECTION_NUM = 2;
short const MUSIC_LIBRARY_SECTION_NUM = 3;
short const FEEDBACK_SECTION_NUM = 4;

int const FEEDBACK_CELL_ACTION_SHEET_TAG = 100;
int const BUG_FOUND_ACTION_SHEET_TAG = 101;

NSString * const ICLOUD_SYNC_SECTION_HEADER_TITLE = @"iCloud";
NSString * const APPEARANCE_SECTION_HEADER_TITLE = @"Appearance";
NSString * const MUSIC_QUALITY_SECTION_HEADER_TITLE = @"Music Quality";
NSString * const MUSIC_LIBRARY_SECTION_HEADER_TITLE = @"Library";

#pragma mark - lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(icloudSwitchMustBeTurnedOff)
                                                 name:MZTurningOnIcloudFailed
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(icloudSwitchMustBeTurnedOn)
                                                 name:MZTurningOffIcloudFailed
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(icloudSwitchMustBeTurnedOn)
                                                 name:MZTurningOnIcloudSuccess
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(icloudSwitchMustBeTurnedOff)
                                                 name:MZTurningOffIcloudSuccess
                                               object:nil];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    mailComposer = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case ICLOUD_SYNC_SECTION_NUM    :   return 1;
        case MUSIC_QUALITY_SECTION_NUM  :   return 2;
        case APPEARANCE_SECTION_NUM     :   return 2;
        case MUSIC_LIBRARY_SECTION_NUM  :   return 1;
        case FEEDBACK_SECTION_NUM       :   return 1;
            
        default:    return -1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BOOL overrideCodeAtEndOfMethod = NO;
    
    if(indexPath.section == ICLOUD_SYNC_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingRightDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
            cell.textLabel.text = @"iCloud Sync";
            cell.detailTextLabel.text = nil;
            if(icloudSwitch == nil){
                icloudSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
                [icloudSwitch setOn:[AppEnvironmentConstants icloudSyncEnabled] animated:NO];
                
                [icloudSwitch addTarget:self
                                 action:@selector(icloudSwitchToggled)
                       forControlEvents:UIControlEventValueChanged];
                
                if([AppEnvironmentConstants isIcloudSwitchWaitingForActionToFinish])
                    icloudSwitch.enabled = NO;
            }
            
            [icloudSwitch setOnTintColor:[[UIColor defaultAppColorScheme] lighterColor]];
            cell.accessoryView = icloudSwitch;
            UIImage *cloudImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                               :[UIImage imageNamed:@"cloud"]];
            cell.imageView.image = cloudImg;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if(indexPath.section == MUSIC_QUALITY_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingRightDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
            //cell stream quality
            
            cell.textLabel.text = @"Cellular Video Quality";
            short cellularVidQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ip", cellularVidQuality];
            
            UIImage *cellImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                              :[UIImage imageNamed:@"cellular tower"]];
            cell.imageView.image = cellImg;
            short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
            UIColor *appTheme = [UIColor defaultAppColorScheme];
            MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                                       color:appTheme];
            cell.accessoryView = coloredDisclosureIndicator;
        }
        else if(indexPath.row == 1)
        {
            //wifi stream quality
            
            cell.textLabel.text = @"Wifi Video Quality";
            short wifiVidQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ip", wifiVidQuality];
            
            UIImage *wifiImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                              :[UIImage imageNamed:@"wifi"]];
            cell.imageView.image = wifiImg;
            short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
            UIColor *appTheme = [UIColor defaultAppColorScheme];
            MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                                       color:appTheme];
            cell.accessoryView = coloredDisclosureIndicator;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if(indexPath.section == APPEARANCE_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingRightDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
            //app theme color
            
            cell.textLabel.text = @"App Theme";
            cell.detailTextLabel.text = nil;
            
            UIImage *colorPaletteImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                                      :[UIImage imageNamed:@"color palette icon"]];
            cell.imageView.image = colorPaletteImg;
            
            short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
            UIColor *appTheme = [UIColor defaultAppColorScheme];
            MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                                       color:appTheme];
            cell.accessoryView = coloredDisclosureIndicator;
        }
        else if(indexPath.row == 1)
        {
            //font size
            
            cell.textLabel.text = @"Font Size";
            cell.detailTextLabel.text = nil;
            cell.imageView.image = [self imageForFontSizeCell];
            
            short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
            UIColor *appTheme = [UIColor defaultAppColorScheme];
            MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                                       color:appTheme];
            cell.accessoryView = coloredDisclosureIndicator;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if(indexPath.section == MUSIC_LIBRARY_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingRightDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
            //ignored prefixes when sorting library cell.
            
            cell.textLabel.text = @"Alphabetical Sorting Rules";
            cell.detailTextLabel.text = nil;

            UIImage *sortingImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                                 :[UIImage imageNamed:@"sorting"]];
            cell.imageView.image = sortingImg;
            
            short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
            UIColor *appTheme = [UIColor defaultAppColorScheme];
            MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                                       color:appTheme];
            cell.accessoryView = coloredDisclosureIndicator;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if(indexPath.section == FEEDBACK_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingBasicDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
            //user Feedback
            
            cell.textLabel.text = @"Feedback";
            overrideCodeAtEndOfMethod = YES;
            float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                  size:fontSize];
            cell.textLabel.textColor = [UIColor defaultAppColorScheme];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }

    
    if(! overrideCodeAtEndOfMethod){
        float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                              size:fontSize];
        cell.detailTextLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                    size:fontSize];
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.numberOfLines = 1;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == APPEARANCE_SECTION_NUM)
    {
        if(indexPath.row == 0)
        {
            //app theme color
            [self performSegueWithIdentifier:@"pick new app theme segue" sender:nil];
        }
        else if(indexPath.row == 1)
        {
            //font size
            [self performSegueWithIdentifier:@"changeFontSizeSegue" sender:nil];
        }

    }
    else if(indexPath.section == MUSIC_QUALITY_SECTION_NUM)
    {
        if(indexPath.row == 1)
        {
            //wifi stream quality
            [self performSegueWithIdentifier:@"pickWifiStreamQualitySegue" sender:nil];
        }
    }
    else if(indexPath.section == FEEDBACK_SECTION_NUM)
    {
        if(indexPath.row == 0)
        {
            //user Feedback
            feedbackBtnActionSheet = [self actionSheetForFeedbackButton];
            [feedbackBtnActionSheet showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
}

#pragma mark - Handling action sheet
- (void)handleActionClickWithButtonIndex:(NSInteger)buttonIndex actionSheet:(IBActionSheet *)sheet
{
    switch (sheet.tag)
    {
        case FEEDBACK_CELL_ACTION_SHEET_TAG:
        {
            if(buttonIndex == 0)
            {
                //user found bug
                bugFoundActionSheet = [self actionSheetForBugFound];
                
                double delayInSeconds = 0.25;
                __weak IBActionSheet *weakSheet = bugFoundActionSheet;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [weakSheet showInView:[UIApplication sharedApplication].keyWindow];
                });
            }
            else if(buttonIndex == 1)
            {
                //general feedback
                
                int generalFeedback = Email_Compose_Purpose_General_Feedback;
                mailComposer = [[EmailComposerManager alloc] initWithEmailComposePurpose:generalFeedback
                                                                               callingVc:self];
                [mailComposer presentEmailComposerAndOrPhotoPicker];
            }
            else if(buttonIndex == 2)
            {
                //cancel button
                return;
            }
        }
        break;
        
        case BUG_FOUND_ACTION_SHEET_TAG:
        {
            if(buttonIndex == 0 || buttonIndex == 1)
            {
                //bug report
                
                int emailPurpose;
                if(buttonIndex == 0)
                    emailPurpose = Email_Compose_Purpose_SimpleBugReport;
                else
                    emailPurpose = Email_Compose_Purpose_ScreenshotBugReport;
                
                mailComposer = [[EmailComposerManager alloc] initWithEmailComposePurpose:emailPurpose
                                                                               callingVc:self];
                [mailComposer presentEmailComposerAndOrPhotoPicker];
            }
            else if(buttonIndex == 2)
            {
                //cancel button
                return;
            }
        }
        break;
            
        default:
            return;
    }
}

#pragma mark - Helpers
- (void)icloudSwitchToggled
{
    __block BOOL switchNowInOnState = icloudSwitch.isOn;
    __block UISwitch *blockSwitch = icloudSwitch;
    if(switchNowInOnState)
    {
        //this check is needed because sliding the switch back and forth before leaving it in
        //its final state can casue some unexpected corner cases.
        if(! [AppEnvironmentConstants icloudSyncEnabled]){
            icloudSwitch.enabled = NO;
        }
        
        [AppEnvironmentConstants set_iCloudSyncEnabled:switchNowInOnState];
    }
    else
    {
        //this check is needed because sliding the switch back and forth before leaving it in
        //its final state can casue some unexpected corner cases.
        if([AppEnvironmentConstants icloudSyncEnabled]){
            icloudSwitch.enabled = NO;
        }
        
        NSString *title = @"iCloud";
        NSString *deviceName = [[UIDevice currentDevice] name];
        NSString *message = [NSString stringWithFormat:@"This device (%@) is about to stop syncing with iCloud. Exisisting data in iCloud will not be affected.", deviceName];
        SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:SDCAlertControllerStyleAlert];
        SDCAlertAction *stopSync = [SDCAlertAction actionWithTitle:@"Stop Syncing"
                                                             style:SDCAlertActionStyleDestructive
                                                           handler:^(SDCAlertAction *action) {
                                                               [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                                   [AppEnvironmentConstants set_iCloudSyncEnabled:switchNowInOnState];
                                                               }];
                                                           }];
        SDCAlertAction *cancel = [SDCAlertAction actionWithTitle:@"Cancel"
                                                           style:SDCAlertActionStyleRecommended
                                                         handler:^(SDCAlertAction *action) {
                                                             [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                                 [blockSwitch setOn:YES animated:YES];
                                                                 blockSwitch.enabled = YES;
                                                             }];
                                                         }];
        [alert addAction:cancel];
        [alert addAction:stopSync];
        [alert presentWithCompletion:nil];
    }
}

- (void)icloudSwitchMustBeTurnedOff
{
    icloudSwitch.enabled = YES;
    [icloudSwitch setOn:NO animated:YES];
}

- (void)icloudSwitchMustBeTurnedOn
{
    icloudSwitch.enabled = YES;
    [icloudSwitch setOn:YES animated:YES];
}

- (IBActionSheet *)actionSheetForBugFound
{
    __weak NewSettingsTableViewController *weakself = self;
    IBActionSheet *mySheet = [[IBActionSheet alloc] initWithTitle:nil
                                                         callback:^(IBActionSheet *myActionSheet, NSInteger buttonIndex){
                                                             [weakself handleActionClickWithButtonIndex:buttonIndex actionSheet:myActionSheet];
                                                         } cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:@"Simple Email", @"Attach Screenshot", nil];
    
    for(UIButton *aButton in mySheet.buttons){
        aButton.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:20];
    }
    mySheet.tag = BUG_FOUND_ACTION_SHEET_TAG;
    [mySheet setButtonTextColor:[UIColor defaultAppColorScheme]];
    [mySheet setTitleTextColor:[UIColor darkGrayColor]];
    [mySheet setCancelButtonFont:[UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                     size:20]];
    [mySheet setTitleFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18]];
    return mySheet;
}

- (IBActionSheet *)actionSheetForFeedbackButton
{
    __weak NewSettingsTableViewController *weakself = self;
    IBActionSheet *mySheet = [[IBActionSheet alloc] initWithTitle:nil
                                              callback:^(IBActionSheet *myActionSheet, NSInteger buttonIndex){
                                                  [weakself handleActionClickWithButtonIndex:buttonIndex actionSheet:myActionSheet];
                                              } cancelButtonTitle:@"Cancel"
                                destructiveButtonTitle:nil
                                     otherButtonTitles:@"I Found A Bug", @"General Feedback", nil];
    
    for(UIButton *aButton in mySheet.buttons){
        aButton.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:20];
    }
    mySheet.tag = FEEDBACK_CELL_ACTION_SHEET_TAG;
    [mySheet setButtonTextColor:[UIColor defaultAppColorScheme]];
    [mySheet setTitleTextColor:[UIColor darkGrayColor]];
    [mySheet setCancelButtonFont:[UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                     size:20]];
    [mySheet setTitleFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18]];
    return mySheet;
}

- (UIImage *)imageForFontSizeCell
{
    UIFont *aFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:23];
    CGSize tempSize = [@"A" sizeWithFont:aFont];
    int edgePadding = 3;
    CGSize size = CGSizeMake(tempSize.width + (2 * edgePadding), tempSize.height + (2 * edgePadding));
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [@"A" drawAtPoint:CGPointMake(edgePadding, edgePadding) withFont:aFont];
    
    // transfer image
    UIImage *tempImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme] :tempImage];
}

- (IBAction)doneDismissButtonTapped:(id)sender
{
    [self commitAllSettingChangesToNSUserDefaults];
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *settingsChangesNotifString = MZUserFinishedWithReviewingSettings;
        [[NSNotificationCenter defaultCenter] postNotificationName:settingsChangesNotifString
                                                            object:nil];
    }];
}

- (void)commitAllSettingChangesToNSUserDefaults
{
    BOOL icloudSyncEnabled = [AppEnvironmentConstants icloudSyncEnabled];
    short prefWifiStreamQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
    short prefCellStreamQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
    int prefSongCellHeight = [AppEnvironmentConstants preferredSongCellHeight];
    
    UIColor *color = [UIColor defaultAppColorScheme];
    const CGFloat* components = CGColorGetComponents(color.CGColor);
    NSNumber *red = [NSNumber numberWithDouble:components[0]];
    NSNumber *green = [NSNumber numberWithDouble:components[1]];
    NSNumber *blue = [NSNumber numberWithDouble:components[2]];
    NSNumber *alpha = [NSNumber numberWithDouble:components[3]];
    NSArray *defaultColorRepresentation = @[red, green, blue, alpha];
    
    [[NSUserDefaults standardUserDefaults] setBool:icloudSyncEnabled
                                            forKey:ICLOUD_SYNC];
    [[NSUserDefaults standardUserDefaults] setInteger:prefWifiStreamQuality
                                               forKey:PREFERRED_WIFI_VALUE_KEY];
    [[NSUserDefaults standardUserDefaults] setInteger:prefCellStreamQuality
                                               forKey:PREFERRED_CELL_VALUE_KEY];
    [[NSUserDefaults standardUserDefaults] setInteger:prefSongCellHeight
                                               forKey:PREFERRED_SONG_CELL_HEIGHT_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:defaultColorRepresentation
                                              forKey:APP_THEME_COLOR_VALUE_KEY];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Rotation and status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self setNeedsStatusBarAppearanceUpdate];
    [self performSelector:@selector(rotateActionSheet) withObject:nil afterDelay:0.1];
}

- (void)rotateActionSheet
{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         if(feedbackBtnActionSheet)
                             [feedbackBtnActionSheet rotateToCurrentOrientation];
                         if(bugFoundActionSheet)
                             [bugFoundActionSheet rotateToCurrentOrientation];
                     }
                     completion:nil];
}

@end
