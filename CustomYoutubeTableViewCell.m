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

- (UIEdgeInsets)layoutMargins
{
    //it should match the padding (created in the method above), so the line starts exactly where
    //the album art starts
    return UIEdgeInsetsMake(0, 2, 0, 0);
}

- (void)orientationNeedsToChanged
{
    [self adjustViewsForOrientation];
}

- (void)adjustViewsForOrientation
{
    float widthOfScreenRoationIndependant;
    float heightOfScreenRotationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b)
    {
        heightOfScreenRotationIndependant = b;
        widthOfScreenRoationIndependant = a;
    }
    else
    {
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    
    int oneThirdDisplayWidth = widthOfScreenRoationIndependant * 0.45;
    int height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:oneThirdDisplayWidth];
    //same size in both orientations
    self.videoThumbnail.frame = CGRectMake(2, 4, oneThirdDisplayWidth, height);
    
    short labelPadding = 10;
    int labelOriginX = self.videoThumbnail.frame.origin.x + self.videoThumbnail.frame.size.width + labelPadding;
    int labelWidths = (self.frame.size.width - (self.videoThumbnail.frame.size.width)) - labelPadding;
    int labelHeight = 34.0f;
    
    self.videoTitle.frame = CGRectMake(labelOriginX,
                                       self.videoTitle.frame.origin.y,
                                       labelWidths,
                                       labelHeight);
    self.videoChannel.frame = CGRectMake(labelOriginX,
                                       self.videoChannel.frame.origin.y,
                                       labelWidths,
                                       labelHeight);
    
    self.videoTitle.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    self.videoChannel.font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
}

@end
