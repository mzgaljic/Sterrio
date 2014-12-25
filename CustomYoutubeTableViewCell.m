//
//  CustomYoutubeTableViewCell.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "CustomYoutubeTableViewCell.h"

@interface CustomYoutubeTableViewCell ()
{
    float uiLabelWithA;
    float uiLabelWithB;
}
@end

@implementation CustomYoutubeTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationNeedsToChanged)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)prepareForReuse
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self adjustViewsForOrientation];
}

- (void)orientationNeedsToChanged
{
    [self adjustViewsForOrientation];
}

- (void)adjustViewsForOrientation
{
    self.videoThumbnail.frame = CGRectMake(2, 4, 142, 80);  //same size in both orientations
    CGRect videoTitleFrame = self.videoTitle.frame;
    float currentX = videoTitleFrame.origin.x;
    float currentY = videoTitleFrame.origin.y;
    float currentHeight = videoTitleFrame.size.height;
    
    //-10 is to account for the width that the thumbnail takes up,
    //and the space between it and the uilabel.
    float newDesiredWidth = (self.frame.size.width - (self.videoThumbnail.frame.size.width)) - 10;
    self.videoTitle.frame = CGRectMake(currentX, currentY, newDesiredWidth, currentHeight);
    
    currentY = self.videoChannel.frame.origin.y;
    currentHeight = self.videoChannel.frame.size.height;
    self.videoChannel.frame = CGRectMake(currentX, currentY, newDesiredWidth, currentHeight);
}

@end
