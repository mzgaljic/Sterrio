//
//  MZTableViewCell.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZTableViewCell.h"
#import "PreferredFontSizeUtility.h"
#import "AlbumArtUtilities.h"
#import "SongAlbumArt+Utilities.h"
#import "AlbumAlbumArt+Utilities.h"
#import "CoreDataManager.h"

@interface MZTableViewCell ()
{
    int lastSongCellHeight;
    UILabel *coloredDotLabel;  //only used in the playbackQueueVc
}
@end
@implementation MZTableViewCell
short const textLabelsPaddingFromImgView = 10;
short const editingModeChevronWidthCompensation = 55;
short const imgPaddingFromLeft = 5;
short const dotLabelPadding = 20;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        lastSongCellHeight = [AppEnvironmentConstants preferredSongCellHeight];
    }
    return self;
}

- (BOOL)shouldReloadCellImages
{
    if(self.optOutOfImageView || self.displayQueueSongsMode)
        return NO;
    //cell images get blurry when going from small to big size
    BOOL retVal = NO;
    if(lastSongCellHeight != [AppEnvironmentConstants preferredSongCellHeight]){
        retVal = YES;
        lastSongCellHeight = [AppEnvironmentConstants preferredSongCellHeight];
    }
    return retVal;
}

- (void)layoutSubviews
{
    //the order of all of these calls matters a lot here. careful editing this.
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
    
    // Makes imageView get placed in the corner
    if(! self.optOutOfImageView){
        int xOrigin;
        if(self.displayQueueSongsMode)
            xOrigin = imgPaddingFromLeft + dotLabelPadding;
        else
            xOrigin = imgPaddingFromLeft;

        int cellHeight = self.frame.size.height;
        self.imageView.frame = CGRectMake(xOrigin,
                                          imgPaddingFromLeft/2,
                                          cellHeight - imgPaddingFromLeft,
                                          cellHeight - imgPaddingFromLeft);
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if(self.isRepresentingAQueuedSong){
            CGRect frame = self.contentView.frame;
            coloredDotLabel = [[UILabel alloc] initWithFrame:CGRectMake(4,
                                                                        frame.size.height/2 - 10,
                                                                        20, 20)];
            coloredDotLabel.text = @"•";
            coloredDotLabel.textColor = [AppEnvironmentConstants appTheme].mainGuiTint;
            coloredDotLabel.font = [UIFont systemFontOfSize:40];
            [self.contentView addSubview:coloredDotLabel];
        }
    }
    [self setLabelsFramesBasedOnEditingMode];
    
    UIFont *textLabelFont;
    NSString *regularFontName = [AppEnvironmentConstants regularFontName];
    NSString *boldFontName = [AppEnvironmentConstants boldFontName];
    if(_isRepresentingANowPlayingItem) {
        textLabelFont = [MZTableViewCell findAdaptiveFontWithName:boldFontName
                                                   forUILabelSize:self.textLabel.frame.size
                                                  withMinimumSize:16];
    } else {
        textLabelFont = [MZTableViewCell findAdaptiveFontWithName:regularFontName
                                                   forUILabelSize:self.textLabel.frame.size withMinimumSize:16];
    }
    self.textLabel.font = textLabelFont;
    
    CGSize detailTextSize = self.detailTextLabel.frame.size;
    self.detailTextLabel.font = [MZTableViewCell findAdaptiveFontWithName:regularFontName
                                                           forUILabelSize:detailTextSize
                                                          withMinimumSize:16];
    if([AppEnvironmentConstants isUserOniOS9OrAbove]) {
        [self.textLabel setAllowsDefaultTighteningForTruncation:YES];
        [self.detailTextLabel setAllowsDefaultTighteningForTruncation:YES];
    }
    [self fixiOS7PlusSeperatorBug];
    
    if([self shouldReloadCellImages])
    {
        [self reloadMZCellImage];
    }
}

- (UIEdgeInsets)layoutMargins
{
    if(self.displayQueueSongsMode || self.optOutOfImageView)
        return UIEdgeInsetsZero;
    
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
    _anAlbumArtClassObjId = nil;
    _optOutOfImageView = NO;
    _displayQueueSongsMode = NO;
    _isRepresentingAQueuedSong = NO;
    _isRepresentingANowPlayingItem = NO;
    _usesOnlyTextLabel = NO;
    self.textLabel.text = @"";
    self.detailTextLabel.text = @"";
    [coloredDotLabel removeFromSuperview];
    [super prepareForReuse];
}

- (void)dealloc
{
    _anAlbumArtClassObjId = nil;
    self.imageView.image = nil;
    coloredDotLabel = nil;
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
    if(_optOutOfImageView){
        xOrigin = textLabelsPaddingFromImgView;
        width = self.frame.size.width - xOrigin;
    } else{
        int imgViewWidth = self.imageView.frame.size.width;
        xOrigin = self.imageView.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
        width = self.frame.size.width - xOrigin;
    }
    
    height = self.frame.size.height * [self internalPercentTextLabelIsDecreasedFromTotalCellHeight];
    if(self.detailTextLabel.text == nil)
        //there is not detail label, just center this one.
        yOrigin = (self.frame.size.height/2) - (height/2);
    else
        yOrigin = self.frame.size.height * .10;  //should be 10% down from top

    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (CGRect)textLabelFrameInEditingMode
{
    int xOrigin, yOrigin, width, height;
    
    if(_optOutOfImageView){
        xOrigin = textLabelsPaddingFromImgView;
    } else{
        int imgViewWidth = self.imageView.frame.size.width;
        xOrigin = self.imageView.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    }
    width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    height = self.frame.size.height * [self internalPercentTextLabelIsDecreasedFromTotalCellHeight];
    if(self.detailTextLabel.text == nil)
        //there is not detail label, just center this one.
        yOrigin = (self.frame.size.height/2) - (height/2);
    else
        yOrigin = self.frame.size.height * .10;  //should be 10% down from top

    return CGRectMake(xOrigin, yOrigin, width, height);
}

- (CGRect)detailTextLabelFrameWithoutEditingMode
{
    int xOrigin;
    if(_optOutOfImageView){
        xOrigin = textLabelsPaddingFromImgView;
    } else{
        int imgViewWidth = self.imageView.frame.size.width;
        xOrigin = self.imageView.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    }
    int width = self.frame.size.width - xOrigin;
    int yOrigin = self.frame.size.height * .55;  //should be 55% from top
    int height = self.frame.size.height *[self internalPercentTextLabelIsDecreasedFromTotalCellHeight];
    return CGRectMake(xOrigin,
                      yOrigin,
                      width,
                      height);
}

- (CGRect)detailTextLabelFrameInEditingMode
{
    int xOrigin;
    if(_optOutOfImageView){
        xOrigin = textLabelsPaddingFromImgView;
    } else{
        int imgViewWidth = self.imageView.frame.size.width;
        xOrigin = self.imageView.frame.origin.x + imgViewWidth + textLabelsPaddingFromImgView;
    }
    int width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    int yOrigin = self.frame.size.height * .55;  //should be 55% from top
    int height = self.frame.size.height *[self internalPercentTextLabelIsDecreasedFromTotalCellHeight];

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

- (float)internalPercentTextLabelIsDecreasedFromTotalCellHeight
{
    if(_usesOnlyTextLabel) {
        return 0.50;  //textLabel height will take up 50% of the contentView.
    } else {
        //textLabel height will take up 35% o the contentView
        //(leaving room for a gap and the detailTextLabel.)
        return [MZTableViewCell percentTextLabelIsDecreasedFromTotalCellHeight];
    }
}

+ (float)percentTextLabelIsDecreasedFromTotalCellHeight
{
    return 0.35;
}

- (void)reloadMZCellImage
{
    if(self.anAlbumArtClassObjId)
    {
        //try to load a new copy of the image on disk. Make EVERY core data access
        //go through main thread context.
        __block UIImage *newImage;
        __block id anAlbumArtClassObj;
        __unsafe_unretained NSManagedObjectID *weakObjId = self.anAlbumArtClassObjId;
        NSManagedObjectContext *context = [CoreDataManager context];
        [context performBlockAndWait:^{
            anAlbumArtClassObj = [context existingObjectWithID:weakObjId error:nil];
        }];
        
        if([anAlbumArtClassObj isMemberOfClass:[SongAlbumArt class]])
        {
            SongAlbumArt *tempAlbumArt = (SongAlbumArt *)anAlbumArtClassObj;
            __unsafe_unretained NSManagedObjectID *albumArtObjId = tempAlbumArt.objectID;
            
            [context performBlockAndWait:^{
                SongAlbumArt *albumArt = (SongAlbumArt *)[context existingObjectWithID:albumArtObjId error:nil];
                newImage = [albumArt imageFromImageData];
            }];
        }
        else if([anAlbumArtClassObj isMemberOfClass:[AlbumAlbumArt class]])
        {
            CGSize cellImgSize = self.imageView.frame.size;
            AlbumAlbumArt *tempAlbumArt = (AlbumAlbumArt *)anAlbumArtClassObj;
            __unsafe_unretained NSManagedObjectID *albumArtObjId = tempAlbumArt.objectID;
            
            [context performBlockAndWait:^{
                AlbumAlbumArt *albumArt = (AlbumAlbumArt *)[context existingObjectWithID:albumArtObjId error:nil];
                newImage = [albumArt imageWithSize:cellImgSize];
            }];
        }
        if(newImage){
            self.imageView.image = nil;
            self.imageView.image = newImage;
        }
    }
}

@end
