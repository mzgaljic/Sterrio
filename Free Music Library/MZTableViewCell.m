//
//  MZTableViewCell.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZTableViewCell.h"

@interface MZTableViewCell ()
{
    int layoutSubviewCount;
    int currentImageViewPadding;
}
@end
@implementation MZTableViewCell
short const textLabelsPaddingFromImgView = 10;
short const editingModeChevronWidthCompensation = 55;

- (void)awakeFromNib
{
    [super awakeFromNib];
    layoutSubviewCount = 0;
    //add observer
    [self addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    currentImageViewPadding = self.frame.size.height * 0.12;  //12% of height
    
    // Makes imageView get placed in the corner
    self.imageView.frame = CGRectMake(currentImageViewPadding,
                                      currentImageViewPadding/2,
                                      self.imageView.frame.size.width - currentImageViewPadding,
                                      self.imageView.frame.size.height - currentImageViewPadding);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self setLabelsFramesBasedOnEditingMode];
    layoutSubviewCount++;
}

- (UIEdgeInsets)layoutMargins
{
    //it should match the padding (created in the method above), so the line starts exactly where
    //the album art starts
    return UIEdgeInsetsMake(0, currentImageViewPadding, 0, 0);
}

#pragma mark - Key value observation
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:@"editing"])
        [self setLabelsFramesBasedOnEditingMode];
    else if([keyPath isEqualToString:@"frame"]){
        //just reload the whole layout
        if(layoutSubviewCount > 0)
            [self layoutSubviews];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

- (void)dealloc
{
    [self removeObservers];
}

#pragma mark - utilities
- (void)removeObservers
{
    @try{
        while(true){
            [self removeObserver:self forKeyPath:@"editing"];
        }
    }
    //do nothing, obviously it wasn't attached because an exception was thrown
    @catch(id anException){}
    @try{
        while(true){
            [self removeObserver:self forKeyPath:@"frame"];
        }
    }
    @catch(id anException){}
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
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int width = self.frame.size.width - xOrigin;
    
    return CGRectMake(xOrigin, self.textLabel.frame.origin.y, width, self.textLabel.frame.size.height);
}

- (CGRect)textLabelFrameInEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int yOrigin = (currentImageViewPadding/2);
    //padding so we dont hit the chevron
    int width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    
    return CGRectMake(xOrigin, yOrigin, width, self.textLabel.frame.size.height);
}

- (CGRect)detailTextLabelFrameWithoutEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int width = self.frame.size.width - xOrigin;
    
    // Assign the the new frame to textLabel
    return CGRectMake(xOrigin,
                      self.detailTextLabel.frame.origin.y,
                      width,
                      self.detailTextLabel.frame.size.height);
}

- (CGRect)detailTextLabelFrameInEditingMode
{
    int xOrigin = self.imageView.frame.origin.x + self.imageView.frame.size.width + textLabelsPaddingFromImgView;
    int yOrigin = (currentImageViewPadding/2) + self.detailTextLabel.frame.size.height;
    int width = self.frame.size.width - xOrigin - editingModeChevronWidthCompensation;
    
    // Assign the the new frame to textLabel
    return CGRectMake(xOrigin,
                      yOrigin,
                      width,
                      self.detailTextLabel.frame.size.height);
}

@end
