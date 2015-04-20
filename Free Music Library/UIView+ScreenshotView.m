//
//  UIView+ScreenshotView.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/12/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "UIView+ScreenshotView.h"

@implementation UIView (ScreenshotView)

//iOS 7+
//Credits to Klaas
//http://stackoverflow.com/questions/2214957/how-do-i-take-a-screen-shot-of-a-uiview
- (UIImage *)viewAsScreenshot
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
