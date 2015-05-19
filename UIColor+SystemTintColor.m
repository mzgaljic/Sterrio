//
//  UIColor+SystemTintColor.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UIColor+SystemTintColor.h"

@implementation UIColor (SystemTintColor)
static UIColor* appColorScheme;

+ (UIColor*)defaultWindowTintColor
{
    static UIColor* systemTintColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        systemTintColor = window.tintColor;
    });
    return systemTintColor;
}

+ (UIColor*)defaultAppColorScheme
{
    return appColorScheme;
}

+ (void)defaultAppColorScheme:(UIColor *)color
{
    appColorScheme = color;
}

+ (UIColor *)standardIOS7PlusTintColor
{
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

@end