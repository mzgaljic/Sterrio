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
                                             selector:@selector(orientationNeedsToChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    _videoTitle.numberOfLines = 0;
    _videoChannel.numberOfLines = 0;
    _videoTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    _videoChannel.lineBreakMode = NSLineBreakByTruncatingTail;
    if([AppEnvironmentConstants isUserOniOS9OrAbove]) {
        [_videoChannel setAllowsDefaultTighteningForTruncation:YES];
        [_videoTitle setAllowsDefaultTighteningForTruncation:YES];
    }
}

- (void)prepareForReuse
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _videoThumbnail.image = nil;
    _videoTitle.text = @"";
    _videoChannel.text = @"";
}

- (void)dealloc
{
    _videoTitle.text = nil;
    _videoChannel.text = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
    
    [self adjustViewsForOrientation];
}

- (void)orientationNeedsToChange
{
    [self adjustViewsForOrientation];
}

- (void)adjustViewsForOrientation
{
    float widthOfScreenRoationIndependant;
    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    float  a = mainScreenBounds.size.height;
    float b = mainScreenBounds.size.width;
    if(a < b)
        widthOfScreenRoationIndependant = a;
    else
        widthOfScreenRoationIndependant = b;
    
    //int thumbnailWidth = widthOfScreenRoationIndependant * 0.45;
    int thumbnailWidth = 140;
    int thumbnailHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:thumbnailWidth];
    int contentViewHeight = self.contentView.frame.size.height;
    int yPadding = (contentViewHeight - thumbnailHeight) / 2;
    //same size in both orientations
    _videoThumbnail.frame = CGRectMake(2,
                                       contentViewHeight - thumbnailHeight - yPadding,
                                       thumbnailWidth,
                                       thumbnailHeight);
    
    _videoTitle.frame = [self videoTitleFrame];
    _videoChannel.frame = [self videoChannelFrame];
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    int minFontSize = 18;
    if(fontSize < minFontSize)
        fontSize = minFontSize;
    
    UIFont *font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                   size:fontSize];
    _videoTitle.font = font;
    _videoChannel.font = font;
}

- (UIEdgeInsets)layoutMargins
{
    //it should match the padding (created in the method above), so the line starts exactly where
    //the album art starts
    return UIEdgeInsetsMake(0, 2, 0, 0);
}

- (CGRect)videoTitleFrame
{
    int textLabelsPaddingFromImgView = 4;
    int xOrigin, yOrigin, width, height;
    int imgViewWidth = _videoThumbnail.frame.size.width;
    xOrigin = _videoThumbnail.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    CGSize selfFrameSize = self.frame.size;
    width = selfFrameSize.width - xOrigin;
    
    height = selfFrameSize.height * [self percentTextLabelIsDecreasedFromTotalCellHeight];
    yOrigin = selfFrameSize.height * .12;  //should be 12% down from top
    
    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (CGRect)videoChannelFrame
{
    int textLabelsPaddingFromImgView = 6;
    int imgViewWidth = _videoThumbnail.frame.size.width;
    int xOrigin = _videoThumbnail.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    CGSize selfFrameSize = self.frame.size;
    int width = selfFrameSize.width - xOrigin;
    int yOrigin = selfFrameSize.height * .53;  //should be 53% from top
    int height = selfFrameSize.height * [self percentTextLabelIsDecreasedFromTotalCellHeight];
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
