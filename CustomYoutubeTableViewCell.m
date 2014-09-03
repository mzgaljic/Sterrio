//
//  CustomYoutubeTableViewCell.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "CustomYoutubeTableViewCell.h"

@implementation CustomYoutubeTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationHasChanged)
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

- (void)orientationHasChanged
{
    [self adjustViewsForOrientation];
}

- (void)adjustViewsForOrientation
{
    self.videoThumbnail.frame = CGRectMake(2, 4, 142, 80);  //same size in both orientations
}

@end
