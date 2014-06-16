//
//  NowPlaying.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "NowPlaying.h"

@interface NowPlaying ()
@property(atomic, readwrite) BOOL playing;
@property(atomic, readwrite) BOOL paused;
@property(atomic, strong, readwrite) Song *aSong;
@property(atomic, strong, readwrite) Playlist *originatingPlaylist;  //playlist this song is being played from (if any)
@end

@implementation NowPlaying
@synthesize aSong, originatingPlaylist, playing , paused;

/**
 * Both parameters are optional. Pass nil as an argumen
 *
 */
- (void)updateNowPlayingWithSong:(Song *)nextSong fromOptionalPlaylist:(Playlist *)newOrSamePlaylist
{
    self.aSong = nextSong;
    self.originatingPlaylist = newOrSamePlaylist;
}

- (void)ResumeNowPlaying
{
    self.playing = YES;
    self.paused = NO;
}

- (void)PauseNowPlaying
{
    self.playing = NO;
    self.paused = YES;
}

@end
