//
//  MySearchBar.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MySearchBar.h"

@interface MySearchBar ()
{
    UIColor *textAndCursorColor;
}
@end
@implementation MySearchBar

- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        textAndCursorColor = [[UIColor defaultAppColorScheme] lighterColor];
        self.placeholder = @"Search";
        self.keyboardType = UIKeyboardTypeASCIICapable;
        [self sizeToFit];
        
        [self customizeSearchBar];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame placeholderText:(NSString *)text
{
    if(self = [super initWithFrame:frame]){
        textAndCursorColor = [[UIColor defaultAppColorScheme] lighterColor];
        self.placeholder = text;
        self.keyboardType = UIKeyboardTypeASCIICapable;
        [self sizeToFit];
        
        [self customizeSearchBar];
    }
    return self;
}

- (void)updateFontSizeIfNecessary
{
    [self setFontSizeBasedOnUserSettings];
    [self setNeedsDisplay];
}

- (void)customizeSearchBar
{
    [self setFontSizeBasedOnUserSettings];
    int prefSize = [AppEnvironmentConstants preferredSizeSetting];
    short height;
    switch (prefSize) {
        case 1:
            height = 28;
            break;
        case 2:
            height = 28;
            break;
        case 3:
            height = 28;
            break;
        case 4:
            height = 28;
            break;
        case 5:
            height = 30;
            break;
        case 6:
            height = 38;
            break;
        default:
            height = 28;
            break;
    }
    //textfield background color, size of white fill, etc.
    CGSize size = CGSizeMake(30, height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0,30,height) cornerRadius:3.0] addClip];
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *prettyGreyBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setSearchFieldBackgroundImage:prettyGreyBackgroundImage forState:UIControlStateNormal];
    
    //blinking cursor color
    self.tintColor = textAndCursorColor;
    self.barTintColor = [UIColor defaultWindowTintColor];
}

- (void)setFontSizeBasedOnUserSettings
{
    float fontSize = [SongTableViewFormatter nonBoldSongLabelFontSize];
    if(fontSize < 18)
        fontSize = 18;
    //font size
    NSDictionary *dict = @{
                           NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                           NSForegroundColorAttributeName : textAndCursorColor
                           };
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil]
     setDefaultTextAttributes:dict];
}

@end
