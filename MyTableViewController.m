//
//  MyTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyTableViewController.h"

@implementation MyTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.barTintColor = [UIColor defaultAppColorScheme];
    
    //change background color of tableview
    self.tableView.backgroundColor = [UIColor clearColor];
    self.parentViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    //force tableview to only show cells with content (hide the invisible stuff at the bottom of the table)
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor defaultWindowTintColor]
                                                                                                forKey:UITextAttributeTextColor]];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar text light and readable
}

@end
