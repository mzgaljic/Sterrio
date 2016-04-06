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
    
    CGRect navBarFrame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.bounds.size.height + [AppEnvironmentConstants statusBarHeight]);
    UIImage *navBarImage = [AppEnvironmentConstants navBarBackgroundImageFromFrame:navBarFrame];
    [self.navigationController.navigationBar setBackgroundImage:navBarImage
                                                  forBarMetrics:UIBarMetricsDefault];
    
    //force tableview to hide empty extra cells
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = NO;
    if([AppEnvironmentConstants appTheme].useWhiteStatusBar) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    } else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

@end
