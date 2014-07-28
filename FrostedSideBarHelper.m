//
//  FrostedSideBarHelper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "FrostedSideBarHelper.h"

@implementation FrostedSideBarHelper

+ (void)setupAndShowSlideOutMenuUsingdelegate:(id)delegate;
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    UIImage *blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSArray *images = @[blankImage,blankImage,
                        blankImage,[UIImage imageNamed:@"Gear Icon"]];
    
    NSArray *colors =@[[UIColor blueColor],[UIColor redColor],[UIColor greenColor],[UIColor purpleColor]];
    
    NSRange range;
    range.length = 4;
    range.location = 0;
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    
    RNFrostedSidebar *sideBar;
    sideBar = [[RNFrostedSidebar alloc] initWithImages:images selectedIndices:indexSet borderColors:colors];
    sideBar.animationDuration = .3;
    sideBar.borderWidth = 1;
    sideBar.delegate = delegate;
    [sideBar show];
}

@end
