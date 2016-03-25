//
//  MyViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyViewController.h"
#import "AppEnvironmentConstants.h"

@implementation MyViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar text light and readable
}

@end
