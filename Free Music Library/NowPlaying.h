//
//  NowPlaying.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Playlist.h"

@interface NowPlaying : NSObject
@property(atomic, readonly) BOOL playing;
@property(atomic, readonly) BOOL paused;

//Both can be nil!
@property(atomic, strong, readonly) Song *aSong;  //nil if no songs played yet
@property(atomic, strong, readonly) Playlist *originatingPlaylist;  //playlist this song is being played from (if any). Nil if not from a playlist.

- (void)updateNowPlayingWithSong:(Song *)nextSong fromOptionalPlaylist:(Playlist *)newOrSamePlaylist;
- (void)ResumeNowPlaying;
- (void)PauseNowPlaying;

@end
