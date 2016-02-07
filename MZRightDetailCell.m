//
//  MZRightDetailCell.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/1/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZRightDetailCell.h"

@interface MZRightDetailCell ()
{
    CGRect originalTextLabelFrame;
    CGRect originalDetailTextLabelFrame;
}
@end
@implementation MZRightDetailCell

/* Ensures that the detailTextLabel (the one on the right in gray text normally) is never
   cut off by the textLabel. On a regular UITableViewCell with the RightDetail style, the
   textLabel can completely push the detailTextLabel off of the contentView.
 */
- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat accessoryWidth = (self.accessoryType == UITableViewCellAccessoryNone) ? 10 : 35.0f;
    CGFloat detailTextLabelWidth = [self.detailTextLabel.text sizeWithFont:self.detailTextLabel.font].width;
    CGRect detailTextLabelFrame;
    if(CGRectIsEmpty(originalDetailTextLabelFrame)) {
        detailTextLabelFrame = self.detailTextLabel.frame;
        originalDetailTextLabelFrame = detailTextLabelFrame;
    } else {
        detailTextLabelFrame = originalDetailTextLabelFrame;
    }
    
    if (detailTextLabelFrame.size.width < (detailTextLabelWidth + accessoryWidth)) {
        detailTextLabelFrame.size.width = detailTextLabelWidth;
        
        detailTextLabelFrame.origin.x = self.frame.size.width - accessoryWidth - detailTextLabelWidth;
        self.detailTextLabel.frame = detailTextLabelFrame;
        
        CGRect txtLabelFrame;
        if(CGRectIsEmpty(originalTextLabelFrame)) {
            txtLabelFrame = self.textLabel.frame;
            originalTextLabelFrame = txtLabelFrame;
        } else {
            txtLabelFrame = originalTextLabelFrame;
        }
        self.textLabel.frame = CGRectMake(txtLabelFrame.origin.x,
                                          txtLabelFrame.origin.y,
                                          self.frame.size.width - (detailTextLabelWidth + accessoryWidth + txtLabelFrame.origin.x),
                                          txtLabelFrame.size.height);
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        originalTextLabelFrame = CGRectNull;
        originalDetailTextLabelFrame = CGRectNull;
    }
    return self;
}

- (void)prepareForReuse
{
    originalTextLabelFrame = CGRectNull;
    originalDetailTextLabelFrame = CGRectNull;
    [super prepareForReuse];
}

- (void)dealloc
{
    originalTextLabelFrame = CGRectNull;
    originalDetailTextLabelFrame = CGRectNull;
}

@end
