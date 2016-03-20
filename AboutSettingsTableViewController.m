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

@implementation AboutSettingsTableViewController
int const NUMBER_OF_SECTIONS = 2;

int const APP_VERSION_SECTION_NUM = 0;
int const LICENSES_SECTION_NUM = 1;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"About";
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUMBER_OF_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case APP_VERSION_SECTION_NUM    :   return 1;
        case LICENSES_SECTION_NUM       :   return 1;
            
        default:    return -1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
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
        }
    }
    else if(indexPath.section == LICENSES_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"aboutSettingRightDetailCell"
                                               forIndexPath:indexPath];
        if(indexPath.row == 0)
        {
            //cell that opens modal VC with license info.
            
            cell.textLabel.text = @"Show Licenses";
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                          size:fontSize];
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
    }
}

@end
