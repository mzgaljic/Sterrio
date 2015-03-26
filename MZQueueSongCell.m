//
//  MZQueueSongCell.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/26/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//Most of this class is a carbon copy of MZTableViewCell...ideally this should have been a subclass of
//that.

#import "MZQueueSongCell.h"

@interface MZQueueSongCell ()
{
    int layoutSubviewCount;
    int currentImageViewPadding;
    CGRect imgViewFrameBeforeEditingMode;
    CGRect textLabelFrameWithoutEditingMode;
    CGRect detailTextLabelFrameWithoutEditingMode;
    
    UILabel *coloredDotLabel;
}
@end
@implementation MZQueueSongCell
short const textLabelsPaddingFromImgView = 10;
short const dotLabelPadding = 20;
short const editingModeChevronWidthCompensation = 55;

static void *didEnterEditingMode = &didEnterEditingMode;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    layoutSubviewCount = 0;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if(layoutSubviewCount == 0){
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }

    currentImageViewPadding = self.frame.size.height * 0.12;  //12% of height
    
    if(layoutSubviewCount == 0){
        int cellHeight = self.frame.size.height;
        self.imageView.frame = CGRectMake(currentImageViewPadding + dotLabelPadding,
                                          currentImageViewPadding/2,
                                          cellHeight - currentImageViewPadding,
                                          cellHeight - currentImageViewPadding);
        imgViewFrameBeforeEditingMode = self.imageView.frame;

        
        if(_isQueuedSong){
            CGRect frame = self.contentView.frame;
            coloredDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(4,
                                                                        frame.size.height/2 - 10,
                                                                        20, 20)];
            coloredDotLabel.text = @"•";
            coloredDotLabel.textColor = [UIColor defaultAppColorScheme];
            coloredDotLabel.font = [UIFont systemFontOfSize:40];
            [self.contentView addSubview:coloredDotLabel];
        }
    }
    
    if(! _isQueuedSong){
        if(coloredDotLabel != nil){
            [coloredDotLabel removeFromSuperview];
            coloredDotLabel = nil;
        }
    }
    
    if(self.editing)
        self.imageView.frame = imgViewFrameBeforeEditingMode;
    else
        self.imageView.frame = imgViewFrameBeforeEditingMode;
    
    [self setLabelsFramesBasedOnEditingMode];
    [self fixiOS7PlusSeperatorBug];
    
    layoutSubviewCount++;
}

- (UIEdgeInsets)layoutMargins
{
    //it should match the padding (created in the method above), so the line starts exactly where
    //the album art starts
    return UIEdgeInsetsMake(0, currentImageViewPadding, 0, 0);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}


#pragma mark - utilities
- (void)setLabelsFramesBasedOnEditingMode
{
    if(self.editing){
        self.textLabel.frame = [self textLabelFrameInEditingMode];
        self.detailTextLabel.frame = [self detailTextLabelFrameInEditingMode];
    } else{
        self.textLabel.frame = [self textLabelFrameWithoutEditingMode];
        self.detailTextLabel.frame = [self detailTextLabelFrameWithoutEditingMode];
    }
}

- (CGRect)textLabelFrameWithoutEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int width = self.frame.size.width - xOrigin;
    textLabelFrameWithoutEditingMode = CGRectMake(xOrigin, self.textLabel.frame.origin.y, width, self.textLabel.frame.size.height);
    return textLabelFrameWithoutEditingMode;
}

- (CGRect)textLabelFrameInEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int yOrigin = textLabelFrameWithoutEditingMode.origin.y;
    //padding so we dont hit the chevron
    int width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    
    return CGRectMake(xOrigin, yOrigin, width, self.textLabel.frame.size.height);
}

- (CGRect)detailTextLabelFrameWithoutEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int width = self.frame.size.width - xOrigin;
    detailTextLabelFrameWithoutEditingMode = CGRectMake(xOrigin,
                                                        self.detailTextLabel.frame.origin.y,
                                                        width,
                                                        self.detailTextLabel.frame.size.height);
    return detailTextLabelFrameWithoutEditingMode;
}

- (CGRect)detailTextLabelFrameInEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int yOrigin = detailTextLabelFrameWithoutEditingMode.origin.y;
    int width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    
    // Assign the the new frame to textLabel
    return CGRectMake(xOrigin,
                      yOrigin,
                      width,
                      self.detailTextLabel.frame.size.height);
}

- (void)fixiOS7PlusSeperatorBug
{
    for (UIView *subview in self.contentView.superview.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"SeparatorView"]) {
            subview.hidden = NO;
        }
    }
}

@end
