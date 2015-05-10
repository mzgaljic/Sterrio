//
//  MZSlider.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/9/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZSlider.h"

@implementation MZSlider


//This extends the touchable area of the sliders knob by 10 pixels on the left and right
//and 15 pixels on the top and bottom.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, -10, -15);
    return CGRectContainsPoint(bounds, point);
}

@end
