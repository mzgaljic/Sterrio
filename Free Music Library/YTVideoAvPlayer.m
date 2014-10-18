//
//  YTVideoAvPlayer.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YTVideoAvPlayer.h"

@interface YTVideoAvPlayer ()
{
    AVPlayerItem *playerItem;
}
@end

@implementation YTVideoAvPlayer

- (id)initWithURL:(NSURL *)URL
{
    if(self = [super initWithURL:URL]){
        [self begingListeningForNotifications];
        [self]
    }
    return self;
}

- (void)startPlaybackOfSong:(Song *)aSong
{
    self
    playerItem = [AVPlayerItem playerItemWithURL:url];
    
    self = [self initWithPlayerItem:playerItem];
    
    [self play];
}

- (void)begingListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(songDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

//Will be called when YTVideoAvPlayer finishes playing a YTVideoPlayerItem
- (void)songDidFinishPlaying:(NSNotification *) notification
{
    
}

@end
