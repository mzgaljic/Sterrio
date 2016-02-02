//
//  MZRightDetailCell.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/1/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZRightDetailCell.h"

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
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    
    if (detailTextLabelFrame.size.width < (detailTextLabelWidth + accessoryWidth)) {
        detailTextLabelFrame.size.width = detailTextLabelWidth;
        
        detailTextLabelFrame.origin.x = self.frame.size.width - accessoryWidth - detailTextLabelWidth;
        self.detailTextLabel.frame = detailTextLabelFrame;
        
        CGRect txtLabelFrame = self.textLabel.frame;
        self.textLabel.frame = CGRectMake(txtLabelFrame.origin.x,
                                          txtLabelFrame.origin.y,
                                          txtLabelFrame.size.width - detailTextLabelWidth,
                                          txtLabelFrame.size.height);
    }
}

@end
