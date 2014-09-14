//
//  UINavigationController+CustomPushAnimation.h
//  Muzic
//
//  Created by Mark Zgaljic on 9/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (CustomPushAnimation)

- (void) pushController: (UIViewController*) controller
         withTransition: (UIViewAnimationTransition) transition;

@end
