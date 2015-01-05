//
//  UINavigationBar+DarkTint.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//The purpose of this class is to make the translucency much darker and nicer in the nav bar
//(similar to the facebook app)

//https://gist.github.com/j-mcnally/6987297
#import <UIKit/UIKit.h>

@interface UINavigationBar (DarkTint)
@property CALayer *colorLayer;
@end
