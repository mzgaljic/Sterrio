//
//  MySearchBar.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MySearchBar.h"

@implementation MySearchBar

- (id)initWithFrame:(CGRect)frame
{
    if([super initWithFrame:frame]){
        self.placeholder = @"Search";
        self.keyboardType = UIKeyboardTypeASCIICapable;
        [self sizeToFit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame placeholderText:(NSString *)text
{
    if([super initWithFrame:frame]){
        self.placeholder = text;
        self.keyboardType = UIKeyboardTypeASCIICapable;
        [self sizeToFit];
        
        //textfield background color   (rectangular white(=)
        CGSize size = CGSizeMake(30, 30);
        UIGraphicsBeginImageContextWithOptions(size, NO, 1);
        //clip goes away for some reason..doesnt work  :(
        //[[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0,30,30) cornerRadius:4.0] addClip];
        [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0,30,30) cornerRadius:4.0];
        UIColor *prettyGreyColor = [UIColor whiteColor];
        [prettyGreyColor setFill];
        UIRectFill(CGRectMake(0, 0, size.width, size.height));
        UIImage *prettyGreyBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self setSearchFieldBackgroundImage:prettyGreyBackgroundImage forState:UIControlStateNormal];
        
        //blinking cursor color
        self.tintColor = [[UIColor defaultAppColorScheme] lighterColor];
    }
    return self;
}

@end
