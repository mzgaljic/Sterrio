//
//  EditingSongIntro.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "EditingSongIntro.h"
#import "MZPlayer.h"

@interface EditingSongIntro ()
@property (nonatomic, strong) MZPlayer *player;
@end

@implementation EditingSongIntro

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]) {
        int width = frame.size.width;
        int height = frame.size.height;
        int playerWidth = width - (width/5);
        
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *videoUrl = [NSURL fileURLWithPath:[mainBundle pathForResource:@"Editing A Song"
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

- (void)resumeVideoLooping
{
    [self.player play];
}

- (void)dealloc
{
    [_player destroyPlayer];
    _player = nil;
}

@end
