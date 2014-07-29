//
//  SettingsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "Song.h"
#import "AppEnvironmentConstants.h"
#import "SDCAlertView.h"
#import "PreferredFontSizeUtility.h"
#import "ZCImagePickerController.h"  //image picker that allows for multi selection


@interface SettingsTableViewController : UITableViewController <UIPickerViewDelegate,
                                                                UIPickerViewDataSource,
                                                                SDCAlertViewDelegate,
                                                                MFMailComposeViewControllerDelegate,
                                                                UIImagePickerControllerDelegate,
                                                                UINavigationControllerDelegate,
                                                                UIActionSheetDelegate,
                                                                ZCImagePickerControllerDelegate>

@property (nonatomic, strong) UISwitch *syncSettingViaIcloudSwitch;
@property (nonatomic, strong) UISwitch *boldSongSwitch;
@property (nonatomic, strong) UISwitch *smartSortSwitch;

@property (nonatomic, assign) short lastSelectedFontSize;
@property (nonatomic, assign) short lastSelectedCellQuality;
@property (nonatomic, assign) short lastSelectedWifiQuality;
@property (nonatomic, assign) short lastTappedPickerCell;

@end
