//
//  UIImage+Cropping.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/7/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "UIImage+Cropping.h"

CGRect CGRectTransformToRect(CGRect fromRect, CGRect toRect)
{
    CGPoint actualOrigin = (CGPoint){fromRect.origin.x * CGRectGetWidth(toRect), fromRect.origin.y * CGRectGetHeight(toRect)};
    CGSize  actualSize   = (CGSize){fromRect.size.width * CGRectGetWidth(toRect), fromRect.size.height * CGRectGetHeight(toRect)};
    return (CGRect){actualOrigin, actualSize};
}


@implementation UIImage (Cropping)

+ (UIImage *)imageWithImage:(UIImage *)image cropInRect:(CGRect)rect
{
    NSParameterAssert(image != nil);
    if (CGPointEqualToPoint(CGPointZero, rect.origin) && CGSizeEqualToSize(rect.size, image.size)) {
        return image;
    }
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1);
    [image drawAtPoint:(CGPoint){-rect.origin.x, -rect.origin.y}];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return croppedImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image cropInRelativeRect:(CGRect)rect
{
    NSParameterAssert(image != nil);
    if (CGRectEqualToRect(rect, CGRectMake(0, 0, 1, 1))) {
        return image;
    }
    
    CGRect imageRect = (CGRect){CGPointZero, image.size};
    CGRect actualRect = CGRectTransformToRect(rect, imageRect);
    return [UIImage imageWithImage:image cropInRect:CGRectIntegral(actualRect)];
}

@end
