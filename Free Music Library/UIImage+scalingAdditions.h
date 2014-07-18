//
//  UIImage+scalingAdditions.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (scalingAdditions)

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize;

@end
