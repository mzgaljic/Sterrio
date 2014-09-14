//
//  CustomSongOrAlbumTableViewCell.m
//  Muzic
//
//  Created by Mark Zgaljic on 9/7/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "CustomSongOrAlbumTableViewCell.h"

@implementation CustomSongOrAlbumTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
