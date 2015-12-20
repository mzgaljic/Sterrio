//
//  QueueSongsIntro.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "QueueSongsIntro.h"
#import "MZPlayer.h"

@interface QueueSongsIntro ()
@property (nonatomic, strong) MZPlayer *player;
@end
@implementation QueueSongsIntro

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]) {
        int width = frame.size.width;
        int height = frame.size.height;
        int playerWidth = width - (width/5);
        
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *videoUrl = [NSURL fileURLWithPath:[mainBundle pathForResource:@"Queue songs video"
                                                                      ofType:@"mp4"]];
        
        _player = [[MZPlayer alloc] initWithFrame:CGRectMake((width - playerWidth)/2,
                                                                 (height/2) - 200,
                                                                 playerWidth,
                                                                 200)
                                             videoURL:videoUrl
                                   useControlsOverlay:NO];
        _player.loopPlaybackForever = YES;
        [_player play];
        
        [self addSubview:self.player];
    }
    return self;
}

- (void)dealloc
{
    [_player destroyPlayer];
    _player = nil;
}

- (void)resumeVideoLooping
{
    [self.player play];
}

@end
