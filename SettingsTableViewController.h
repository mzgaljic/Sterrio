//
//  SettingsTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"

@interface SettingsTableViewController : UITableViewController

@property (nonatomic, strong) UISwitch *syncSettingViaIcloudSwitch;
@property (nonatomic, strong) UISwitch *boldSongSwitch;
@property (nonatomic, strong) UISwitch *smartSortSwitch;

@end
