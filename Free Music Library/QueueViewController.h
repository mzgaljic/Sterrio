//
//  QueueViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "StackController.h"
#import "AppEnvironmentConstants.h"
#import "AlbumArtUtilities.h"
#import "Song.h"
#import "Song+Utilities.h"
#import "SongTableViewFormatter.h"
#import "PreferredFontSizeUtility.h"
#import "UIImage+colorImages.h"
#import "UIColor+ColorComparison.h"
#import "MusicPlaybackController.h"
#import <FXImageView/UIImage+FX.h>
//#import "MZTableViewCell.h"
#import "MZQueueSongCell.h"
#import "UIColor+LighterAndDarker.h"

@interface QueueViewController : UIViewController
                                <UITableViewDataSource,
                                UITableViewDelegate>
{
    StackController *stackController;
}
@end
