
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
#import "StreamQualityPickerTableViewController.h"
#import <StoreKit/StoreKit.h>

@interface NewSettingsTableViewController () <SKProductsRequestDelegate,
                                            SKPaymentTransactionObserver>
{
    UISwitch *icloudSwitch;
    IBActionSheet *feedbackBtnActionSheet;
    IBActionSheet *bugFoundActionSheet;
    EmailComposerManager *mailComposer;
    UITableViewCell *icloudCell;
}
@property (nonatomic, assign) BOOL areAdsRemoved;
@end

@implementation NewSettingsTableViewController
short NUM_SECTIONS = 6;

short REMOVE_ADS_SECTION_NUM = 0;
short ICLOUD_SYNC_SECTION_NUM = 1;
short MUSIC_QUALITY_SECTION_NUM = 2;
short APPEARANCE_SECTION_NUM = 3;
short ADVANCED_SECTION_NUM = 4;
short FEEDBACK_SECTION_NUM = 5;

int const RESTORE_PURCHASE_ACTION_SHEET_TAG = 100;
int const FEEDBACK_CELL_ACTION_SHEET_TAG = 101;
int const BUG_FOUND_ACTION_SHEET_TAG = 102;

#define kRemoveAdsProductIdentifier @"com.mzgaljic.removeads"

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    if((self.areAdsRemoved = [AppEnvironmentConstants areAdsRemoved])) {
        REMOVE_ADS_SECTION_NUM = -1;
        
        ICLOUD_SYNC_SECTION_NUM--;
        MUSIC_QUALITY_SECTION_NUM--;
        APPEARANCE_SECTION_NUM--;
        ADVANCED_SECTION_NUM--;
        FEEDBACK_SECTION_NUM--;
        
        NUM_SECTIONS--;
    }
    
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
}

- (void)dealloc
{
    icloudSwitch = nil;
    icloudCell = nil;
    mailComposer = nil;
    bugFoundActionSheet = nil;
    feedbackBtnActionSheet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == ICLOUD_SYNC_SECTION_NUM + 1) {
        //the icloud section has a big footer. The section beneath this icloud section
        //will want more padding...
        return 38;
    } else {
        return 26;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == ICLOUD_SYNC_SECTION_NUM) {
        return 1;
    } else if(section == REMOVE_ADS_SECTION_NUM) {
        return 2;
    } else if(section == MUSIC_QUALITY_SECTION_NUM) {
        return 2;
    } else if(section == APPEARANCE_SECTION_NUM) {
        return 2;
    } else if(section == ADVANCED_SECTION_NUM) {
        return 1;
    } else if(section == FEEDBACK_SECTION_NUM) {
        return 1;
    } else {
        return -1;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(section == ICLOUD_SYNC_SECTION_NUM) {
        if(! [AppEnvironmentConstants icloudSyncEnabled])
            return nil;
        
        static UIView *footerView;
        
        NSString *syncDateString = [AppEnvironmentConstants humanReadableLastSyncTime];
        NSString *footerText = [NSString stringWithFormat:@"Last Synced %@", syncDateString];
        if(syncDateString == nil){
            footerText = @"Still trying to sync...";
        }
        float footerWidth = [UIScreen mainScreen].bounds.size.width;
        float padding = 10.0f; // an arbitrary amount to center the label in the container
        footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, footerWidth, 44.0f)];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // create the label centered in the container, then set the appropriate autoresize mask
        UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, footerWidth - 2.0f * padding, 44.0f)];
        footerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        footerLabel.textAlignment = NSTextAlignmentCenter;
        footerLabel.text = footerText;
        footerLabel.textColor = [UIColor darkGrayColor];
        
        [footerView addSubview:footerLabel];
        
        return footerView;
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BOOL overrideCodeAtEndOfMethod = NO;
    
    if(indexPath.section == REMOVE_ADS_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingBasicDetailCell"
                                               forIndexPath:indexPath];
        if(indexPath.row == 0)
        {
            //Remove ads
            
            cell.textLabel.text = @"Remove Ads";
            overrideCodeAtEndOfMethod = YES;
            float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                  size:fontSize];
            cell.textLabel.textColor = [UIColor defaultAppColorScheme];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
        } else if(indexPath.row == 1) {
            //Restore purchase
            
            cell.textLabel.text = @"Restore Purchase (Ad Removal)";
            overrideCodeAtEndOfMethod = YES;
            float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                  size:fontSize];
            cell.textLabel.textColor = [UIColor defaultAppColorScheme];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
        }
    }
    else if(indexPath.section == ICLOUD_SYNC_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingRightDetailCell"
                                               forIndexPath:indexPath];
        icloudCell = cell;
        
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
            }
            
            [icloudSwitch setOnTintColor:[[UIColor defaultAppColorScheme] lighterColor]];
            
            if([AppEnvironmentConstants isIcloudSwitchWaitingForActionToFinish]){
                icloudCell.userInteractionEnabled = NO;
                icloudCell.textLabel.enabled = NO;
                icloudSwitch.enabled = NO;
            } else{
                icloudCell.userInteractionEnabled = YES;
                icloudCell.textLabel.enabled = YES;
                icloudSwitch.enabled = YES;
            }
            
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
    else if(indexPath.section == ADVANCED_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingRightDetailCell"
                                               forIndexPath:indexPath];
        if(indexPath.row == 0)
        {
            //advanced settings
            
            cell.textLabel.text = @"Advanced";
            cell.detailTextLabel.text = nil;
            
            UIImage *advancedImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                                  :[UIImage imageNamed:@"advanced"]];
            cell.imageView.image = advancedImg;
            
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
    
    if(indexPath.section == REMOVE_ADS_SECTION_NUM)
    {
        if(indexPath.row == 0)
        {
            //remove ads
            [self userWantsToRemoveAds];
        } else if(indexPath.row == 1) {
            //let user pick which purchase to restore
            IBActionSheet *mySheet = [self actionSheetForRestoringPurchases];
            [mySheet showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
    else if(indexPath.section == APPEARANCE_SECTION_NUM)
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
        if(indexPath.row == 0)
        {
            //cellular stream quality
            VIDEO_QUALITY_STREAM_TYPE streamType = VIDEO_QUALITY_STREAM_TYPE_Cellular;
            [self performSegueWithIdentifier:@"pickStreamQualitySegue"
                                      sender:[NSNumber numberWithShort:streamType]];
        }
        else if(indexPath.row == 1)
        {
            //wifi stream quality
            VIDEO_QUALITY_STREAM_TYPE streamType = VIDEO_QUALITY_STREAM_TYPE_Wifi;
            [self performSegueWithIdentifier:@"pickStreamQualitySegue"
                                      sender:[NSNumber numberWithShort:streamType]];
        }
    }
    else if(indexPath.section == ADVANCED_SECTION_NUM)
    {
        if(indexPath.row == 0)
        {
            //advanced
            [self performSegueWithIdentifier:@"advancedSettingsSegue" sender:nil];
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

#pragma mark - Segue Helper
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"pickStreamQualitySegue"])
    {
        NSNumber *numObj = (NSNumber *)sender;
        VIDEO_QUALITY_STREAM_TYPE streamType = [numObj shortValue];
        
        [[segue destinationViewController] setStreamType:streamType];
        
        if(streamType == VIDEO_QUALITY_STREAM_TYPE_Cellular){
            [[segue destinationViewController] setStreamQualityOptions:@[@240, @360, @720]];
            [[segue destinationViewController] setDefaultStreamSetting:240];
        }else if(streamType == VIDEO_QUALITY_STREAM_TYPE_Wifi){
            [[segue destinationViewController] setStreamQualityOptions:@[@240, @360, @720]];
            [[segue destinationViewController] setDefaultStreamSetting:720];
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
        
        case RESTORE_PURCHASE_ACTION_SHEET_TAG:
        {
            if(buttonIndex == 0) {
                //restore ad removal purchase
                [self restore];
            } else {
                //cancel
            }
        }
        break;
            
        default: return;
    }
}

#pragma mark - Removing ads code
- (void)userWantsToRemoveAds
{
    NSLog(@"User requests to remove ads");
    
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
    } else{
        //this is called the user cannot make payments, most likely due to parental controls
        NSString *title = @"Purchase failed";
        NSString *message = @"This is likely due to parental control settings on this device.";
        NSLog(@"Purchase failed, %@", message);
        SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:SDCAlertControllerStyleAlert];
        SDCAlertAction *okay = [SDCAlertAction actionWithTitle:@"Okay"
                                                             style:SDCAlertActionStyleDefault
                                                           handler:^(SDCAlertAction *action) {}];
        [alert addAction:okay];
        [alert presentWithCompletion:nil];
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    SKProduct *validProduct = nil;
    NSUInteger count = [response.products count];
    if(count > 0) {
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Product Available!");
        [self purchase:validProduct];
    }
    else if(!validProduct) {
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
        NSString *title = @"Item unavailable";
        NSString *message = @"This item is currently unavailable on the App Store.";
        NSLog(@"%@", message);
        SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:SDCAlertControllerStyleAlert];
        SDCAlertAction *okay = [SDCAlertAction actionWithTitle:@"Okay"
                                                         style:SDCAlertActionStyleDefault
                                                       handler:^(SDCAlertAction *action) {}];
        [alert addAction:okay];
        [alert presentWithCompletion:nil];
    }
}

- (void)purchase:(SKProduct *)product
{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restore
{
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            NSLog(@"Transaction state -> Restored");
            
            [self doRemoveAds];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }   
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for(SKPaymentTransaction *transaction in transactions){
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                [self doRemoveAds]; //the action to occur when the purchase is made.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                //Should not block the ui or do anything, purchase is pending approval (by parent, etc.).
                break;
        }
    }
}

- (void)doRemoveAds{
    self.areAdsRemoved = YES;
    [AppEnvironmentConstants adsHaveBeenRemoved:self.areAdsRemoved];
}


#pragma mark - Helper
- (void)icloudSwitchToggled
{
    __block BOOL switchNowInOnState = icloudSwitch.isOn;
    __block UISwitch *blockSwitch = icloudSwitch;
    __weak UITableViewCell *weakCell = icloudCell;

    icloudCell.userInteractionEnabled = NO;
    icloudCell.textLabel.enabled = NO;
    blockSwitch.enabled = NO;
    
    
    if(switchNowInOnState)
    {
        [AppEnvironmentConstants set_iCloudSyncEnabled:switchNowInOnState];
    }
    else
    {
        NSString *title = @"iCloud";
        NSString *deviceName = [[UIDevice currentDevice] name];
        NSString *message = [NSString stringWithFormat:@"This device (%@) is about to stop syncing with iCloud. \n\nThis action will not affect existing data in iCloud.", deviceName];
        SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:SDCAlertControllerStyleAlert];
        SDCAlertAction *stopSync = [SDCAlertAction actionWithTitle:@"Stop Syncing"
                                                             style:SDCAlertActionStyleDestructive
                                                           handler:^(SDCAlertAction *action) {
                                                               [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                                   weakCell.userInteractionEnabled = NO;
                                                                   weakCell.textLabel.enabled = NO;
                                                                   blockSwitch.enabled = NO;
                                                                   [AppEnvironmentConstants set_iCloudSyncEnabled:switchNowInOnState];
                                                               }];
                                                           }];
        SDCAlertAction *cancel = [SDCAlertAction actionWithTitle:@"Cancel"
                                                           style:SDCAlertActionStyleRecommended
                                                         handler:^(SDCAlertAction *action) {
                                                             [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                                 [blockSwitch setOn:YES animated:YES];
                                                                 blockSwitch.enabled = YES;
                                                                 weakCell.textLabel.enabled = YES;
                                                                 weakCell.userInteractionEnabled = YES;
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
    icloudCell.textLabel.enabled = YES;
    icloudCell.userInteractionEnabled = YES;
    [icloudSwitch setOn:NO animated:YES];
}

- (void)icloudSwitchMustBeTurnedOn
{
    icloudSwitch.enabled = YES;
    icloudCell.textLabel.enabled = YES;
    icloudCell.userInteractionEnabled = YES;
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

- (IBActionSheet *)actionSheetForRestoringPurchases
{
    __weak NewSettingsTableViewController *weakself = self;
    NSString *title = @"Which purchase are you restoring?";
    IBActionSheet *mySheet = [[IBActionSheet alloc] initWithTitle:title
                                                         callback:^(IBActionSheet *myActionSheet, NSInteger buttonIndex){
                                                             [weakself handleActionClickWithButtonIndex:buttonIndex actionSheet:myActionSheet];
                                                         } cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:@"Ad Removal", nil];
    
    for(UIButton *aButton in mySheet.buttons){
        aButton.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:20];
    }
    mySheet.tag = RESTORE_PURCHASE_ACTION_SHEET_TAG;
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
    [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
    
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
    BOOL audioOnlyAirplay = [AppEnvironmentConstants shouldOnlyAirplayAudio];
    
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
    [[NSUserDefaults standardUserDefaults] setBool:audioOnlyAirplay
                                            forKey:ONLY_AIRPLAY_AUDIO_VALUE_KEY];
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
