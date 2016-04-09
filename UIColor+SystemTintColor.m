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

+ (UIColor *)standardIOS7PlusTintColor
{
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

@end
