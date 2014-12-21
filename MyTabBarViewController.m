//
//  MyTabBarViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyTabBarViewController.h"

@interface MyTabBarViewController ()

@end

@implementation MyTabBarViewController

- (void)viewWillAppear:(BOOL)animated
{
    UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *pic = [UIImage imageNamed:@"Funny pic"];
    pic = [MyTabBarViewController imageWithImage:pic scaledToSize:CGSizeMake(100, 100)];
    CGSize picSize = pic.size;
    
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    
    myButton.frame = CGRectMake(appWindow.frame.size.width - picSize.width,
                                appWindow.frame.size.height - (picSize.height * 2), 100, 100);
    
    [myButton setImage:pic forState:UIControlStateNormal];
    [myButton addTarget:self action:@selector(goToTop)
       forControlEvents:UIControlEventTouchUpInside];
    [myButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [myButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    myButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    [appWindow addSubview:myButton];
}

//get rid of this method once the production "Ready" floating view is finished
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
