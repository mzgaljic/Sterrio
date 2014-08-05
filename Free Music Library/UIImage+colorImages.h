//
//  UIImage+colorImages.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (colorImages)

//code by Jamz Tang, found at: http://blog.ioscodesnippet.com/post/9247898208/creating-a-placeholder-uiimage-dynamically-with-color
+ (UIImage *)imageWithColor:(UIColor *)color width:(float)widthValue height:(float)heightValue;

@end
