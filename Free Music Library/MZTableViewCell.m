//
//  MZTableViewCell.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//There is a small bug in this implementation. If the font size is changed WHILE the cell
//is in editing mode, the y origin values of the textlabels will be screwed up until the cells
//leave editing mode. The simple fix i am using is to basically block the settings page while in
//editing mode by disabling the button.

#import "MZTableViewCell.h"
#import "PreferredFontSizeUtility.h"
#import "AlbumArtUtilities.h"
#import "SongAlbumArt+Utilities.h"
#import "AlbumAlbumArt+Utilities.h"

@interface MZTableViewCell ()
{
    short lastPrefSizeUsed;
}
@end
@implementation MZTableViewCell
short const textLabelsPaddingFromImgView = 10;
short const editingModeChevronWidthCompensation = 55;
short const imgPaddingFromLeft = 5;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        lastPrefSizeUsed = [AppEnvironmentConstants preferredSizeSetting];
    }
    return self;
}

- (BOOL)shouldReloadCellImages
{
    //cell images get blurry when going from small to big size
    BOOL retVal = NO;
    if(lastPrefSizeUsed < [AppEnvironmentConstants preferredSizeSetting]
       && abs(lastPrefSizeUsed - [AppEnvironmentConstants preferredSizeSetting]) >= 2)
        retVal = YES;
    lastPrefSizeUsed = [AppEnvironmentConstants preferredSizeSetting];
    return retVal;
}

- (void)layoutSubviews
{
    //the order of all of these calls matters a lot here. careful editing this.
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
    
    // Makes imageView get placed in the corner
    int cellHeight = self.frame.size.height;
    self.imageView.frame = CGRectMake(imgPaddingFromLeft,
                                      imgPaddingFromLeft/2,
                                      cellHeight - imgPaddingFromLeft,
                                      cellHeight - imgPaddingFromLeft);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self setLabelsFramesBasedOnEditingMode];
    UIFont *textLabelFont;
    NSString *regularFontName = [AppEnvironmentConstants regularFontName];
    NSString *boldFontName = [AppEnvironmentConstants boldFontName];
    int suggestedFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    
    if([AppEnvironmentConstants boldNames])
        textLabelFont = [MZTableViewCell findAdaptiveFontWithName:boldFontName
                                   forUILabelSize:self.textLabel.frame.size
                                  withMinimumSize:suggestedFontSize - 10];
    else
        textLabelFont = [MZTableViewCell findAdaptiveFontWithName:regularFontName
                                   forUILabelSize:self.textLabel.frame.size
                                  withMinimumSize:suggestedFontSize - 10];
    
    self.textLabel.font = textLabelFont;
    
    CGSize detailTextSize = self.detailTextLabel.frame.size;
    self.detailTextLabel.font = [MZTableViewCell findAdaptiveFontWithName:regularFontName
                                                           forUILabelSize:detailTextSize
                                                          withMinimumSize:suggestedFontSize - 10];
    [self fixiOS7PlusSeperatorBug];
    
    if([self shouldReloadCellImages])
    {
        if(self.anAlbumArtClass)
        {
            //try to load a new copy of the image on disk.
            UIImage *newImage;
            if([self.anAlbumArtClass isMemberOfClass:[SongAlbumArt class]])
            {
                SongAlbumArt *albumArt = (SongAlbumArt *)self.anAlbumArtClass;
                newImage = [albumArt imageFromImageData];
            }
            else if([self.anAlbumArtClass isMemberOfClass:[AlbumAlbumArt class]])
            {
                CGSize cellImgSize = self.imageView.frame.size;
                AlbumAlbumArt *albumArt = (AlbumAlbumArt *)self.anAlbumArtClass;
                newImage = [albumArt imageWithSize:cellImgSize];
            }
            if(newImage){
                self.imageView.image = nil;
                self.imageView.image = newImage;
            } else
                newImage = nil;
        }
    }
}

- (UIEdgeInsets)layoutMargins
{
    //it should match the padding (created in the method above), so the line starts exactly where
    //the album art starts
    int ios7PlusEditingInsetVal = 43;
    if(self.editing)
        return UIEdgeInsetsMake(0, ios7PlusEditingInsetVal, 0, 0);
    else
        return UIEdgeInsetsMake(0, imgPaddingFromLeft, 0, 0);
}

- (void)prepareForReuse
{
    self.anAlbumArtClass = nil;
    [super prepareForReuse];
}

- (void)dealloc
{
    self.anAlbumArtClass = nil;
}

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
    int xOrigin, yOrigin, width, height;
    
    xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    width = self.frame.size.width - xOrigin;
    height = self.frame.size.height * 0.35;
    
    if(self.detailTextLabel.text == nil)
        //there is not detail label, just center this one.
        yOrigin = (self.frame.size.height/2) - (height/2);
    else
        yOrigin = self.frame.size.height * .12;  //should be 12% down from top

    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (CGRect)textLabelFrameInEditingMode
{
    int xOrigin, yOrigin, width, height;
    
    xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    height = self.frame.size.height * 0.35;
    
    if(self.detailTextLabel.text == nil)
        //there is not detail label, just center this one.
        yOrigin = (self.frame.size.height/2) - (height/2);
    else
        yOrigin = self.frame.size.height * .12;  //should be 12% down from top

    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (CGRect)detailTextLabelFrameWithoutEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int width = self.frame.size.width - xOrigin;
    int yOrigin = self.frame.size.height * .53;  //should be 53% from top
    int height = self.frame.size.height * 0.35;
    return CGRectMake(xOrigin,
                      yOrigin,
                      width,
                      height);
}

- (CGRect)detailTextLabelFrameInEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int yOrigin = self.frame.size.height * .53;  //should be 53% from top
    int width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    int height = self.frame.size.height * 0.35;

    return CGRectMake(xOrigin,
                      yOrigin,
                      width,
                      height);
}

- (void)fixiOS7PlusSeperatorBug
{
    for (UIView *subview in self.contentView.superview.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"SeparatorView"]) {
            subview.hidden = NO;
        }
    }
}

+ (UIFont *)findAdaptiveFontWithName:(NSString *)fontName
                      forUILabelSize:(CGSize)labelSize
                     withMinimumSize:(NSInteger)minSize
{
    UIFont *tempFont = nil;
    NSString *testString = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    NSInteger tempMin = minSize;
    NSInteger tempMax = 256;
    NSInteger mid = 0;
    NSInteger difference = 0;
    
    while (tempMin <= tempMax) {
        @autoreleasepool {
            mid = tempMin + (tempMax - tempMin) / 2;
            tempFont = [UIFont fontWithName:fontName size:mid];
            difference = labelSize.height - [testString sizeWithFont:tempFont].height;
            
            if (mid == tempMin || mid == tempMax) {
                if (difference < 0) {
                    return [UIFont fontWithName:fontName size:(mid - 1)];
                }
                return [UIFont fontWithName:fontName size:mid];
            }
            
            if (difference < 0) {
                tempMax = mid - 1;
            } else if (difference > 0) {
                tempMin = mid + 1;
            } else {
                return [UIFont fontWithName:fontName size:mid];
            }
        }
    }
    
    return [UIFont fontWithName:fontName size:mid];
}

@end
