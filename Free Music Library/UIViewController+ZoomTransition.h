//
//  UIViewController+ZoomTransition.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIViewController (ZoomTransition)

// make a transition that looks like a modal view
//  is expanding from a subview
- (void)expandView:(UIView *)sourceView
toModalViewController:(UIViewController *)modalViewController;

// make a transition that looks like the current modal view
//  is shrinking into a subview
- (void)dismissModalViewControllerToView:(UIView *)view;

@end
