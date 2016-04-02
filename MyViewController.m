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

    CGRect navBarFrame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.bounds.size.height + [AppEnvironmentConstants statusBarHeight]);
    UIImage *navBarImage = [AppEnvironmentConstants navBarBackgroundImageFromFrame:navBarFrame];
    [self.navigationController.navigationBar setBackgroundImage:navBarImage
                                                  forBarMetrics:UIBarMetricsDefault];
    
    //set nav bar title color and transparency
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationController.navigationBar.translucent = YES;
    if([AppEnvironmentConstants appTheme].useWhiteStatusBar) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    } else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
}

@end
