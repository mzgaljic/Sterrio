//
//  MZTableViewCell.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZTableViewCell.h"

@implementation MZTableViewCell

- (void) layoutSubviews
{
    [super layoutSubviews];
    // Makes imageView get placed in the corner
    self.imageView.frame = CGRectMake( 0, 0, 80, 80 );
    
    // Get textlabel frame
    //self.textLabel.backgroundColor = [UIColor blackColor];
    CGRect textlabelFrame = self.textLabel.frame;
    
    // Figure out new width
    textlabelFrame.size.width = textlabelFrame.size.width + textlabelFrame.origin.x - 90;
    // Change origin to what we want
    textlabelFrame.origin.x = 90;
    
    // Assign the the new frame to textLabel
    self.textLabel.frame = textlabelFrame;
}

@end
