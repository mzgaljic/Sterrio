//
//  SDCAlertControllerDefaultVisualStyle.m
//  SDCAlertView
//
//  Created by Scott Berrevoets on 9/27/14.
//  Copyright (c) 2014 Scotty Doesn't Code. All rights reserved.
//

#import "SDCAlertControllerDefaultVisualStyle.h"

#import "SDCAlertController.h"
#import "PreferredFontSizeUtility.h"

@implementation SDCAlertControllerDefaultVisualStyle

#pragma mark - Alert

- (CGFloat)width {
	return 270;
}

- (UIEdgeInsets)contentPadding {
	return UIEdgeInsetsMake(36, 16, 12, 16);
}

- (CGFloat)cornerRadius {
	return 7;
}

- (UIEdgeInsets)margins {
	return UIEdgeInsetsMake(3, 0, 3, 0);
}

- (UIOffset)parallax {
	return UIOffsetMake(15.75, 15.75);
}

#pragma mark - Title & Message Labels

- (UIFont *)titleLabelFont {
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    int minFontSize = 17;
    if(fontSize < minFontSize)
        fontSize = minFontSize;
    
    fontSize = fontSize * 1.2;
    int maxFontSize = 26;
    if(fontSize > maxFontSize)
        fontSize = maxFontSize;
    
	return [UIFont fontWithName:[AppEnvironmentConstants boldFontName] size:fontSize];
}

- (UIFont *)messageLabelFont {
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    int minFontSize = 17;
    if(fontSize < minFontSize)
        fontSize = minFontSize;
    
    int maxFontSize = 24;
    if(fontSize > maxFontSize)
        fontSize = maxFontSize;
    
    return [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:fontSize];
}

- (UIColor *)titleLabelColor {
	return [UIColor blackColor];
}

- (UIColor *)messageLabelColor {
	return [UIColor blackColor];
}

- (CGFloat)labelSpacing {
    if([SDCAlertController areTwoLabelsPresentInAlert])
    {
        int fontSizeComponentWasDesignedFor = 17;
        int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
        int spacing = 24;
        
        if(fontSize > fontSizeComponentWasDesignedFor){
            int numGreater = abs(fontSize - spacing);
            spacing = spacing + numGreater;
        }
        
        return spacing;
    }
    else
        return 18;
}

- (CGFloat)messageLabelBottomSpacing {
    int fontSizeComponentWasDesignedFor = 20;
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    int spacing = 24;
    
    if(fontSize > fontSizeComponentWasDesignedFor){
        int numGreater = abs(fontSize - spacing);
        spacing = spacing + numGreater;
    }
        
	return spacing;
}

#pragma mark - Actions

- (CGFloat)actionViewHeight {
	return 44;
}

- (CGFloat)minimumActionViewWidth {
	return 90; // Fits exactly three actions without scrolling
}


- (UIView *)actionViewHighlightBackgroundView {
	UIView *view = [[UIView alloc] init];
	view.backgroundColor = [UIColor colorWithWhite:.80 alpha:.7];
	return view;
}

- (UIColor *)actionViewSeparatorColor {
	return [UIColor colorWithWhite:0.5 alpha:0.5];
}

- (CGFloat)actionViewSeparatorThickness {
	return 1 / [UIScreen mainScreen].scale;
}

- (UIColor *)textColorForAction:(SDCAlertAction *)action {
	if (action.style & SDCAlertActionStyleDestructive) {
		return [UIColor redColor];
	} else {
		return [AppEnvironmentConstants appTheme].contrastingTextColor;
	}
}

- (UIFont *)fontForAction:(SDCAlertAction *)action {
    int fontSize = [PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize];
    int minFontSize = 17;
    if(fontSize < minFontSize)
        fontSize = minFontSize;
    
    int maxFontSize = 22;
    if(fontSize > maxFontSize)
        fontSize = maxFontSize;
    
    UIFont *myFont;
	if (action.style & SDCAlertActionStyleRecommended) {
        myFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName] size:fontSize];
		return myFont;
	} else {
        myFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:fontSize];
		return myFont;
	}
}

#pragma mark - Text Fields

- (UIFont *)textFieldFont {
	return [UIFont systemFontOfSize:13];
}

- (CGFloat)estimatedTextFieldHeight {
	return 25;
}

- (CGFloat)textFieldBorderWidth {
	return 1 / [UIScreen mainScreen].scale;
}

- (UIColor *)textFieldBorderColor {
	return [UIColor colorWithRed:64.f/255 green:64.f/255 blue:64.f/255 alpha:1];
}

- (UIEdgeInsets)textFieldMargins {
	return UIEdgeInsetsMake(4, 4, 4, 4);
}

@end
