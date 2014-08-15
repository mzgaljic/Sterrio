//
//  MyAvPlayer.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAvPlayer.h"

@implementation MyAvPlayer

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

/** takes an AVPlayer, creates an AVPlayerLayer, and sets the AVPlayer to the AVPlayerLayer.
 Code that displays the player onto the layer!*/
- (void)setMovieToPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    [[YouTubeMoviePlayerSingleton createSingleton] setAVPlayerLayerInstance:(AVPlayerLayer *)[self layer]];
}

@end
