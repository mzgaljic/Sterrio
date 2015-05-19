//
//  UIWindow+VisibleVC.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/18/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//user: zirinisp
//from: http://stackoverflow.com/questions/11637709/get-the-current-displaying-uiviewcontroller-on-the-screen-in-appdelegate-m

#import <UIKit/UIKit.h>

@interface UIWindow (VisibleVC)

- (UIViewController *)visibleViewController;

@end