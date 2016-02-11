//
//  CustomYoutubeTableViewCell.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "CustomYoutubeTableViewCell.h"

@interface CustomYoutubeTableViewCell ()
@end

@implementation CustomYoutubeTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationNeedsToChanged)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    self.videoTitle.numberOfLines = 0;
    self.videoChannel.numberOfLines = 0;
    self.videoTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    self.videoChannel.lineBreakMode = NSLineBreakByTruncatingTail;
    if([AppEnvironmentConstants isUserOniOS9OrAbove]) {
        [self.videoChannel setAllowsDefaultTighteningForTruncation:YES];
        [self.videoTitle setAllowsDefaultTighteningForTruncation:YES];
    }
}

- (void)prepareForReuse
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
    
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
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b)
        widthOfScreenRoationIndependant = a;
    else
        widthOfScreenRoationIndependant = b;
    
    //int thumbnailWidth = widthOfScreenRoationIndependant * 0.45;
    int thumbnailWidth = 140;
    int thumbnailHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:thumbnailWidth];
    int yPadding = (self.contentView.frame.size.height - thumbnailHeight) / 2;
    //same size in both orientations
    self.videoThumbnail.frame = CGRectMake(2,
                                           self.contentView.frame.size.height - thumbnailHeight - yPadding,
                                           thumbnailWidth,
                                           thumbnailHeight);
    
    self.videoTitle.frame = [self videoTitleFrame];
    self.videoChannel.frame = [self videoChannelFrame];
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    int minFontSize = 18;
    if(fontSize < minFontSize)
        fontSize = minFontSize;
    
    UIFont *font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                   size:fontSize];
    self.videoTitle.font = font;
    self.videoChannel.font = font;
}

- (CGRect)videoTitleFrame
{
    int textLabelsPaddingFromImgView = 4;
    int xOrigin, yOrigin, width, height;
    int imgViewWidth = self.videoThumbnail.frame.size.width;
    xOrigin = self.videoThumbnail.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    width = self.frame.size.width - xOrigin;
    
    height = self.frame.size.height * [self percentTextLabelIsDecreasedFromTotalCellHeight];
    yOrigin = self.frame.size.height * .12;  //should be 12% down from top
    
    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (CGRect)videoChannelFrame
{
    int textLabelsPaddingFromImgView = 6;
    int imgViewWidth = self.videoThumbnail.frame.size.width;
    int xOrigin = self.videoThumbnail.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    int width = self.frame.size.width - xOrigin;
    int yOrigin = self.frame.size.height * .53;  //should be 53% from top
    int height = self.frame.size.height * [self percentTextLabelIsDecreasedFromTotalCellHeight];
    return CGRectMake(xOrigin,
                      yOrigin,
                      width,
                      height);
}

- (float)percentTextLabelIsDecreasedFromTotalCellHeight
{
    return 0.38;
}

@end
