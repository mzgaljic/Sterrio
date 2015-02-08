//
//  CustomYoutubeTableViewCell.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PreferredFontSizeUtility.h"

@interface CustomYoutubeTableViewCell : UITableViewCell

@property(nonatomic, weak) IBOutlet UIImageView *videoThumbnail;
@property(nonatomic, weak) IBOutlet UILabel *videoTitle;
@property(nonatomic, weak) IBOutlet UILabel *videoChannel;

@end
