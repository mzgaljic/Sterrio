//
//  MZTableViewCell.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZTableViewCell.h"

@implementation MZTableViewCell
short const textLabelPaddingFromImage = 15;

- (void) layoutSubviews
{
    [super layoutSubviews];
    // Makes imageView get placed in the corner
    CGRect originalImgFrame = self.imageView.frame;
    self.imageView.frame = CGRectMake(0,
                                      originalImgFrame.origin.y,
                                      originalImgFrame.size.width,
                                      originalImgFrame.size.height);
    
    // Get textlabel frame
    CGRect textlabelFrame = self.textLabel.frame;
    // Figure out new width
    textlabelFrame.size.width = textlabelFrame.size.width + textlabelFrame.origin.x - self.imageView.frame.size.width;
    // Change origin to what we want
    textlabelFrame.origin.x = originalImgFrame.origin.x + originalImgFrame.size.width;
    // Assign the the new frame to textLabel
    self.textLabel.frame = textlabelFrame;
    

    //now do the same for detail text label
    CGRect detailTextlabelFrame = self.detailTextLabel.frame;
    detailTextlabelFrame.size.width = detailTextlabelFrame.size.width + detailTextlabelFrame.origin.x - self.imageView.frame.size.width;
    detailTextlabelFrame.origin.x = textlabelFrame.origin.x;
    self.detailTextLabel.frame = detailTextlabelFrame;
}

@end
