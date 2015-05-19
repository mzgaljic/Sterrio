//
//  UIImage+ColoringExistingImage.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/5/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UIImage+ColoringExistingImage.h"

@implementation UIImage (ColoringExistingImage)

//thanks to https://coderwall.com/p/nne_ow
- (UIImage *)colorImageWithColor:(UIColor *)color
{
    // Make a rectangle the size of your image
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    // Create a new bitmap context based on the current image's size and scale, that has opacity
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    // Get a reference to the current context (which you just created)
    CGContextRef c = UIGraphicsGetCurrentContext();
    // Draw your image into the context we created
    [self drawInRect:rect];
    // Set the fill color of the context
    CGContextSetFillColorWithColor(c, [color CGColor]);
    // This sets the blend mode, which is not super helpful. Basically it uses the your fill color with the alpha of the image and vice versa. I'll include a link with more info.
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    // Now you apply the color and blend mode onto your context.
    CGContextFillRect(c, rect);
    // You grab the result of all this drawing from the context.
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    // And you return it.
    return result;
}

@end
