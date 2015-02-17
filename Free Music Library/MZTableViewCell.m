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

@interface MZTableViewCell ()
{
    int layoutSubviewCount;
    int currentImageViewPadding;
    CGRect imgViewFrameBeforeEditingMode;
    CGRect textLabelFrameWithoutEditingMode;
    CGRect detailTextLabelFrameWithoutEditingMode;
}
@end
@implementation MZTableViewCell
short const textLabelsPaddingFromImgView = 10;
short const editingModeChevronWidthCompensation = 55;

static void *didEnterEditingMode = &didEnterEditingMode;

- (void)awakeFromNib
{
    [super awakeFromNib];
    layoutSubviewCount = 0;
    //add observer
    [self addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew context:didEnterEditingMode];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsMayHaveChanged)
                                                 name:MZUserFinishedWithReviewingSettings
                                               object:nil];
}

- (void)settingsMayHaveChanged
{
    int cellHeight = self.frame.size.height;
    self.imageView.frame = CGRectMake(currentImageViewPadding,
                                      currentImageViewPadding/2,
                                      cellHeight - currentImageViewPadding,
                                      cellHeight - currentImageViewPadding);
    imgViewFrameBeforeEditingMode = self.imageView.frame;
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    currentImageViewPadding = self.frame.size.height * 0.12;  //12% of height
    
    // Makes imageView get placed in the corner
    if(layoutSubviewCount == 0){
        int cellHeight = self.frame.size.height;
        self.imageView.frame = CGRectMake(currentImageViewPadding,
                                          currentImageViewPadding/2,
                                          cellHeight - currentImageViewPadding,
                                          cellHeight - currentImageViewPadding);
        imgViewFrameBeforeEditingMode = self.imageView.frame;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    if(self.editing)
        self.imageView.frame = imgViewFrameBeforeEditingMode;
    else
        self.imageView.frame = imgViewFrameBeforeEditingMode;
    
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
    if(context == didEnterEditingMode)
        [self setLabelsFramesBasedOnEditingMode];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)dealloc
{
    [self removeObservers];
}

#pragma mark - utilities
- (void)removeObservers
{
    //temporarily disable logging since this "crash" when removing observers does not impact the program at all.
    Fabric *myFabric = [Fabric sharedSDK];
    myFabric.debug = YES;
    
    @try{
        while(true){
            [self removeObserver:self forKeyPath:@"editing" context:didEnterEditingMode];
        }
    }
    //do nothing, obviously it wasn't attached because an exception was thrown
    @catch(id anException){}

    myFabric.debug = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

@end
