//
//  MyTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyTableViewController.h"
#import "AppEnvironmentConstants.h"

@implementation MyTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //makes the keyboard dismiss when the tableview is touched (useful for search bar stuff)
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    
    //force tableview to hide empty extra cells
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar text light and readable
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

@end
