//
//  UIToolbar+DarkTint.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "UIToolbar+DarkTint.h"
#import <objc/runtime.h>

@implementation UIToolbar (DarkTint)
@dynamic colorLayer;
static CGFloat const kSpaceToCoverStatusBars = 0.0f;

- (void)swizlayoutSubviews {
    [self swizlayoutSubviews];
    
    if (self.colorLayer == nil) {
        self.colorLayer = [[CALayer alloc] init];
        self.colorLayer.opacity = .85;
        [self.layer addSublayer:self.colorLayer];
        
        self.colorLayer.backgroundColor = [[UIColor colorWithRed:.26 green:.50 blue:.76 alpha:1] CGColor];
    }
    if (self.colorLayer != nil) {
        self.colorLayer.frame = CGRectMake(0, 0 - kSpaceToCoverStatusBars, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + kSpaceToCoverStatusBars);
        
        [self.layer insertSublayer:self.colorLayer atIndex:1];
    }
}

-(void) setColorLayer:(CALayer *)colorLayer {
    objc_setAssociatedObject(self, @"colorLayer", colorLayer, OBJC_ASSOCIATION_RETAIN);
}

-(CALayer *) colorLayer {
    return objc_getAssociatedObject(self, @"colorLayer");
}

+(void) load {
    Method original, swizzled;
    original = class_getInstanceMethod(self, @selector(layoutSubviews));
    swizzled = class_getInstanceMethod(self, @selector(swizlayoutSubviews));
    method_exchangeImplementations(original, swizzled);
}

@end
