//
//  UIColor+LighterAndDarker.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/23/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UIColor+LighterAndDarker.h"

@implementation UIColor (LighterAndDarker)

- (UIColor *)lighterColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.3, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}
@end