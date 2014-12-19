//
//  PlayerView.m
//  Muzic
//
//  Created by Mark Zgaljic on 11/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

- (id)init
{
    if (self = [super init]) {
        AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
        layer.masksToBounds = YES;
    }
    return self;
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end