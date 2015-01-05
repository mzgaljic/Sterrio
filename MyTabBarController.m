//
//  MyTabBarController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyTabBarController.h"
#import "UIColor+LighterAndDarker.h"

@implementation MyTabBarController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //set color of tab bar
    //self.tabBar.barTintColor = [UIColor defaultAppColorScheme];
    self.tabBar.barTintColor = [UIColor whiteColor];
    
    //set color of buttons
    self.tabBar.tintColor = [[[[UIColor defaultAppColorScheme] lighterColor] lighterColor] lighterColor];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

@end
