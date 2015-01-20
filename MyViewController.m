//
//  MyViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyViewController.h"

@implementation MyViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [UIColor defaultAppColorScheme];
    
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor defaultWindowTintColor]
                                                                                                forKey:UITextAttributeTextColor]];
    #pragma clang diagnostic warning "-Wdeprecated-declarations"
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;  //makes status bar text light and readable
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

@end
