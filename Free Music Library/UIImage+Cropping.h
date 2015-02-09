//
//  UIImage+Cropping.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/7/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//Thanks to Jamz Tang: http://blog.ioscodesnippet.com/post/10001584770/crop-an-image-in-specific-rect

#import <UIKit/UIKit.h>

@interface UIImage (Cropping)

+ (UIImage *)imageWithImage:(UIImage *)image cropInRect:(CGRect)rect;

// define rect in proportional to the target image.
//
//  +--+--+
//  |A | B|
//  +--+--+
//  |C | D|
//  +--+--+
//
//  rect {0, 0, 1, 1} produce full image without cropping.
//  rect {0.5, 0.5, 0.5, 0.5} produce part D, etc.

+ (UIImage *)imageWithImage:(UIImage *)image cropInRelativeRect:(CGRect)rect;

//-------------
//-------------
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;

@end

// Used by +[UIImage imageWithImage:cropInRelativeRect]
CGRect CGRectTransformToRect(CGRect fromRect, CGRect toRect);
