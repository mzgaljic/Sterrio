//
//  UIImage+colorImages.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UIImage+colorImages.h"

@implementation UIImage (colorImages)

//code by Jamz Tang, found at: http://blog.ioscodesnippet.com/post/9247898208/creating-a-placeholder-uiimage-dynamically-with-color
+ (UIImage *)imageWithColor:(UIColor *)color width:(float)widthValue height:(float)heightValue
{
    CGRect rect = CGRectMake(0, 0, widthValue, heightValue);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
