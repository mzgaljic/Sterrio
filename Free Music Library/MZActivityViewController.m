//
//  MZActivityViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZActivityViewController.h"

@interface MZActivityViewController ()
{
    NSDictionary *originalTitleTextAttributes;
}
@end

@implementation MZActivityViewController

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    if(self = [super initWithActivityItems:activityItems applicationActivities:applicationActivities]){
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //setting nav bar title color temporarily to the default color scheme
    originalTitleTextAttributes = [[UINavigationBar appearance] titleTextAttributes];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor defaultAppColorScheme]}];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //retoring the original nav bar title
    [[UINavigationBar appearance] setTitleTextAttributes:originalTitleTextAttributes];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}


@end
