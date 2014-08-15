//
//  MyAvPlayer.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "YouTubeMoviePlayerSingleton.h"

@interface MyAvPlayer : UIView

@property (nonatomic, strong) AVPlayer *player;

- (void)setMovieToPlayer:(AVPlayer *)player;

@end
