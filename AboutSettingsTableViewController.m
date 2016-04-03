//
//  AboutSettingsTableViewController.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AboutSettingsTableViewController.h"
#import "PreferredFontSizeUtility.h"
#import "UIDevice+DeviceName.h"
#import "LicensesViewController.h"
#import "MZLicense.h"
#import "TermsOfServiceViewController.h"

@implementation AboutSettingsTableViewController
int const NUMBER_OF_ABOUT_SECTIONS = 3;

int const APP_VERSION_SECTION_NUM = 0;
int const LICENSES_SECTION_NUM = 1;
int const TOS_SECTION_NUM = 2;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"About";
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUMBER_OF_ABOUT_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 26;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case APP_VERSION_SECTION_NUM    :   return 1;
        case LICENSES_SECTION_NUM       :   return 1;
        case TOS_SECTION_NUM            :   return 1;
            
        default:    return -1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    
    if(indexPath.section == APP_VERSION_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"aboutSettingRightDetailCell"
                                               forIndexPath:indexPath];
        if(indexPath.row == 0)
        {
            //The full app version
            
            cell.textLabel.text = @"Version";
            NSString *appVersion = [UIDevice appVersionString];
            NSString *buildNum = [UIDevice appBuildString];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@.%@", appVersion, buildNum];
            cell.imageView.image = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:fontSize];
        }
    }
    else if(indexPath.section == LICENSES_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"aboutSettingRightDetailCell"
                                               forIndexPath:indexPath];
        if(indexPath.row == 0)
        {
            //cell that opens modal VC with license info.
            
            cell.textLabel.text = @"Show Credits & Licenses";
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                  size:fontSize];
        }
    }
    else if(indexPath.section == TOS_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"aboutSettingRightDetailCell"
                                               forIndexPath:indexPath];
        if(indexPath.row == 0)
        {
            //cell that opens app TOS
            
            cell.textLabel.text = @"Show Terms & Conditions";
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                  size:fontSize];
        }
    }
    
    cell.detailTextLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                size:fontSize];
    cell.textLabel.numberOfLines = 2;
    cell.detailTextLabel.numberOfLines = 1;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == LICENSES_SECTION_NUM && indexPath.row == 0) {
        NSArray *licenses = [MZLicense allProjectLicenses];
        LicensesViewController *licensesVc = [[LicensesViewController alloc] initWithLicenses:licenses];
        UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:licensesVc];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                        target:licensesVc
                                        action:@selector(dismiss)];
        licensesVc.navigationItem.rightBarButtonItem = doneButton;
        [self presentViewController:navVc animated:YES completion:nil];
    } else if(indexPath.section == TOS_SECTION_NUM && indexPath.row == 0) {
        TermsOfServiceViewController *tosVc = [TermsOfServiceViewController new];
        UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:tosVc];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                       target:tosVc
                                       action:@selector(dismiss)];
        tosVc.navigationItem.rightBarButtonItem = doneButton;
        [self presentViewController:navVc animated:YES completion:nil];
    }
}

@end
