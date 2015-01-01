
//
//  UIColor+SystemTintColor.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SystemTintColor)

+ (UIColor*)defaultWindowTintColor;
+ (UIColor*)defaultAppColorScheme;
+ (void)defaultAppColorScheme:(UIColor *)color;

@end
