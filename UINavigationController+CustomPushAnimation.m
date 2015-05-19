//
//  UINavigationController+CustomPushAnimation.m
//  Muzic
//
//  Created by Mark Zgaljic on 9/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UINavigationController+CustomPushAnimation.h"

@implementation UINavigationController (CustomPushAnimation)

- (void) pushController: (UIViewController*) controller
         withTransition: (UIViewAnimationTransition) transition
{
    [UIView beginAnimations:nil context:NULL];
    [self pushViewController:controller animated:NO];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationTransition:transition forView:self.view cache:YES];
    [UIView commitAnimations];
}

@end
