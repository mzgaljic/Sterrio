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
    self.navigationController.navigationBar.barTintColor = [UIColor defaultAppColorScheme];
    
    //change background color of view
    self.view.backgroundColor = [UIColor clearColor];
    self.parentViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor defaultWindowTintColor]
                                                                                                forKey:UITextAttributeTextColor]];
}

@end
